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

    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $selectedPrimaryTab) {
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

                        AdBannerSlot(
                            placement: .homeFeedBanner,
                            displayContext: adDisplayContext
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, HomeDiscoveryHeaderMetrics.contentTopPadding)
                    .padding(.bottom, HomeDiscoveryHeaderMetrics.contentBottomPadding)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .tag(HomeDiscoveryPrimaryTab.candidates)

                HomeMutualMatchPage(
                    candidates: mutualMatchCandidates,
                    listingCount: viewerIndividualListingCount,
                    contentTopPadding: HomeDiscoveryHeaderMetrics.contentTopPadding,
                    refreshIndicatorTopPadding: HomeDiscoveryHeaderMetrics.pullRefreshIndicatorTopPadding,
                    onRefresh: onRefresh,
                    onSelect: { selectedMutualMatchCandidate = $0 },
                    onCreateListing: openIndividualListingCreation
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .tag(HomeDiscoveryPrimaryTab.mutual)
            }
            .megrumPageTabViewStyle()

            pinnedHeader
        }
        .overlay {
            if isLoading {
                ProgressView()
                    .tint(MegrumTheme.lavender)
                    .padding(18)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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
                        initialStep: .haves
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
    }

}
