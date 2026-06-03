// Docket — VScroll
// A vertical ScrollView that always uses overlay (auto-hiding) scrollers,
// regardless of the system "Show scroll bars" setting or an attached mouse.

import SwiftUI
import AppKit

private struct OverlayScrollerSetter: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { view.enclosingScrollView?.scrollerStyle = .overlay }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { nsView.enclosingScrollView?.scrollerStyle = .overlay }
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
