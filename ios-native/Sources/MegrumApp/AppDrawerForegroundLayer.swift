import SwiftUI

struct AppDrawerPresentationState {
    var drawerWidth: CGFloat
    var drawerOpenOffset: CGFloat
    var progress: CGFloat

    var contentOffset: CGFloat {
        drawerOpenOffset * progress
    }

    var foregroundCornerRadius: CGFloat {
        AppDrawerVisualMetrics.foregroundCornerRadius * progress
    }

    var foregroundShadowOpacity: CGFloat {
        AppDrawerVisualMetrics.foregroundShadowOpacity * progress
    }

    var foregroundWhiteoutOpacity: CGFloat {
        AppDrawerVisualMetrics.whiteoutOpacity * progress
    }

    var isInteractive: Bool {
        progress > 0.001
    }

    init(
        containerWidth: CGFloat,
        isPresented: Bool,
        dragTranslation: CGFloat
    ) {
        let drawerWidth = AppDrawerVisualMetrics.drawerWidth(screenWidth: containerWidth)
        let drawerOpenOffset = AppDrawerVisualMetrics.openOffset(screenWidth: containerWidth)
        let progress = AppDrawerVisualMetrics.presentationProgress(
            isPresented: isPresented,
            dragTranslation: dragTranslation,
            drawerTravel: drawerWidth
        )

        self.drawerWidth = drawerWidth
        self.drawerOpenOffset = drawerOpenOffset
        self.progress = progress
    }
}

@MainActor
struct AppDrawerForegroundLayer<Content: View, CloseGesture: Gesture, HomeGesture: Gesture>: View {
    var presentation: AppDrawerPresentationState
    var closeGesture: CloseGesture
    var homeGesture: HomeGesture
    var onCloseOverlayTap: () -> Void

    private let content: Content

    init(
        presentation: AppDrawerPresentationState,
        closeGesture: CloseGesture,
        homeGesture: HomeGesture,
        onCloseOverlayTap: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.presentation = presentation
        self.closeGesture = closeGesture
        self.homeGesture = homeGesture
        self.onCloseOverlayTap = onCloseOverlayTap
        self.content = content()
    }

    var body: some View {
        content
            .zIndex(AppDrawerVisualMetrics.foregroundZIndex)
            .offset(x: presentation.contentOffset)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: presentation.foregroundCornerRadius,
                    bottomLeadingRadius: presentation.foregroundCornerRadius,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 0
                )
            )
            .shadow(
                color: Color.black.opacity(presentation.foregroundShadowOpacity),
                radius: AppDrawerVisualMetrics.foregroundShadowRadius,
                x: -5,
                y: 0
            )
            .overlay {
                if presentation.isInteractive {
                    Color.white
                        .opacity(presentation.foregroundWhiteoutOpacity)
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture(perform: onCloseOverlayTap)
                        .gesture(closeGesture)
                }
            }
            .overlay(alignment: .leading) {
                Color.clear
                    .frame(width: AppDrawerVisualMetrics.closedEdgeGestureWidth)
                    .contentShape(Rectangle())
                    .simultaneousGesture(homeGesture, including: .gesture)
                    .zIndex(AppDrawerVisualMetrics.closedEdgeGestureZIndex)
            }
    }
}
