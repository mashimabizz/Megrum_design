import MegrumCore
import MegrumDesign
import SwiftUI

struct HomeDiscoveryExperience: View {
    var appState: MegrumAppState?
    var viewer: UserProfile?
    var inventoryItems: [GoodsItem] = []
    var matchedItems: [GoodsItem] = []
    var possibleItems: [GoodsItem] = []
    var goodsTypes: [GoodsType] = []
    var conditionSignalsByItemID: [UUID: HomeCandidateConditionSignals] = [:]
    var mutualMatchCandidateData: [HomeMutualMatchCandidateData] = []
    var isLoading: Bool
    var adDisplayContext: AdDisplayContext = AdDisplayContext()
    var opensInitialHavesLookup: Bool = false
    var onOpenSettings: () -> Void
    var onOpenSearch: () -> Void
    var onOpenSearchWithCriteria: (SearchInitialCriteria) -> Void = { _ in }
    var onOpenWish: () -> Void = {}
    var onOpenIndividualListings: () -> Void = {}
    var onOpenExchangeSettings: () -> Void = {}
    var onOpenPaymentSettings: () -> Void = {}
    var onOpenOwnerProfile: (UUID) -> Void = { _ in }
    var onStartProposal: (HomeDiscoveryProposalSelection) -> Void = { _ in }
    var onRefresh: () async -> Void

    @AppStorage(HomeExchangeSettingsStorageKeys.preference) var exchangePreferenceRawValue = HomeDefaultExchangeSettings.standard.preference.rawValue
    @AppStorage(HomeExchangeSettingsStorageKeys.requiresSamePrefecture) var exchangeRequiresSamePrefecture = HomeDefaultExchangeSettings.standard.requiresSamePrefecture
    @AppStorage(HomeExchangeSettingsStorageKeys.requiresDateOverlap) var exchangeRequiresDateOverlap = HomeDefaultExchangeSettings.standard.requiresDateOverlap
    @AppStorage(HomeExchangeSettingsStorageKeys.localPrefecture) var exchangeLocalPrefecture = HomeDefaultExchangeSettings.standard.localPrefecture
    @AppStorage(HomeExchangeSettingsStorageKeys.localDateKeys) var exchangeLocalDateKeysRawValue = ""
    @AppStorage(HomeExchangeSettingsStorageKeys.mailShippingFee) var exchangeMailShippingFeeRawValue = HomeDefaultExchangeSettings.standard.mailShippingFee.rawValue
    @AppStorage(HomeExchangeSettingsStorageKeys.mailShippingDays) var exchangeMailShippingDaysRawValue = HomeDefaultExchangeSettings.standard.mailShippingDays.rawValue
    @State var selectedSheet: HomeDiscoverySheet?
    @State var selectedMutualMatchCandidate: HomeMutualMatchCandidate?
    @State var showsMatchHelp = false
    @State var pendingProposalSelection: HomeDiscoveryProposalSelection?
    @State var pendingProfileUserID: UUID?
    @State var didOpenInitialSheet = false
    @State var selectedPrimaryTab: HomeDiscoveryPrimaryTab = .candidates
    @State var showsIndividualListingCreation = false
    @State var sharePromptContext: GoodsSharePostContext?
    @State var isPreparingSharePost = false
    @State var sharePostErrorMessage: String?
    #if os(iOS)
    @State var shareActivityPayload: GoodsSharePostPayload?
    #endif

    var body: some View {
        MegrumCollapsingTopChromeContainer {
            HomePullRefreshScrollView(
                coordinateSpaceName: "home-discovery-candidates-refresh",
                indicatorTopPadding: HomeDiscoveryHeaderMetrics.pullRefreshIndicatorTopPadding,
                onRefresh: onRefresh
            ) {
                VStack(alignment: .leading, spacing: 14) {
                    HomeDiscoverySection(
                        title: "メンバー×シリーズでマッチ",
                        candidates: userTagCandidates,
                        layout: .grid,
                        cardTitleStyle: .memberTag,
                        onSelect: { selectedSheet = $0 },
                        onSearchCandidate: { candidate, selectedGoods in
                            openSearch(for: candidate, selectedGoods: selectedGoods, source: .userTag)
                        }
                    )

                    HomeDiscoverySection(
                        title: "メンバーでマッチ",
                        candidates: userCandidates,
                        layout: .grid,
                        cardTitleStyle: .member,
                        onSelect: { selectedSheet = $0 },
                        onSearchCandidate: { candidate, selectedGoods in
                            openSearch(for: candidate, selectedGoods: selectedGoods, source: .user)
                        }
                    )

                    if !havesCandidates.isEmpty {
                        HomeDiscoverySection(
                            title: "求められているグッズ",
                            candidates: havesCandidates,
                            layout: .rail,
                            onSelect: { selectedSheet = $0 }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, HomeDiscoveryHeaderMetrics.contentTopPadding)
                .padding(.bottom, HomeDiscoveryHeaderMetrics.contentBottomPadding)
                .megrumReportsScrollContentTop(in: "home-discovery-candidates-refresh")
                .megrumSuppressesEnclosingScrollEdgeEffects()
            }
            .megrumHiddenBottomScrollEdgeEffect()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } chrome: { isCollapsed in
            pinnedHeader(isCollapsed: isCollapsed)
        }
        .overlay {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(MegrumTheme.lavender)
                        .padding(18)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                if let sharePromptContext {
                    GoodsSharePromptOverlay(
                        context: sharePromptContext,
                        isPreparing: isPreparingSharePost,
                        errorMessage: sharePostErrorMessage,
                        onDismiss: dismissSharePrompt,
                        onShare: startGoodsSharePost
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
                    .zIndex(20)
                }
            }
        }
        .sheet(
            item: $selectedSheet,
            onDismiss: presentPendingProposalIfNeeded
        ) { sheet in
            HomeDiscoverySheetView(
                sheet: sheet,
                appState: appState,
                viewerOfferGoods: viewerOfferGoods,
                onOpenOwnerProfile: requestProfilePresentation,
                onStartProposal: requestProposalPresentation
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedMutualMatchCandidate) { candidate in
            HomeMutualMatchDetailSheet(
                candidate: candidate,
                allCandidates: mutualMatchCandidates,
                appState: appState,
                viewerOfferGoods: viewerOfferGoods,
                goodsTypes: goodsTypes,
                matchedItems: matchedItems,
                possibleItems: possibleItems,
                conditionSignalsByItemID: displayConditionSignalsByItemID,
                onOpenOwnerProfile: requestProfilePresentationFromMutualMatch,
                onStartProposal: requestProposalPresentationFromMutualMatch
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .homeIndividualListingCreationPresentation(isPresented: $showsIndividualListingCreation) {
            if let appState {
                NavigationStack {
                    IndividualListingEditorSheet(
                        appState: appState,
                        initialStep: .haves,
                        onCreatedListing: handleCreatedListingShare
                    )
                }
            }
        }
        .sheet(isPresented: $showsMatchHelp) {
            HomeMatchLogicHelpSheet(
                exchangeSettings: defaultExchangeSettings,
                onOpenWish: {
                    showsMatchHelp = false
                    onOpenWish()
                },
                onOpenIndividualListings: {
                    showsMatchHelp = false
                    onOpenIndividualListings()
                },
                onOpenExchangeSettings: {
                    showsMatchHelp = false
                    onOpenExchangeSettings()
                },
                onOpenPaymentSettings: {
                    showsMatchHelp = false
                    onOpenPaymentSettings()
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .task {
            openInitialSheetIfNeeded()
        }
        #if os(iOS)
        .sheet(item: $shareActivityPayload, content: GoodsShareActivitySheet.init)
        #endif
        .animation(.spring(response: 0.30, dampingFraction: 0.86), value: sharePromptContext?.id)
    }

}
