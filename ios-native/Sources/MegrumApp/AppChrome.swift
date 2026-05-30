import SwiftUI

extension View {
    @ViewBuilder
    func megrumHiddenNavigationBar() -> some View {
        #if os(iOS)
        self
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        #else
        self
        #endif
    }
}
