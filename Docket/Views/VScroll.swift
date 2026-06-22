// Docket — VScroll
// A vertical ScrollView that always uses overlay (auto-hiding) scrollers,
// regardless of the system "Show scroll bars" setting or an attached mouse.
//
// SwiftUI's ScrollView resets the underlying NSScrollView.scrollerStyle to the
// system preference on every layout pass. When the user has "Show scroll bars:
// Always" set (or a mouse attached forcing legacy scrollers), the bar becomes a
// wide, always-visible legacy scroller. To guarantee the modern auto-hiding
// overlay scroller, we resolve the enclosing NSScrollView and KVO-observe its
// `scrollerStyle`, forcing it back to `.overlay` whenever anything changes it.

import SwiftUI
import AppKit

private struct OverlayScrollerSetter: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        context.coordinator.attach(to: view)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.reapply(from: nsView)
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.invalidate()
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        private weak var scrollView: NSScrollView?
        private var observation: NSKeyValueObservation?
        private var isForcing = false

        /// Resolve the enclosing scroll view, retrying briefly because on the
        /// first `makeNSView` the helper view is not yet in the hierarchy.
        func attach(to view: NSView) {
            resolve(from: view, attemptsLeft: 8)
        }

        func reapply(from view: NSView) {
            if scrollView == nil {
                resolve(from: view, attemptsLeft: 8)
            } else {
                force()
            }
        }

        private func resolve(from view: NSView, attemptsLeft: Int) {
            DispatchQueue.main.async { [weak self, weak view] in
                guard let self, let view else { return }
                guard let sv = view.enclosingScrollView else {
                    if attemptsLeft > 0 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            self.resolve(from: view, attemptsLeft: attemptsLeft - 1)
                        }
                    }
                    return
                }
                self.scrollView = sv
                self.force()
                self.installObserver(on: sv)
            }
        }

        private func installObserver(on sv: NSScrollView) {
            observation?.invalidate()
            // Force the style back to overlay whenever SwiftUI (or the system)
            // changes it. The `isForcing` guard prevents observer recursion.
            observation = sv.observe(\.scrollerStyle, options: [.new]) { [weak self] sv, _ in
                guard let self, !self.isForcing else { return }
                if sv.scrollerStyle != .overlay {
                    self.force()
                }
            }
        }

        private func force() {
            guard let sv = scrollView else { return }
            isForcing = true
            sv.scrollerStyle = .overlay
            sv.autohidesScrollers = true
            sv.verticalScroller?.scrollerStyle = .overlay
            isForcing = false
        }

        func invalidate() {
            observation?.invalidate()
            observation = nil
        }

        deinit { invalidate() }
    }
}

struct VScroll<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        ScrollView(.vertical) {
            content().background(OverlayScrollerSetter())
        }
    }
}
