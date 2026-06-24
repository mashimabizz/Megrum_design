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

    @AppStorage(HomeExchangeSettingsStorageKeys.preference) private var exchangePreferenceRawValue = HomeDefaultExchangeSettings.standard.preference.rawValue
    @AppStorage(HomeExchangeSettingsStorageKeys.requiresSamePrefecture) private var exchangeRequiresSamePrefecture = HomeDefaultExchangeSettings.standard.requiresSamePrefecture
    @AppStorage(HomeExchangeSettingsStorageKeys.requiresDateOverlap) private var exchangeRequiresDateOverlap = HomeDefaultExchangeSettings.standard.requiresDateOverlap
    @State private var selectedSheet: HomeDiscoverySheet?
    @State private var selectedMutualMatchCandidate: HomeMutualMatchCandidate?
    @State private var showsMatchHelp = false
    @State private var pendingProposalSelection: HomeDiscoveryProposalSelection?
    @State private var pendingProfileUserID: UUID?
    @State private var didOpenInitialSheet = false
    @State private var selectedPrimaryTab: HomeDiscoveryPrimaryTab = .mutual
    @State private var showsIndividualListingCreation = false
    @State private var primaryTabPageWidth: CGFloat = 1
    @GestureState private var primaryTabDragTranslation: CGFloat = 0

    var body: some View {
        ZStack(alignment: .top) {
            GeometryReader { geometry in
                TabView(selection: $selectedPrimaryTab) {
                    HomeMutualMatchPage(
                        candidates: mutualMatchCandidates,
                        listingCount: viewerIndividualListingCount,
                        contentTopPadding: HomeDiscoveryHeaderMetrics.contentTopPadding,
                        onSelect: { selectedMutualMatchCandidate = $0 },
                        onCreateListing: openIndividualListingCreation
                    )
                    .refreshable {
                        await onRefresh()
                    }
                    .tag(HomeDiscoveryPrimaryTab.mutual)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            HomeDiscoverySection(
                                title: "メンバー×タグでマッチ",
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
                        .padding(.bottom, 34)
                    }
                    .refreshable {
                        await onRefresh()
                    }
                    .tag(HomeDiscoveryPrimaryTab.candidates)

                    HomeListingTimelinePage(
                        contentTopPadding: HomeDiscoveryHeaderMetrics.contentTopPadding
                    )
                    .refreshable {
                        await onRefresh()
                    }
                    .tag(HomeDiscoveryPrimaryTab.timeline)
                }
                .megrumPageTabViewStyle()
                .simultaneousGesture(primaryTabDragGesture(pageWidth: geometry.size.width))
                .onAppear {
                    primaryTabPageWidth = max(1, geometry.size.width)
                }
                .onChange(of: geometry.size.width) { _, width in
                    primaryTabPageWidth = max(1, width)
                }
            }

            VStack {
                Spacer()
                HStack {
                    LiquidGlassSearchButton(action: onOpenSearch)
                    Spacer()
                }
                .padding(.leading, FloatingActionLayoutMetrics.leadingPadding)
                .padding(.bottom, FloatingActionLayoutMetrics.homeSearchBottomPadding)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)

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

    private var userTagCandidates: [HomeDiscoveryCandidate] {
        let items = partnerItems(from: matchedItems + possibleItems)
            .filter { item in
                HomeDiscoveryMatchPolicy.isMemberTagMatchEligible(
                    item: item,
                    signals: displayConditionSignalsByItemID[item.id]
                )
            }
            .sorted(by: candidateSorter.areInCandidateOrder)
        let candidates = HomeDiscoveryCandidateFactory.candidates(
            from: items,
            source: .userTag,
            goodsTypes: goodsTypes,
            conditionSignalsByItemID: displayConditionSignalsByItemID
        )
        return Array(candidates.prefix(4))
    }

    private var userCandidates: [HomeDiscoveryCandidate] {
        let items = partnerItems(from: matchedItems + possibleItems)
            .filter { item in
                HomeDiscoveryMatchPolicy.isMemberMatchEligible(
                    item: item,
                    signals: displayConditionSignalsByItemID[item.id]
                )
            }
            .sorted(by: candidateSorter.areInCandidateOrder)
        let candidates = HomeDiscoveryCandidateFactory.candidates(
            from: items,
            source: .user,
            goodsTypes: goodsTypes,
            conditionSignalsByItemID: displayConditionSignalsByItemID
        )
        return Array(candidates.prefix(HomeDiscoveryCandidateFactory.memberCandidateDisplayLimit))
    }

    private var havesCandidates: [HomeDiscoveryCandidate] {
        let inventoryViewerItems = ownItems(from: inventoryItems)
        let viewerItems = inventoryViewerItems.isEmpty ? ownItems(from: matchedItems + possibleItems) : inventoryViewerItems
        let sourceItems = viewerItems.isEmpty ? possibleItems : viewerItems
        let sortedSourceItems = sourceItems
            .filter { havesWishHitCount(for: $0) > 0 }
            .sorted(by: candidateSorter.areInHavesOrder)
        let candidates = HomeDiscoveryCandidateFactory.candidates(
            from: Array(sortedSourceItems.prefix(8)),
            source: .haves,
            goodsTypes: goodsTypes,
            conditionSignalsByItemID: displayConditionSignalsByItemID
        )
        let itemByID = sortedSourceItems.reduce(into: [UUID: GoodsItem]()) { result, item in
            result[item.id] = result[item.id] ?? item
        }
        let havesCandidates = candidates.compactMap { candidate in
            visibleHavesCandidate(candidate, sourceItem: itemByID[candidate.id])
        }
        return havesCandidates
    }

    private var viewerOfferGoods: [HomeMockGoods] {
        ownItems(from: inventoryItems)
            .filter { $0.marketAvailableQuantity > 0 }
            .enumerated()
            .map { index, item in
                HomeMockGoods.from(item: item, index: index, goodsTypes: goodsTypes)
            }
    }

    private var mutualMatchCandidates: [HomeMutualMatchCandidate] {
        HomeMutualMatchCandidateFactory.candidates(
            mutualMatchData: mutualMatchCandidateData,
            viewerID: viewer?.id,
            inventoryItems: inventoryItems,
            matchedItems: matchedItems,
            possibleItems: possibleItems,
            goodsTypes: goodsTypes,
            conditionSignalsByItemID: displayConditionSignalsByItemID
        )
    }

    private var viewerIndividualListingCount: Int {
        appState?.listings.filter { $0.status != .closed }.count ?? 0
    }

    private var candidateSorter: HomeDiscoveryCandidateSorter {
        HomeDiscoveryCandidateSorter(conditionSignalsByItemID: displayConditionSignalsByItemID)
    }

    private var defaultExchangeSettings: HomeDefaultExchangeSettings {
        HomeDefaultExchangeSettings(
            preferenceRawValue: exchangePreferenceRawValue,
            requiresSamePrefecture: exchangeRequiresSamePrefecture,
            requiresDateOverlap: exchangeRequiresDateOverlap
        )
    }

    private var displayConditionSignalsByItemID: [UUID: HomeCandidateConditionSignals] {
        defaultExchangeSettings.applying(to: conditionSignalsByItemID)
    }

    private func partnerItems(from items: [GoodsItem]) -> [GoodsItem] {
        guard let viewerID = viewer?.id else {
            return deduplicated(items)
        }
        return deduplicated(items.filter { $0.ownerID != viewerID })
    }

    private func ownItems(from items: [GoodsItem]) -> [GoodsItem] {
        guard let viewerID = viewer?.id else {
            return []
        }
        return deduplicated(items.filter { $0.ownerID == viewerID })
    }

    private func openInitialSheetIfNeeded() {
        guard opensInitialHavesLookup, !didOpenInitialSheet else {
            return
        }
        didOpenInitialSheet = true
        selectedSheet = havesCandidates.first?.sheet
    }

    private func openIndividualListingCreation() {
        guard let appState else {
            onOpenIndividualListings()
            return
        }

        showsIndividualListingCreation = true
        Task {
            if appState.oshiGroups.isEmpty || appState.oshiGenres.isEmpty {
                await appState.loadOshiGroups()
            }
            if appState.goodsTypes.isEmpty {
                await appState.loadGoodsTypes()
            }
        }
    }

    private func openSearch(
        for candidate: HomeDiscoveryCandidate,
        selectedGoods: HomeMockGoods?,
        source: HomeDiscoveryCandidateSource
    ) {
        onOpenSearchWithCriteria(
            HomeDiscoverySearchRoutePolicy.criteria(
                for: candidate,
                selectedGoods: selectedGoods,
                source: source
            )
        )
    }

    private func requestProposalPresentation(_ selection: HomeDiscoveryProposalSelection) {
        pendingProposalSelection = nil
        selectedSheet = nil
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: HomeDiscoveryDeferredPresentationPolicy.sheetDismissalDelayNanoseconds)
            onStartProposal(selection)
        }
    }

    private func requestProfilePresentation(_ userID: UUID) {
        pendingProfileUserID = userID
        selectedSheet = nil
    }

    private func requestProposalPresentationFromMutualMatch(_ selection: HomeDiscoveryProposalSelection) {
        selectedMutualMatchCandidate = nil
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: HomeDiscoveryDeferredPresentationPolicy.sheetDismissalDelayNanoseconds)
            onStartProposal(selection)
        }
    }

    private func requestProfilePresentationFromMutualMatch(_ userID: UUID) {
        selectedMutualMatchCandidate = nil
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: HomeDiscoveryDeferredPresentationPolicy.sheetDismissalDelayNanoseconds)
            onOpenOwnerProfile(userID)
        }
    }

    private func presentPendingProposalIfNeeded() {
        if let pendingProfileUserID {
            self.pendingProfileUserID = nil
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: HomeDiscoveryDeferredPresentationPolicy.sheetDismissalDelayNanoseconds)
                onOpenOwnerProfile(pendingProfileUserID)
            }
            return
        }

        guard let selection = pendingProposalSelection else {
            return
        }
        pendingProposalSelection = nil
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: HomeDiscoveryDeferredPresentationPolicy.sheetDismissalDelayNanoseconds)
            onStartProposal(selection)
        }
    }

    private func deduplicated(_ items: [GoodsItem]) -> [GoodsItem] {
        var seen: Set<UUID> = []
        var result: [GoodsItem] = []
        for item in items where seen.insert(item.id).inserted {
            result.append(item)
        }
        return result
    }

    private func visibleHavesCandidate(
        _ candidate: HomeDiscoveryCandidate,
        sourceItem: GoodsItem?
    ) -> HomeDiscoveryCandidate? {
        guard let sourceItem else {
            return nil
        }
        let payload = havesLookupPayload(for: sourceItem, baseCandidate: candidate)
        guard payload.hasAnyMatches else {
            return nil
        }
        var updated = candidate
        updated.sheet = .havesLookup(payload)
        return updated
    }

    private func havesLookupPayload(
        for offeredItem: GoodsItem,
        baseCandidate: HomeDiscoveryCandidate
    ) -> HomeHavesLookupPayload {
        let offeredGoods = baseCandidate.goods.first ?? HomeMockGoods.from(
            item: offeredItem,
            index: 0,
            goodsTypes: goodsTypes
        )
        let offeredSignals = displayConditionSignalsByItemID[offeredItem.id] ?? baseCandidate.signals
        let tagMatchedItems = havesTagMatchedItems(for: offeredItem)
        let tagMatchedIDs = Set(tagMatchedItems.map(\.id))
        let memberMatchedItems = havesMemberMatchedItems(for: offeredItem)
            .filter { !tagMatchedIDs.contains($0.id) }

        return HomeHavesLookupPayload(
            offeredGoods: offeredGoods,
            offeredSignals: offeredSignals,
            tagMatchedCandidates: havesMatchCandidates(
                from: tagMatchedItems,
                source: .userTag,
                preferredOfferGoodsID: offeredItem.id
            ),
            memberMatchedCandidates: havesMatchCandidates(
                from: memberMatchedItems,
                source: .user,
                preferredOfferGoodsID: offeredItem.id
            )
        )
    }

    private func havesTagMatchedItems(for offeredItem: GoodsItem) -> [GoodsItem] {
        let offeredTags = matchingTagSet(for: offeredItem)
        guard !offeredTags.isEmpty else {
            return []
        }
        return havesPartnerPool(for: offeredItem)
            .filter { !matchingTagSet(for: $0).isDisjoint(with: offeredTags) }
            .sorted(by: candidateSorter.areInCandidateOrder)
    }

    private func havesMemberMatchedItems(for offeredItem: GoodsItem) -> [GoodsItem] {
        havesPartnerPool(for: offeredItem)
            .sorted(by: candidateSorter.areInCandidateOrder)
    }

    private func havesPartnerPool(for offeredItem: GoodsItem) -> [GoodsItem] {
        let partnerUserIDs = Set(displayConditionSignalsByItemID[offeredItem.id]?.wishMatchedPartnerUserIDs ?? [])
        guard !partnerUserIDs.isEmpty else {
            return []
        }
        return partnerItems(from: matchedItems + possibleItems)
            .filter { $0.id != offeredItem.id }
            .filter { partnerUserIDs.contains($0.ownerID) }
    }

    private func havesMatchCandidates(
        from items: [GoodsItem],
        source: HomeDiscoveryCandidateSource,
        preferredOfferGoodsID: UUID
    ) -> [HomeDiscoveryCandidate] {
        HomeDiscoveryCandidateFactory.candidates(
            from: Array(items.prefix(6)),
            source: source,
            goodsTypes: goodsTypes,
            conditionSignalsByItemID: displayConditionSignalsByItemID
        )
        .map { candidate in
            var updated = candidate
            updated.sheet = havesMatchSheet(for: candidate, preferredOfferGoodsID: preferredOfferGoodsID)
            return updated
        }
    }

    private func havesMatchSheet(
        for candidate: HomeDiscoveryCandidate,
        preferredOfferGoodsID: UUID
    ) -> HomeDiscoverySheet {
        let goods = candidate.goods.first ?? HomeDiscoveryFixtures.selectedYellow
        let signals = candidate.conditionSignals(for: goods)
        let payload = HomeDiscoverySheetPayload(
            goods: goods,
            signals: signals,
            preferredOfferGoodsID: preferredOfferGoodsID
        )
        return HomeDiscoveryMatchPolicy.goodsCondition(for: signals.goods) == .direct
            ? .goodsHit(payload)
            : .wishHit(payload)
    }

    private func memberMatches(_ lhs: GoodsItem, _ rhs: GoodsItem) -> Bool {
        if let lhsMemberID = lhs.memberID,
           let rhsMemberID = rhs.memberID {
            return lhsMemberID == rhsMemberID
        }
        let lhsMemberName = normalizedMasterName(lhs.memberName)
        let rhsMemberName = normalizedMasterName(rhs.memberName)
        if !lhsMemberName.isEmpty, lhsMemberName == rhsMemberName {
            return true
        }
        if let lhsGroupID = lhs.groupID,
           let rhsGroupID = rhs.groupID {
            return lhsGroupID == rhsGroupID
        }
        return false
    }

    private func normalizedMasterName(_ value: String?) -> String {
        value?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() ?? ""
    }

    private func matchingTagSet(for item: GoodsItem) -> Set<String> {
        Set(HomeDiscoveryTagFormatter.matchingTagNames(for: item, goodsTypes: goodsTypes))
    }

    private func havesWishHitCount(for item: GoodsItem) -> Int {
        displayConditionSignalsByItemID[item.id]?.linkCounts.wishCount ?? 0
    }

    private var header: some View {
        HStack {
            Button(action: onOpenSettings) {
                HomeDiscoveryViewerAvatar(viewer: viewer)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("メニューを開く")

            Spacer()

            Text("Megrum")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Spacer()

            Button {
                showsMatchHelp = true
            } label: {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(MegrumTheme.lavender)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("マッチ表示のヘルプを開く")
        }
        .padding(.vertical, 2)
    }

    private var pinnedHeader: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            HomeDiscoveryTabSwitcher(
                selection: $selectedPrimaryTab,
                swipeProgress: primaryTabSwipeProgress
            )
        }
            .padding(.top, 10)
            .padding(.bottom, 0)
            .frame(maxWidth: .infinity)
            .background {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .overlay(MegrumTheme.canvas.opacity(0.34))
                    .ignoresSafeArea(edges: .top)
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(.white.opacity(0.42))
                    .frame(height: 1)
            }
            .zIndex(10)
    }

    private var primaryTabSwipeProgress: CGFloat {
        let selectedIndex = CGFloat(selectedPrimaryTab.index)
        let rawProgress = selectedIndex - (primaryTabDragTranslation / max(1, primaryTabPageWidth))
        let maximumProgress = CGFloat(HomeDiscoveryPrimaryTab.allCases.count - 1)
        return min(max(rawProgress, 0), maximumProgress)
    }

    private func primaryTabDragGesture(pageWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .local)
            .updating($primaryTabDragTranslation) { value, state, _ in
                guard abs(value.translation.width) > abs(value.translation.height) else {
                    return
                }
                state = value.translation.width
            }
    }
}

private enum HomeDiscoveryHeaderMetrics {
    static let contentTopPadding: CGFloat = 122
}
