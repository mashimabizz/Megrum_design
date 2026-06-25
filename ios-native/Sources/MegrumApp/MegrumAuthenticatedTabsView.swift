import MegrumCore
import MegrumDesign
import SwiftUI

@MainActor
struct MegrumAuthenticatedTabsView: View {
    @ObservedObject var appState: MegrumAppState
    @Binding var selectedTab: MegrumTab
    @Binding var showsSearch: Bool
    @Binding var showsDrawer: Bool
    @Binding var requestedTradesStage: TradeStage?
    @Binding var drawerDestination: AppDrawerDestination?
    @Binding var drawerPageDestination: AppDrawerDestination?
    @Binding var publicProfileRoute: PublicProfileRoute?
    @Binding var homeSettingsRoute: HomeSettingsRoute?
    @Binding var requestedWishSection: WishCollectionSection?
    @Binding var drawerDragTranslation: CGFloat
    var adDisplayContext: AdDisplayContext
    var visualQAInitialScreen: VisualQAInitialScreen?
    var onSignOut: () async -> Void
    var onRequestInterstitial: (AdPlacement) -> Void

    var body: some View {
        GeometryReader { proxy in
            let drawerWidth = AppDrawerVisualMetrics.drawerWidth(screenWidth: proxy.size.width)
            let drawerOpenOffset = AppDrawerVisualMetrics.openOffset(screenWidth: proxy.size.width)
            let drawerProgress = resolvedDrawerProgress(drawerTravel: drawerOpenOffset)
            let contentOffset = drawerOpenOffset * drawerProgress
            let foregroundCornerRadius = AppDrawerVisualMetrics.foregroundCornerRadius * drawerProgress
            let foregroundShadowOpacity = AppDrawerVisualMetrics.foregroundShadowOpacity * drawerProgress
            let foregroundWhiteoutOpacity = AppDrawerVisualMetrics.whiteoutOpacity * drawerProgress

            ZStack(alignment: .leading) {
                AppDrawerOverlay(
                    isPresented: $showsDrawer,
                    presentationProgress: drawerProgress,
                    drawerWidth: drawerWidth,
                    appState: appState,
                    onSelectDestination: { destination in
                        openDrawerDestination(destination)
                    },
                    onSignOut: {
                        await onSignOut()
                        drawerDestination = nil
                        drawerPageDestination = nil
                        publicProfileRoute = nil
                        drawerDragTranslation = 0
                        showsDrawer = false
                    }
                )
                .allowsHitTesting(drawerProgress > 0.001)
                .zIndex(AppDrawerVisualMetrics.drawerZIndex)

                tabContent
                    .zIndex(AppDrawerVisualMetrics.foregroundZIndex)
                    .offset(x: contentOffset)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: foregroundCornerRadius,
                            bottomLeadingRadius: foregroundCornerRadius,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 0
                        )
                    )
                    .shadow(
                        color: Color.black.opacity(foregroundShadowOpacity),
                        radius: AppDrawerVisualMetrics.foregroundShadowRadius,
                        x: -5,
                        y: 0
                    )
                    .overlay {
                        if drawerProgress > 0.001 {
                            Color.white
                                .opacity(foregroundWhiteoutOpacity)
                                .ignoresSafeArea()
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    withAnimation(drawerAnimation) {
                                        drawerDragTranslation = 0
                                        showsDrawer = false
                                    }
                                }
                                .gesture(drawerPanGesture(drawerTravel: drawerOpenOffset))
                        }
                    }
                    .simultaneousGesture(
                        homeDrawerPanGesture(
                            drawerTravel: drawerOpenOffset,
                            containerSize: proxy.size
                        ),
                        including: .gesture
                    )
            }
            .background(MegrumTheme.canvas.ignoresSafeArea())
            .contentShape(Rectangle())
            .simultaneousGesture(
                openDrawerPanGesture(
                    drawerTravel: drawerOpenOffset,
                    containerSize: proxy.size
                ),
                including: showsDrawer ? .all : .subviews
            )
        }
    }

    private var tabContent: some View {
        MegrumAuthenticatedTabContentView(
            appState: appState,
            selectedTab: $selectedTab,
            showsSearch: $showsSearch,
            requestedTradesStage: $requestedTradesStage,
            publicProfileRoute: $publicProfileRoute,
            homeSettingsRoute: $homeSettingsRoute,
            requestedWishSection: $requestedWishSection,
            adDisplayContext: adDisplayContext,
            visualQAInitialScreen: visualQAInitialScreen,
            onOpenDrawer: {
                withAnimation(drawerAnimation) {
                    drawerDragTranslation = 0
                    showsDrawer = true
                }
            },
            onRequestInterstitial: onRequestInterstitial
        )
    }

    private var drawerAnimation: Animation {
        .interactiveSpring(response: 0.30, dampingFraction: 0.88)
    }

    private func resolvedDrawerProgress(drawerTravel: CGFloat) -> CGFloat {
        AppDrawerVisualMetrics.presentationProgress(
            isPresented: showsDrawer,
            dragTranslation: drawerDragTranslation,
            drawerTravel: drawerTravel
        )
    }

    private func homeDrawerPanGesture(drawerTravel: CGFloat, containerSize: CGSize) -> some Gesture {
        drawerPanGesture(drawerTravel: drawerTravel) { startLocation in
            AppDrawerGestureResolver.isClosedHomeDrawerSwipeStartAllowed(
                isHomeTabSelected: selectedTab == .home,
                isDrawerPresented: showsDrawer,
                isSearchPresented: showsSearch,
                startLocation: startLocation,
                screenSize: containerSize
            )
        }
    }

    private func openDrawerPanGesture(drawerTravel: CGFloat, containerSize: CGSize) -> some Gesture {
        drawerPanGesture(drawerTravel: drawerTravel) { startLocation in
            showsDrawer
                && AppDrawerGestureResolver.isOpenDrawerSwipeStartAllowed(
                    startLocation: startLocation,
                    screenSize: containerSize
                )
        }
    }

    private func drawerPanGesture(
        drawerTravel: CGFloat,
        allowsStart: @escaping (CGPoint) -> Bool = { _ in true }
    ) -> some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { value in
                guard allowsStart(value.startLocation) else {
                    resetDrawerDragTranslation()
                    return
                }
                if let translation = AppDrawerGestureResolver.activeTranslation(
                    isPresented: showsDrawer,
                    translation: value.translation
                ) {
                    updateDrawerDragTranslation(translation)
                } else {
                    resetDrawerDragTranslation()
                }
            }
            .onEnded { value in
                guard allowsStart(value.startLocation) else {
                    resetDrawerDragTranslation()
                    return
                }
                guard let targetVisibility = AppDrawerGestureResolver.targetVisibility(
                    isPresented: showsDrawer,
                    translation: value.translation,
                    predictedEndTranslationWidth: value.predictedEndTranslation.width,
                    drawerWidth: drawerTravel
                ) else {
                    resetDrawerDragTranslation(animated: true)
                    return
                }

                withAnimation(drawerAnimation) {
                    showsDrawer = targetVisibility
                    drawerDragTranslation = 0
                }
            }
    }

    private func updateDrawerDragTranslation(_ translation: CGFloat) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            drawerDragTranslation = translation
        }
    }

    private func resetDrawerDragTranslation(animated: Bool = false) {
        guard drawerDragTranslation != 0 else {
            return
        }
        if animated {
            withAnimation(drawerAnimation) {
                drawerDragTranslation = 0
            }
        } else {
            updateDrawerDragTranslation(0)
        }
    }

    private func openDrawerDestination(_ destination: AppDrawerDestination) {
        drawerDestination = nil
        drawerPageDestination = nil

        let presentationDelay: TimeInterval = showsDrawer ? 0.18 : 0
        switch destination {
        case .profile, .schedules:
            DispatchQueue.main.asyncAfter(deadline: .now() + presentationDelay) {
                drawerPageDestination = destination
            }
        default:
            DispatchQueue.main.asyncAfter(deadline: .now() + presentationDelay) {
                drawerDestination = destination
            }
        }
    }
}
