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
    @Binding var pendingNotificationRouteIntent: NotificationRouteIntent?
    @ObservedObject var tutorialCoordinator: TutorialTourCoordinator
    var adDisplayContext: AdDisplayContext
    var visualQAInitialScreen: VisualQAInitialScreen?
    var onSignOut: () async -> Void
    var onRequestInterstitial: (AdPlacement) -> Void
    @State private var isGroomViewerPresented = false

    var body: some View {
        AppDrawerInteractiveHost(
            appState: appState,
            showsDrawer: $showsDrawer,
            isHomeTabSelected: selectedTab == .home,
            isSearchPresented: showsSearch,
            onSelectDestination: { destination in
                openDrawerDestination(destination)
            },
            onSignOut: signOutFromDrawer
        ) {
            tabContent
        }
        #if os(iOS)
        // タブバーはグルーム表示オーバーレイが上から覆うため隠さない。
        // UIKit直叩き（isHidden）やtoolbar切替はiOS 27で復帰に失敗し、
        // タブバーが消えたままになる不具合の原因だった。
        .statusBarHidden(isGroomViewerPresented)
        #endif
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
            pendingNotificationRouteIntent: $pendingNotificationRouteIntent,
            isGroomViewerPresented: $isGroomViewerPresented,
            tutorialCoordinator: tutorialCoordinator,
            adDisplayContext: adDisplayContext,
            visualQAInitialScreen: visualQAInitialScreen,
            onOpenDrawer: openDrawer,
            onRequestInterstitial: onRequestInterstitial
        )
    }

    private func openDrawer() {
        MegrumHaptics.buttonTap()
        withAnimation(AppDrawerInteractiveMetrics.animation) {
            showsDrawer = true
        }
    }

    private func signOutFromDrawer() async {
        await onSignOut()
        drawerDestination = nil
        drawerPageDestination = nil
        publicProfileRoute = nil
        showsDrawer = false
    }

    private func openDrawerDestination(_ destination: AppDrawerDestination) {
        drawerDestination = nil
        drawerPageDestination = nil

        let presentationDelay: TimeInterval = showsDrawer ? 0.18 : 0
        DispatchQueue.main.asyncAfter(deadline: .now() + presentationDelay) {
            drawerDestination = destination
        }
    }
}

enum AppDrawerInteractiveMetrics {
    static let animation: Animation = .interactiveSpring(response: 0.30, dampingFraction: 0.88)
}

/// Owns the interactive drawer drag state so per-frame drag updates re-render
/// only this host (drawer chrome, offsets), never the tab content passed in
/// by the parent — dragging must not re-evaluate the tab screens.
@MainActor
struct AppDrawerInteractiveHost<Content: View>: View {
    @ObservedObject var appState: MegrumAppState
    @Binding var showsDrawer: Bool
    var isHomeTabSelected: Bool
    var isSearchPresented: Bool
    var onSelectDestination: (AppDrawerDestination) -> Void
    var onSignOut: () async -> Void

    private let content: Content
    @State private var dragTranslation: CGFloat = 0

    init(
        appState: MegrumAppState,
        showsDrawer: Binding<Bool>,
        isHomeTabSelected: Bool,
        isSearchPresented: Bool,
        onSelectDestination: @escaping (AppDrawerDestination) -> Void,
        onSignOut: @escaping () async -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.appState = appState
        _showsDrawer = showsDrawer
        self.isHomeTabSelected = isHomeTabSelected
        self.isSearchPresented = isSearchPresented
        self.onSelectDestination = onSelectDestination
        self.onSignOut = onSignOut
        self.content = content()
    }

    var body: some View {
        GeometryReader { proxy in
            let drawerPresentation = AppDrawerPresentationState(
                containerWidth: proxy.size.width,
                isPresented: showsDrawer,
                dragTranslation: dragTranslation
            )

            ZStack(alignment: .leading) {
                AppDrawerOverlay(
                    isPresented: $showsDrawer,
                    presentationProgress: drawerPresentation.progress,
                    drawerWidth: drawerPresentation.drawerWidth,
                    appState: appState,
                    onSelectDestination: onSelectDestination,
                    onSignOut: onSignOut
                )
                .allowsHitTesting(drawerPresentation.isInteractive)
                .zIndex(AppDrawerVisualMetrics.drawerZIndex)

                AppDrawerForegroundLayer(
                    presentation: drawerPresentation,
                    safeAreaInsets: proxy.safeAreaInsets,
                    closeGesture: drawerPanGesture(drawerTravel: drawerPresentation.drawerOpenOffset),
                    homeGesture: homeDrawerPanGesture(
                        drawerTravel: drawerPresentation.drawerOpenOffset,
                        containerSize: proxy.size
                    ),
                    onCloseOverlayTap: closeDrawer
                ) {
                    content
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
        .onChange(of: showsDrawer) { _, _ in
            if dragTranslation != 0 {
                updateDragTranslation(0)
            }
        }
    }

    private func homeDrawerPanGesture(drawerTravel: CGFloat, containerSize: CGSize) -> some Gesture {
        drawerPanGesture(drawerTravel: drawerTravel) { startLocation in
            AppDrawerGestureResolver.isClosedHomeDrawerSwipeStartAllowed(
                isHomeTabSelected: isHomeTabSelected,
                isDrawerPresented: showsDrawer,
                isSearchPresented: isSearchPresented,
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
                    resetDismissDrag()
                    return
                }
                if let translation = AppDrawerGestureResolver.activeTranslation(
                    isPresented: showsDrawer,
                    translation: value.translation
                ) {
                    updateDragTranslation(translation)
                } else {
                    resetDismissDrag()
                }
            }
            .onEnded { value in
                guard allowsStart(value.startLocation) else {
                    resetDismissDrag()
                    return
                }
                guard let targetVisibility = AppDrawerGestureResolver.targetVisibility(
                    isPresented: showsDrawer,
                    translation: value.translation,
                    predictedEndTranslationWidth: value.predictedEndTranslation.width,
                    drawerWidth: drawerTravel
                ) else {
                    resetDismissDrag(animated: true)
                    return
                }

                // スワイプの指が離れ「開閉が確定した瞬間」に触覚フィードバック（開くアニメの完了待ちはしない）。
                // 開く時は buttonTap、閉じる時はほんの少しだけ弱い drawerClose。iter1226.397。
                let willOpenViaSwipe = targetVisibility && !showsDrawer
                let willCloseViaSwipe = !targetVisibility && showsDrawer
                if willOpenViaSwipe {
                    MegrumHaptics.buttonTap()
                } else if willCloseViaSwipe {
                    MegrumHaptics.drawerClose()
                }
                withAnimation(AppDrawerInteractiveMetrics.animation) {
                    showsDrawer = targetVisibility
                    dragTranslation = 0
                }
            }
    }

    private func updateDragTranslation(_ translation: CGFloat) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            dragTranslation = translation
        }
    }

    private func resetDismissDrag(animated: Bool = false) {
        guard dragTranslation != 0 else {
            return
        }
        if animated {
            withAnimation(AppDrawerInteractiveMetrics.animation) {
                dragTranslation = 0
            }
        } else {
            updateDragTranslation(0)
        }
    }

    private func closeDrawer() {
        MegrumHaptics.buttonTap()
        withAnimation(AppDrawerInteractiveMetrics.animation) {
            dragTranslation = 0
            showsDrawer = false
        }
    }
}
