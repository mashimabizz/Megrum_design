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
            let drawerPresentation = AppDrawerPresentationState(
                containerWidth: proxy.size.width,
                isPresented: showsDrawer,
                dragTranslation: drawerDragTranslation
            )

            ZStack(alignment: .leading) {
                AppDrawerOverlay(
                    isPresented: $showsDrawer,
                    presentationProgress: drawerPresentation.progress,
                    drawerWidth: drawerPresentation.drawerWidth,
                    appState: appState,
                    onSelectDestination: { destination in
                        openDrawerDestination(destination)
                    },
                    onSignOut: signOutFromDrawer
                )
                .allowsHitTesting(drawerPresentation.isInteractive)
                .zIndex(AppDrawerVisualMetrics.drawerZIndex)

                AppDrawerForegroundLayer(
                    presentation: drawerPresentation,
                    closeGesture: drawerPanGesture(drawerTravel: drawerPresentation.drawerOpenOffset),
                    homeGesture: homeDrawerPanGesture(
                        drawerTravel: drawerPresentation.drawerOpenOffset,
                        containerSize: proxy.size
                    ),
                    onCloseOverlayTap: closeDrawer
                ) {
                    tabContent
                }
            }
            .background(MegrumTheme.canvas.ignoresSafeArea())
            .contentShape(Rectangle())
            .simultaneousGesture(
                openDrawerPanGesture(
                    drawerTravel: drawerPresentation.drawerOpenOffset,
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
            onOpenDrawer: openDrawer,
            onRequestInterstitial: onRequestInterstitial
        )
    }

    private var drawerAnimation: Animation {
        .interactiveSpring(response: 0.30, dampingFraction: 0.88)
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

    private func openDrawer() {
        withAnimation(drawerAnimation) {
            drawerDragTranslation = 0
            showsDrawer = true
        }
    }

    private func closeDrawer() {
        withAnimation(drawerAnimation) {
            drawerDragTranslation = 0
            showsDrawer = false
        }
    }

    private func signOutFromDrawer() async {
        await onSignOut()
        drawerDestination = nil
        drawerPageDestination = nil
        publicProfileRoute = nil
        drawerDragTranslation = 0
        showsDrawer = false
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
