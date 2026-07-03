import SwiftUI

extension View {
    @ViewBuilder
    func groomViewerImmersiveOverlay<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        sourceAnchor: UnitPoint = .center,
        onDismiss: @escaping () -> Void = {},
        @ViewBuilder content: @escaping (Item, @escaping () -> Void) -> Content
    ) -> some View {
        #if os(iOS)
        ZStack {
            self

            if let presentedItem = item.wrappedValue {
                Color.black
                    .ignoresSafeArea(.all)
                    .allowsHitTesting(false)
                    .transition(.opacity)
                    .zIndex(9_998)

                content(presentedItem) {
                    item.wrappedValue = nil
                    onDismiss()
                }
                .megrumGroomViewerImmersivePresentationChrome()
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.08, anchor: sourceAnchor).combined(with: .opacity),
                    removal: .scale(scale: 0.08, anchor: sourceAnchor).combined(with: .opacity)
                ))
                .zIndex(9_999)
            }
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.86), value: item.wrappedValue?.id)
        .background(SystemTabBarVisibilityHost(isHidden: item.wrappedValue != nil))
        .toolbar(item.wrappedValue == nil ? .visible : .hidden, for: .tabBar)
        .statusBarHidden(item.wrappedValue != nil)
        #else
        self.sheet(item: item, onDismiss: onDismiss) { presentedItem in
            content(presentedItem) {
                item.wrappedValue = nil
                onDismiss()
            }
        }
        #endif
    }

    @ViewBuilder
    func megrumGroomViewerImmersivePresentationChrome() -> some View {
        #if os(iOS)
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.ignoresSafeArea(.all))
            .ignoresSafeArea(.all)
            .presentationBackground(.black)
            .preferredColorScheme(.dark)
            .statusBarHidden(true)
            .toolbar(.hidden, for: .tabBar)
            .background(SystemTabBarVisibilityHost(isHidden: true))
        #else
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.ignoresSafeArea())
        #endif
    }
}
