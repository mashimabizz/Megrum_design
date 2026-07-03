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

/// Clips the drawer foreground with leading rounded corners while still
/// covering the safe areas: the foreground view's bounds stop at the safe
/// area, but its content (tab bar, scroll content) draws beyond them, so the
/// plain bounds-sized clip used to cut everything below/above the safe area.
private struct AppDrawerForegroundClipShape: Shape {
    var cornerRadius: CGFloat
    var safeAreaInsets: EdgeInsets

    var animatableData: CGFloat {
        get { cornerRadius }
        set { cornerRadius = newValue }
    }

    func path(in rect: CGRect) -> Path {
        guard cornerRadius > 0.5 else {
            // Drawer closed: don't clip at all, so content that draws into
            // the safe areas (status bar, tab bar, home indicator) is never
            // cut off regardless of how the OS reports the insets.
            return Path(rect.insetBy(dx: -2000, dy: -2000))
        }
        let extended = CGRect(
            x: rect.minX - safeAreaInsets.leading,
            y: rect.minY - safeAreaInsets.top,
            width: rect.width + safeAreaInsets.leading + safeAreaInsets.trailing,
            height: rect.height + safeAreaInsets.top + safeAreaInsets.bottom
        )
        return UnevenRoundedRectangle(
            topLeadingRadius: cornerRadius,
            bottomLeadingRadius: cornerRadius,
            bottomTrailingRadius: 0,
            topTrailingRadius: 0
        )
        .path(in: extended)
    }
}

@MainActor
struct AppDrawerForegroundLayer<Content: View, CloseGesture: Gesture, HomeGesture: Gesture>: View {
    var presentation: AppDrawerPresentationState
    var safeAreaInsets: EdgeInsets
    var closeGesture: CloseGesture
    var homeGesture: HomeGesture
    var onCloseOverlayTap: () -> Void

    private let content: Content

    init(
        presentation: AppDrawerPresentationState,
        safeAreaInsets: EdgeInsets,
        closeGesture: CloseGesture,
        homeGesture: HomeGesture,
        onCloseOverlayTap: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.presentation = presentation
        self.safeAreaInsets = safeAreaInsets
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
                AppDrawerForegroundClipShape(
                    cornerRadius: presentation.foregroundCornerRadius,
                    safeAreaInsets: safeAreaInsets
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
