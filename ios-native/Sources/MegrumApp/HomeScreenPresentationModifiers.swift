import SwiftUI

extension View {
    @ViewBuilder
    func homeRelationPresentation<Content: View>(
        item: Binding<HomeRelationRoute?>,
        @ViewBuilder content: @escaping (HomeRelationRoute) -> Content
    ) -> some View {
        #if os(iOS)
        megrumSlideItemPresentation(item: item) { route, _ in
            content(route)
        }
        #else
        sheet(item: item, content: content)
        #endif
    }

    @ViewBuilder
    func homeProposalPresentation<Content: View>(
        item: Binding<HomeProposalRoute?>,
        @ViewBuilder content: @escaping (HomeProposalRoute) -> Content
    ) -> some View {
        #if os(iOS)
        megrumSlideItemPresentation(item: item) { route, _ in
            content(route)
        }
        #else
        sheet(item: item, content: content)
        #endif
    }
}
