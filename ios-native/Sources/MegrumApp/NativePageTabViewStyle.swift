import SwiftUI

extension View {
    @ViewBuilder
    func megrumPageTabViewStyle() -> some View {
        #if os(iOS)
        self.tabViewStyle(.page(indexDisplayMode: .never))
        #else
        self
        #endif
    }
}
