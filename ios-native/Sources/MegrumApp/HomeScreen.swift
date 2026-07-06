import MegrumCore
import MegrumDesign
import SwiftUI

@MainActor
struct HomeScreen: View {
    var viewer: UserProfile?
    var matchedItems: [GoodsItem]
    var possibleItems: [GoodsItem]
    var adDisplayContext: AdDisplayContext = AdDisplayContext()
    @Binding var showsSearch: Bool
    var onRefresh: () async -> Void
    var appState: MegrumAppState? = nil
    var onOpenSettings: () -> Void = {}
    var onOpenSearchRequested: (() -> Void)? = nil
    var onOpenSearchWithCriteria: (SearchInitialCriteria) -> Void = { _ in }
    var onOpenWish: () -> Void = {}
    var onOpenIndividualListings: () -> Void = {}
    var onOpenExchangeSettings: () -> Void = {}
    var onOpenPaymentSettings: () -> Void = {}
    var onOpenOwnerProfile: (UUID) -> Void = { _ in }
    var onOpenRelationRoute: ((HomeRelationRoute) -> Void)?
    var onOpenProposalRoute: ((HomeProposalRoute) -> Void)?
    var onOpenMeguri: (() -> Void)? = nil
    var onOpenTrades: (() -> Void)? = nil
    var onOpenInventory: () -> Void = {}
    var tutorialSampleActive: Bool = false
    var tutorialFocusAnchor: TutorialAnchorID? = nil
    var starterMissionEnabled: Bool = false
    /// ガイドツアーのサンプル候補用シグナル差し替え。指定時は appState 由来のシグナルより優先。
    var conditionSignalsByItemIDOverride: [UUID: HomeCandidateConditionSignals]? = nil
    /// ガイドツアーのサンプル用：あなたのグッズ（求められているグッズ・激求サムネイル）を差し替える。
    var inventoryItemsOverride: [GoodsItem]? = nil
    var visualQAInitialScreen: VisualQAInitialScreen? = nil

    @AppStorage("megrum.home.localMode.activityWindowID") var localModeActivityWindowID = ""
    @AppStorage("megrum.home.localMode.enabled") var localModeEnabled = false
    @AppStorage("megrum.home.localMode.venue") var localModeVenue = ""
    @AppStorage("megrum.home.localMode.latitude") var localModeLatitude = ""
    @AppStorage("megrum.home.localMode.longitude") var localModeLongitude = ""
    @AppStorage("megrum.home.localMode.startedAt") var localModeStartedAt = 0.0
    @AppStorage("megrum.home.localMode.durationMinutes") var localModeDurationMinutes = HomeLocalActivitySettings.defaultDurationMinutes
    @AppStorage("megrum.home.localMode.radiusMeters") var localModeRadiusMeters = HomeLocalActivitySettings.defaultRadiusMeters
    @AppStorage("megrum.home.localMode.selectedCarryingIDs") var localModeSelectedCarryingIDs = ""
    @State var loadedLocalActivitySettings: HomeLocalActivitySettings?
    @State private var showsLocalModeSettings = false
    @State var relationRoute: HomeRelationRoute?
    @State var proposalRoute: HomeProposalRoute?
    @State var didOpenVisualQAInitialRoute = false

    var body: some View {
        HomeDiscoveryExperience(
            appState: appState,
            viewer: viewer,
            inventoryItems: inventoryItemsOverride ?? appState?.inventory ?? [],
            matchedItems: matchedItems,
            possibleItems: possibleItems,
            recentPartnerItems: appState?.homeRecentPartnerItems ?? [],
            goodsTypes: appState?.goodsTypes ?? [],
            conditionSignalsByItemID: conditionSignalsByItemIDOverride ?? appState?.homeCandidateConditionSignals ?? [:],
            mutualMatchCandidateData: appState?.homeMutualMatchCandidates ?? [],
            hasLoadedCandidates: appState?.hasLoadedHomeCandidates ?? true,
            adDisplayContext: adDisplayContext,
            opensInitialHavesLookup: visualQAInitialScreen == .homeHavesLookup,
            onOpenSettings: onOpenSettings,
            onOpenSearch: {
                if let onOpenSearchRequested {
                    onOpenSearchRequested()
                } else {
                    showsSearch = true
                }
            },
            onOpenSearchWithCriteria: onOpenSearchWithCriteria,
            onOpenWish: onOpenWish,
            onOpenIndividualListings: onOpenIndividualListings,
            onOpenExchangeSettings: onOpenExchangeSettings,
            onOpenPaymentSettings: onOpenPaymentSettings,
            onOpenOwnerProfile: onOpenOwnerProfile,
            onStartProposal: startProposalFromDiscovery,
            onRefresh: {
                await onRefresh()
                await loadLocalActivitySettings()
            },
            tutorialSampleActive: tutorialSampleActive,
            tutorialFocusAnchor: tutorialFocusAnchor,
            starterMissionEnabled: starterMissionEnabled,
            onOpenInventory: onOpenInventory
        )
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .megrumHiddenNavigationBar()
        .sheet(isPresented: $showsLocalModeSettings) {
            HomeLocalModeSettingsSheet(
                viewer: viewer,
                settings: localActivitySettings,
                carryingCandidates: localCarryingCandidates,
                onSave: saveLocalActivitySettings
            )
        }
        .homeRelationPresentation(item: $relationRoute) { route in
            if let relationState = localModeState {
                NavigationStack {
                    MatchRelationScreen(
                        appState: relationState,
                        targetItem: route.item,
                        matchType: route.matchType,
                        visualQAInitialScreen: visualQAInitialScreen,
                        onCompletionAction: { action in
                            relationRoute = nil
                            if action == .openTrades {
                                onOpenTrades?()
                            }
                        }
                    )
                }
            }
        }
        .homeProposalPresentation(item: $proposalRoute) { route in
            if let relationState = localModeState {
                NavigationStack {
                    ProposalCreateFlow(
                        appState: relationState,
                        targetItem: route.item,
                        receiverGoodsIDs: route.receiverGoodsIDs,
                        initialSenderGoodsIDs: route.senderGoodsIDs,
                        matchType: route.matchType,
                        initialExchangeMethod: route.initialExchangeMethod,
                        initialCashAmount: route.initialCashAmount,
                        initialShippingFee: route.initialShippingFee,
                        initialShippingDays: route.initialShippingDays,
                        initialStep: route.initialStep,
                        visualQAInitialScreen: visualQAInitialScreen,
                        onCompletionAction: { action in
                            proposalRoute = nil
                            if action == .openTrades {
                                onOpenTrades?()
                            }
                        }
                    )
                }
            }
        }
        .task(id: viewer?.id) {
            await loadLocalActivitySettings()
            openVisualQAInitialRouteIfNeeded()
        }
        .onChange(of: matchedItems.map(\.id), initial: true) { _, _ in
            openVisualQAInitialRouteIfNeeded()
        }
    }

}
