// Docket — VScroll
// A vertical ScrollView that always uses overlay (auto-hiding) scrollers,
// regardless of the system "Show scroll bars" setting or an attached mouse.

import SwiftUI
import AppKit

private struct OverlayScrollerSetter: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        applyOverlay(view)
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {
        applyOverlay(nsView)
    }
    private func applyOverlay(_ view: NSView) {
        DispatchQueue.main.async {
            guard let sv = view.enclosingScrollView else { return }
            sv.scrollerStyle = .overlay
            sv.hasVerticalScroller = true
            sv.verticalScroller?.alphaValue = 0
        }
    }
}

struct VScroll<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            content().background(OverlayScrollerSetter())
        }
    }
}
