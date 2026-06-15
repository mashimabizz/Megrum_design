import MegrumCore
import MegrumDesign
import SwiftUI

struct HomeDiscoveryExperience: View {
    var viewer: UserProfile?
    var inventoryItems: [GoodsItem] = []
    var matchedItems: [GoodsItem] = []
    var possibleItems: [GoodsItem] = []
    var goodsTypes: [GoodsType] = []
    var conditionSignalsByItemID: [UUID: HomeCandidateConditionSignals] = [:]
    var isLoading: Bool
    var opensInitialHavesLookup: Bool = false
    var onOpenSettings: () -> Void
    var onOpenSearch: () -> Void
    var onStartProposal: (HomeDiscoveryProposalSelection) -> Void = { _ in }
    var onRefresh: () async -> Void

    @State private var selectedSheet: HomeDiscoverySheet?
    @State private var pendingProposalSelection: HomeDiscoveryProposalSelection?
    @State private var didOpenInitialSheet = false

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HomeDiscoverySection(
                        title: "メンバー×タグでマッチ",
                        candidates: userTagCandidates,
                        layout: .grid,
                        cardTitleStyle: .memberTag,
                        onSelect: { selectedSheet = $0 }
                    )

                    HomeDiscoverySection(
                        title: "メンバーでマッチ",
                        candidates: userCandidates,
                        layout: .grid,
                        cardTitleStyle: .member,
                        onSelect: { selectedSheet = $0 }
                    )

                    if !havesCandidates.isEmpty {
                        HomeDiscoverySection(
                            title: "欲しがられているグッズ",
                            candidates: havesCandidates,
                            layout: .rail,
                            onSelect: { selectedSheet = $0 }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, HomeDiscoveryHeaderMetrics.contentTopPadding)
                .padding(.bottom, 34)
            }
            .refreshable {
                await onRefresh()
            }

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
                viewerOfferGoods: viewerOfferGoods,
                onStartProposal: requestProposalPresentation
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
                let signals = conditionSignalsByItemID[item.id]
                return signals?.matchesViewerWish == true && (signals?.tagMatchCount ?? 0) > 0
            }
            .sorted(by: candidateSorter.areInCandidateOrder)
        let candidates = HomeDiscoveryCandidateFactory.candidates(
            from: items,
            source: .userTag,
            goodsTypes: goodsTypes,
            conditionSignalsByItemID: conditionSignalsByItemID
        )
        return candidates.isEmpty ? HomeDiscoveryFixtures.userTagCandidates : Array(candidates.prefix(4))
    }

    private var userCandidates: [HomeDiscoveryCandidate] {
        let usedIDs = Set(userTagCandidates.flatMap { $0.goods.map(\.id) })
        let items = partnerItems(from: matchedItems + possibleItems)
            .filter { item in
                !usedIDs.contains(item.id)
                    && conditionSignalsByItemID[item.id]?.matchesViewerWish == true
            }
            .sorted(by: candidateSorter.areInCandidateOrder)
        let candidates = HomeDiscoveryCandidateFactory.candidates(
            from: Array(items.prefix(4)),
            source: .user,
            goodsTypes: goodsTypes,
            conditionSignalsByItemID: conditionSignalsByItemID
        )
        return candidates.isEmpty ? HomeDiscoveryFixtures.userCandidates : candidates
    }

    private var havesCandidates: [HomeDiscoveryCandidate] {
        let inventoryViewerItems = ownItems(from: inventoryItems)
        let viewerItems = inventoryViewerItems.isEmpty ? ownItems(from: matchedItems + possibleItems) : inventoryViewerItems
        let sourceItems = viewerItems.isEmpty ? possibleItems : viewerItems
        let sortedSourceItems = sourceItems.sorted(by: candidateSorter.areInHavesOrder)
        let candidates = HomeDiscoveryCandidateFactory.candidates(
            from: Array(sortedSourceItems.prefix(8)),
            source: .haves,
            goodsTypes: goodsTypes,
            conditionSignalsByItemID: conditionSignalsByItemID
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

    private var candidateSorter: HomeDiscoveryCandidateSorter {
        HomeDiscoveryCandidateSorter(conditionSignalsByItemID: conditionSignalsByItemID)
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

    private func requestProposalPresentation(_ selection: HomeDiscoveryProposalSelection) {
        pendingProposalSelection = selection
        selectedSheet = nil
    }

    private func presentPendingProposalIfNeeded() {
        guard let selection = pendingProposalSelection else {
            return
        }
        pendingProposalSelection = nil
        Task { @MainActor in
            await Task.yield()
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
        let offeredSignals = conditionSignalsByItemID[offeredItem.id] ?? baseCandidate.signals
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
            .filter { memberMatches($0, offeredItem) && !matchingTagSet(for: $0).isDisjoint(with: offeredTags) }
            .sorted(by: candidateSorter.areInCandidateOrder)
    }

    private func havesMemberMatchedItems(for offeredItem: GoodsItem) -> [GoodsItem] {
        havesPartnerPool(for: offeredItem)
            .filter { memberMatches($0, offeredItem) }
            .sorted(by: candidateSorter.areInCandidateOrder)
    }

    private func havesPartnerPool(for offeredItem: GoodsItem) -> [GoodsItem] {
        partnerItems(from: matchedItems + possibleItems)
            .filter { $0.id != offeredItem.id }
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
            conditionSignalsByItemID: conditionSignalsByItemID
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
        let lhsMemberName = HomeDiscoveryTitleParser.comparableMemberName(from: lhs.title)
        let rhsMemberName = HomeDiscoveryTitleParser.comparableMemberName(from: rhs.title)
        if !lhsMemberName.isEmpty, lhsMemberName == rhsMemberName {
            return true
        }
        if let lhsGroupID = lhs.groupID,
           let rhsGroupID = rhs.groupID {
            return lhsGroupID == rhsGroupID
        }
        return false
    }

    private func matchingTagSet(for item: GoodsItem) -> Set<String> {
        Set(HomeDiscoveryTagFormatter.matchingTagNames(for: item, goodsTypes: goodsTypes))
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

            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.vertical, 2)
    }

    private var pinnedHeader: some View {
        header
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 8)
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
}

private enum HomeDiscoveryHeaderMetrics {
    static let contentTopPadding: CGFloat = 72
}
