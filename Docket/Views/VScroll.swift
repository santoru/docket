// Docket — VScroll
// A simple vertical ScrollView. Scrollbar appearance follows the system
// "Show scroll bars" setting (System Settings → Appearance).

import SwiftUI

struct VScroll<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        ScrollView(.vertical) {
            content()
        }
    }
}
