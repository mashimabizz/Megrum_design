import MegrumCore
import MegrumDesign
import SwiftUI

struct MatchRelationProposalTarget: Identifiable, Equatable {
    var targetItem: GoodsItem
    var listingID: UUID?
    var receiverGoodsIDs: [UUID]
    var senderGoodsIDs: [UUID]
    var matchType: ProposalMatchType

    var id: String {
        [
            targetItem.id.uuidString,
            listingID?.uuidString ?? "multi-or-simple",
            receiverGoodsIDs.map(\.uuidString).joined(separator: ","),
            senderGoodsIDs.map(\.uuidString).joined(separator: ","),
            matchType.rawValue
        ]
        .joined(separator: "|")
    }
}

struct MatchRelationListingDetail: Identifiable, Equatable {
    var listing: IndividualListing
    var isMyListing: Bool
    var haves: [MatchRelationHave]
    var options: [MatchRelationOption]

    var id: UUID { listing.id }

    var selectableOptionCount: Int {
        options.filter { !$0.option.isCashOffer }.count
    }
}

struct MatchRelationHave: Identifiable, Equatable {
    var item: GoodsItem
    var quantity: Int
    var matched: Bool

    var id: UUID { item.id }
}

struct MatchRelationOption: Identifiable, Equatable {
    var option: IndividualListingWishOption
    var wishes: [MatchRelationWish]
    var matched: Bool

    var id: UUID { option.id }
}

struct MatchRelationWish: Identifiable, Equatable {
    var item: GoodsItem
    var quantity: Int
    var candidates: [MatchRelationCandidate]

    var id: UUID { item.id }
}

struct MatchRelationCandidate: Identifiable, Equatable {
    var item: GoodsItem
    var quantity: Int

    var id: UUID { item.id }
}

struct MatchRelationWishPopupTarget: Identifiable, Equatable {
    var listingID: UUID
    var viewpoint: MatchRelationViewpoint
    var wish: MatchRelationWish
    var exchangeType: IndividualListingExchangeType
    var fallbackHave: MatchRelationHave

    var id: String {
        [
            listingID.uuidString,
            viewpoint.rawValue,
            wish.id.uuidString
        ]
        .joined(separator: "|")
    }
}

enum MatchRelationViewpoint: String, Equatable {
    case mine
    case partner
}

enum MatchRelationPopupCopy {
    static func candidateOwnerTitle(viewpoint: MatchRelationViewpoint, partnerHandle: String) -> String {
        switch viewpoint {
        case .mine:
            "@\(partnerHandle) が譲るもの"
        case .partner:
            "あなたが譲るもの"
        }
    }

    static func subtitle(quantity: Int, candidateCount: Int) -> String {
        "wish ×\(quantity)・\(candidateCount) 件の候補"
    }

    static func fallbackTitle(_ title: String) -> String {
        "↑ あなたの譲：\(title)"
    }
}

enum MatchRelationSwipeDirection {
    case previous
    case next

    var step: Int {
        switch self {
        case .previous:
            -1
        case .next:
            1
        }
    }
}

enum MatchRelationSwipeResolver {
    static let minimumHorizontalDistance: CGFloat = 8
    static let horizontalPriorityRatio: CGFloat = 1.08
    static let edgeResistanceRatio: CGFloat = 0.22

    static func direction(for translation: CGSize) -> MatchRelationSwipeDirection? {
        guard isHorizontalSwipe(translation) else {
            return nil
        }
        return translation.width < 0 ? .next : .previous
    }

    static func presentationOffset(
        translation: CGSize,
        screenWidth: CGFloat,
        hasAdjacentTarget: Bool
    ) -> CGFloat? {
        guard direction(for: translation) != nil else {
            return nil
        }
        let rawOffset = hasAdjacentTarget ? translation.width : translation.width * edgeResistanceRatio
        return max(-screenWidth, min(screenWidth, rawOffset))
    }

    static func shouldSwitchTarget(
        translation: CGSize,
        predictedEndTranslationWidth: CGFloat,
        screenWidth: CGFloat,
        hasAdjacentTarget: Bool
    ) -> Bool {
        guard hasAdjacentTarget, direction(for: translation) != nil else {
            return false
        }
        let absX = abs(translation.width)
        let fastEnough = abs(predictedEndTranslationWidth) >= absX + 32 && absX >= 42
        return absX >= threshold(screenWidth: screenWidth) || fastEnough
    }

    static func threshold(screenWidth: CGFloat) -> CGFloat {
        min(118, max(72, screenWidth * 0.24))
    }

    private static func isHorizontalSwipe(_ translation: CGSize) -> Bool {
        let absX = abs(translation.width)
        let absY = abs(translation.height)
        return absX > minimumHorizontalDistance && absX > absY * horizontalPriorityRatio
    }
}

struct MatchRelationAggregate: Equatable {
    var senderItems: [GoodsItem]
    var receiverItems: [GoodsItem]
    var senderIDs: [UUID]
    var receiverIDs: [UUID]
    var referencedListingIDs: [UUID]

    static let empty = MatchRelationAggregate(
        senderItems: [],
        receiverItems: [],
        senderIDs: [],
        receiverIDs: [],
        referencedListingIDs: []
    )

    var isEmpty: Bool {
        senderIDs.isEmpty || receiverIDs.isEmpty || referencedListingIDs.isEmpty
    }
}

enum MatchRelationBottomBarCopy {
    static func primaryTitle(isEnabled: Bool, showsReset: Bool, totalSelectionCount: Int) -> String {
        guard isEnabled else {
            return "候補を読み込んでいます"
        }
        if showsReset {
            return "打診に進む（\(totalSelectionCount)件）"
        }
        return "この内容で打診へ"
    }

    static func secondaryTitle(showsReset: Bool) -> String {
        showsReset ? "リセット" : "閉じる"
    }
}

enum MatchRelationComposer {
    static func selectableSenderGoods(from inventory: [GoodsItem]) -> [GoodsItem] {
        inventory.filter { item in
            guard item.kind == nil || item.kind == .inventory else {
                return false
            }
            switch item.status {
            case nil, .active, .reserved:
                return true
            case .keep, .traded, .archived:
                return false
            }
        }
    }

    static func deduplicatedGoods(_ items: [GoodsItem]) -> [GoodsItem] {
        var seen: Set<UUID> = []
        return items.filter { seen.insert($0.id).inserted }
    }

    static func orderedIDs(_ selectedIDs: Set<UUID>, in items: [GoodsItem]) -> [UUID] {
        items.map(\.id).filter { selectedIDs.contains($0) }
    }

    static func fallbackSenderIDs(for target: GoodsItem, inventory: [GoodsItem]) -> [UUID] {
        let exact = inventory.filter { item in
            item.groupID == target.groupID
                && item.memberID == target.memberID
                && item.goodsTypeID == target.goodsTypeID
        }
        if let firstExact = exact.first {
            return [firstExact.id]
        }

        let sameGroup = inventory.filter { item in
            item.groupID == target.groupID
                && (target.goodsTypeID == nil || item.goodsTypeID == target.goodsTypeID)
        }
        if let firstSameGroup = sameGroup.first {
            return [firstSameGroup.id]
        }

        return inventory.first.map { [$0.id] } ?? []
    }

    static func buildRelationDetails(
        ownListings: [IndividualListing],
        partnerListings: [IndividualListing],
        senderGoods: [GoodsItem],
        partnerGoods: [GoodsItem],
        highlightedItemID: UUID
    ) -> [MatchRelationListingDetail] {
        let ownDetails = ownListings
            .filter { $0.status == .active }
            .compactMap { listing in
                detail(
                    for: listing,
                    isMyListing: true,
                    havesSource: senderGoods,
                    candidateSource: partnerGoods,
                    highlightedItemID: highlightedItemID
                )
            }

        let partnerDetails = partnerListings
            .filter { $0.status == .active }
            .compactMap { listing in
                detail(
                    for: listing,
                    isMyListing: false,
                    havesSource: partnerGoods,
                    candidateSource: senderGoods,
                    highlightedItemID: highlightedItemID
                )
            }

        return ownDetails + partnerDetails
    }

    static func relationSwipeItems(homeMatchedItems: [GoodsItem], currentTarget: GoodsItem) -> [GoodsItem] {
        let deduplicated = deduplicatedGoods(homeMatchedItems)
        guard !deduplicated.isEmpty else {
            return [currentTarget]
        }
        if deduplicated.contains(where: { $0.id == currentTarget.id }) {
            return deduplicated
        }
        return deduplicatedGoods([currentTarget] + deduplicated)
    }

    static func adjacentSwipeTarget(
        in items: [GoodsItem],
        currentID: UUID,
        direction: MatchRelationSwipeDirection
    ) -> GoodsItem? {
        guard let currentIndex = items.firstIndex(where: { $0.id == currentID }) else {
            return nil
        }
        let nextIndex = currentIndex + direction.step
        guard items.indices.contains(nextIndex) else {
            return nil
        }
        return items[nextIndex]
    }

    static func initialCandidateSelection(
        for details: [MatchRelationListingDetail],
        highlightedItemID: UUID
    ) -> [UUID: Set<UUID>] {
        var selection: [UUID: Set<UUID>] = [:]

        for detail in details {
            let highlightedHave = detail.haves.contains { $0.item.id == highlightedItemID }
            for option in detail.options where !option.option.isCashOffer {
                if highlightedHave, selection[detail.id, default: []].isEmpty {
                    let defaults = defaultCandidateIDs(for: option)
                    if !defaults.isEmpty {
                        selection[detail.id] = Set(defaults)
                        continue
                    }
                }

                for wish in option.wishes {
                    if wish.candidates.contains(where: { $0.item.id == highlightedItemID }) {
                        selection[detail.id, default: []].insert(highlightedItemID)
                    }
                }
            }
        }

        return selection
    }

    static func initialHaveSelection(
        for details: [MatchRelationListingDetail],
        highlightedItemID: UUID
    ) -> [UUID: Set<UUID>] {
        var selection: [UUID: Set<UUID>] = [:]

        for detail in details where detail.listing.haveLogic == .one && detail.haves.count >= 2 {
            let highlighted = detail.haves.first { $0.item.id == highlightedItemID }
            let first = highlighted ?? detail.haves.first(where: \.matched) ?? detail.haves.first
            if let first {
                selection[detail.id] = [first.item.id]
            }
        }

        return selection
    }

    static func defaultPopupTarget(
        for details: [MatchRelationListingDetail],
        highlightedItemID: UUID
    ) -> MatchRelationWishPopupTarget? {
        for detail in details {
            for option in detail.options where !option.option.isCashOffer {
                for wish in option.wishes where !wish.candidates.isEmpty {
                    guard wish.candidates.contains(where: { $0.item.id == highlightedItemID }),
                          let fallbackHave = defaultFallbackHave(for: detail, highlightedItemID: highlightedItemID) else {
                        continue
                    }
                    return MatchRelationWishPopupTarget(
                        listingID: detail.id,
                        viewpoint: detail.isMyListing ? .mine : .partner,
                        wish: wish,
                        exchangeType: option.option.exchangeType,
                        fallbackHave: fallbackHave
                    )
                }
            }
        }

        for detail in details {
            for option in detail.options where !option.option.isCashOffer {
                if let wish = option.wishes.first(where: { !$0.candidates.isEmpty }),
                   let fallbackHave = defaultFallbackHave(for: detail, highlightedItemID: highlightedItemID) {
                    return MatchRelationWishPopupTarget(
                        listingID: detail.id,
                        viewpoint: detail.isMyListing ? .mine : .partner,
                        wish: wish,
                        exchangeType: option.option.exchangeType,
                        fallbackHave: fallbackHave
                    )
                }
            }
        }

        return nil
    }

    static func defaultFallbackHave(
        for detail: MatchRelationListingDetail,
        highlightedItemID: UUID
    ) -> MatchRelationHave? {
        detail.haves.first { $0.item.id == highlightedItemID }
            ?? detail.haves.first(where: \.matched)
            ?? detail.haves.first
    }

    static func selectedCandidates(
        for wish: MatchRelationWish,
        selectedCandidateIDs: Set<UUID>
    ) -> [MatchRelationCandidate] {
        wish.candidates.filter { selectedCandidateIDs.contains($0.item.id) }
    }

    static func hasSelectedCandidate(
        for wish: MatchRelationWish,
        selectedCandidateIDs: Set<UUID>
    ) -> Bool {
        !selectedCandidates(for: wish, selectedCandidateIDs: selectedCandidateIDs).isEmpty
    }

    static func popupTarget(
        listingID: UUID,
        viewpoint: MatchRelationViewpoint,
        option: MatchRelationOption,
        wish: MatchRelationWish,
        fallbackHave: MatchRelationHave
    ) -> MatchRelationWishPopupTarget {
        MatchRelationWishPopupTarget(
            listingID: listingID,
            viewpoint: viewpoint,
            wish: wish,
            exchangeType: option.option.exchangeType,
            fallbackHave: fallbackHave
        )
    }

    static func aggregateSelection(
        details: [MatchRelationListingDetail],
        selectedCandidateIDsByListingID: [UUID: Set<UUID>],
        selectedHaveIDsByListingID: [UUID: Set<UUID>]
    ) -> MatchRelationAggregate {
        var senderItems: [GoodsItem] = []
        var receiverItems: [GoodsItem] = []
        var senderIDs: Set<UUID> = []
        var receiverIDs: Set<UUID> = []
        var referencedListingIDs: [UUID] = []

        func add(_ item: GoodsItem, to items: inout [GoodsItem], ids: inout Set<UUID>) {
            guard ids.insert(item.id).inserted else {
                return
            }
            items.append(item)
        }

        for detail in details {
            let selectedCandidateIDs = selectedCandidateIDsByListingID[detail.id] ?? []
            guard !selectedCandidateIDs.isEmpty else {
                continue
            }

            var seenCandidateIDs: Set<UUID> = []
            let selectedCandidates = detail.options
                .flatMap(\.wishes)
                .flatMap(\.candidates)
                .compactMap { candidate -> GoodsItem? in
                    guard selectedCandidateIDs.contains(candidate.item.id),
                          seenCandidateIDs.insert(candidate.item.id).inserted else {
                        return nil
                    }
                    return candidate.item
                }

            let selectedHaves: [MatchRelationHave]
            if detail.listing.haveLogic == .one, detail.haves.count >= 2 {
                let selectedHaveIDs = selectedHaveIDsByListingID[detail.id] ?? []
                selectedHaves = detail.haves.filter { selectedHaveIDs.contains($0.item.id) }
            } else {
                selectedHaves = detail.haves
            }

            guard !selectedCandidates.isEmpty, !selectedHaves.isEmpty else {
                continue
            }

            referencedListingIDs.append(detail.id)

            if detail.isMyListing {
                for have in selectedHaves {
                    add(have.item, to: &senderItems, ids: &senderIDs)
                }
                for candidate in selectedCandidates {
                    add(candidate, to: &receiverItems, ids: &receiverIDs)
                }
            } else {
                for candidate in selectedCandidates {
                    add(candidate, to: &senderItems, ids: &senderIDs)
                }
                for have in selectedHaves {
                    add(have.item, to: &receiverItems, ids: &receiverIDs)
                }
            }
        }

        return MatchRelationAggregate(
            senderItems: senderItems,
            receiverItems: receiverItems,
            senderIDs: Array(senderIDs),
            receiverIDs: Array(receiverIDs),
            referencedListingIDs: referencedListingIDs
        )
    }

    static func itemsMatch(candidate: GoodsItem, wish: GoodsItem, fallbackGroupID: UUID?, fallbackGoodsTypeID: UUID?) -> Bool {
        let wishGroupID = wish.groupID ?? fallbackGroupID
        let wishGoodsTypeID = wish.goodsTypeID ?? fallbackGoodsTypeID

        let candidateGoodsTypeID = candidate.goodsTypeID
        if candidateGoodsTypeID != wishGoodsTypeID,
           candidateGoodsTypeID != nil || wishGoodsTypeID != nil {
            return false
        }
        if let candidateMemberID = candidate.memberID, let wishMemberID = wish.memberID {
            return candidateMemberID == wishMemberID
        }
        guard let candidateGroupID = candidate.groupID, let wishGroupID else {
            return candidate.id == wish.id
        }
        return candidateGroupID == wishGroupID
    }

    private static func detail(
        for listing: IndividualListing,
        isMyListing: Bool,
        havesSource: [GoodsItem],
        candidateSource: [GoodsItem],
        highlightedItemID: UUID
    ) -> MatchRelationListingDetail? {
        let havesByID = goodsByID(havesSource)
        let candidatesByID = goodsByID(candidateSource)
        let haves = listing.haves.compactMap { quantity -> MatchRelationHave? in
            guard let item = havesByID[quantity.itemID] else {
                return nil
            }
            return MatchRelationHave(
                item: item,
                quantity: quantity.quantity,
                matched: item.id == highlightedItemID || listing.options.contains { option in
                    option.wishes.contains { wish in
                        if let wishItem = candidatesByID[wish.itemID] {
                            return itemsMatch(
                                candidate: item,
                                wish: wishItem,
                                fallbackGroupID: option.wishGroupID,
                                fallbackGoodsTypeID: option.wishGoodsTypeID
                            )
                        }
                        return false
                    }
                }
            )
        }

        guard !haves.isEmpty else {
            return nil
        }

        let goodsByID = goodsByID(havesSource + candidateSource)
        let options = listing.options.map { option -> MatchRelationOption in
            let wishes = option.wishes.compactMap { wishQuantity -> MatchRelationWish? in
                let wishItem = goodsByID[wishQuantity.itemID] ?? GoodsItem(
                    id: wishQuantity.itemID,
                    ownerID: listing.ownerID,
                    groupID: option.wishGroupID,
                    goodsTypeID: option.wishGoodsTypeID,
                    title: "グッズ"
                )
                let candidates = candidateSource
                    .filter { candidate in
                        candidate.id == wishQuantity.itemID
                            || itemsMatch(
                                candidate: candidate,
                                wish: wishItem,
                                fallbackGroupID: option.wishGroupID,
                                fallbackGoodsTypeID: option.wishGoodsTypeID
                            )
                    }
                    .map { MatchRelationCandidate(item: $0, quantity: 1) }

                return MatchRelationWish(
                    item: wishItem,
                    quantity: wishQuantity.quantity,
                    candidates: deduplicatedCandidates(candidates)
                )
            }

            return MatchRelationOption(
                option: option,
                wishes: wishes,
                matched: option.isCashOffer || wishes.contains { !$0.candidates.isEmpty }
            )
        }

        let hasCandidateRelation = options.contains { option in
            !option.option.isCashOffer && option.wishes.contains { !$0.candidates.isEmpty }
        }
        let hasHighlightedHave = haves.contains { $0.item.id == highlightedItemID }
        guard hasCandidateRelation || hasHighlightedHave else {
            return nil
        }

        return MatchRelationListingDetail(
            listing: listing,
            isMyListing: isMyListing,
            haves: haves,
            options: options
        )
    }

    private static func goodsByID(_ items: [GoodsItem]) -> [UUID: GoodsItem] {
        items.reduce(into: [:]) { result, item in
            result[item.id] = result[item.id] ?? item
        }
    }

    private static func defaultCandidateIDs(for option: MatchRelationOption) -> [UUID] {
        let visibleWishes = option.wishes.filter { !$0.candidates.isEmpty }
        guard !visibleWishes.isEmpty else {
            return []
        }
        if option.option.logic == .all {
            return deduplicatedIDs(visibleWishes.compactMap { $0.candidates.first?.item.id })
        }
        return visibleWishes.first?.candidates.first.map { [$0.item.id] } ?? []
    }

    private static func deduplicatedCandidates(_ candidates: [MatchRelationCandidate]) -> [MatchRelationCandidate] {
        var seen: Set<UUID> = []
        return candidates.filter { seen.insert($0.item.id).inserted }
    }

    private static func deduplicatedIDs(_ ids: [UUID]) -> [UUID] {
        var seen: Set<UUID> = []
        return ids.filter { seen.insert($0).inserted }
    }
}

struct MatchRelationScreen: View {
    @ObservedObject var appState: MegrumAppState
    var targetItem: GoodsItem
    var matchType: ProposalMatchType = .perfect
    var onCompletionAction: (ProposalCompletionAction) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss
    @State private var currentTargetItem: GoodsItem
    @State private var selectedCandidateIDsByListingID: [UUID: Set<UUID>] = [:]
    @State private var selectedHaveIDsByListingID: [UUID: Set<UUID>] = [:]
    @State private var popupTarget: MatchRelationWishPopupTarget?
    @State private var proposalTarget: MatchRelationProposalTarget?
    @State private var relationSwipeOffset: CGFloat = 0
    @State private var didApplyVisualQACandidateExpansion = false
    private let visualQAInitialScreen: VisualQAInitialScreen?

    init(
        appState: MegrumAppState,
        targetItem: GoodsItem,
        matchType: ProposalMatchType = .perfect,
        visualQAInitialScreen: VisualQAInitialScreen? = nil,
        onCompletionAction: @escaping (ProposalCompletionAction) -> Void = { _ in }
    ) {
        self._appState = ObservedObject(wrappedValue: appState)
        self.targetItem = targetItem
        self.matchType = matchType
        self.onCompletionAction = onCompletionAction
        self.visualQAInitialScreen = visualQAInitialScreen ?? VisualQAPreviewMode.initialScreen(
            environment: ProcessInfo.processInfo.environment
        )
        _currentTargetItem = State(initialValue: targetItem)
    }

    private var partnerProfile: PublicUserProfile? {
        appState.publicProfilesByUserID[currentTargetItem.ownerID]
    }

    private var partnerHandle: String {
        partnerProfile?.profile.handle ?? "相手"
    }

    private var partnerGoods: [GoodsItem] {
        let loaded = appState.publicTradeGoodsByUserID[currentTargetItem.ownerID] ?? []
        let visualQAFallback: [GoodsItem]
        if visualQAInitialScreen == .matchRelation || visualQAInitialScreen == .matchRelationCandidates {
            visualQAFallback = NativePreviewData.inventory.filter { item in
                item.ownerID == currentTargetItem.ownerID
            }
        } else {
            visualQAFallback = []
        }
        return MatchRelationComposer.deduplicatedGoods([currentTargetItem] + loaded + visualQAFallback)
    }

    private var senderGoods: [GoodsItem] {
        MatchRelationComposer.selectableSenderGoods(from: appState.inventory)
    }

    private var partnerListings: [IndividualListing] {
        (appState.publicListingsByUserID[currentTargetItem.ownerID] ?? [])
            .filter { $0.status == .active }
    }

    private var ownListings: [IndividualListing] {
        appState.listings.filter { $0.status == .active }
    }

    private var relationDetails: [MatchRelationListingDetail] {
        MatchRelationComposer.buildRelationDetails(
            ownListings: ownListings,
            partnerListings: partnerListings,
            senderGoods: senderGoods,
            partnerGoods: partnerGoods,
            highlightedItemID: currentTargetItem.id
        )
    }

    private var aggregate: MatchRelationAggregate {
        MatchRelationComposer.aggregateSelection(
            details: relationDetails,
            selectedCandidateIDsByListingID: selectedCandidateIDsByListingID,
            selectedHaveIDsByListingID: selectedHaveIDsByListingID
        )
    }

    private var simpleReceiverIDs: [UUID] {
        [currentTargetItem.id]
    }

    private var simpleSenderIDs: [UUID] {
        MatchRelationComposer.fallbackSenderIDs(for: currentTargetItem, inventory: senderGoods)
    }

    private var isLoading: Bool {
        appState.loadingPublicExchangeUserID == currentTargetItem.ownerID
            || appState.loadingPublicProfileUserID == currentTargetItem.ownerID
            || appState.isLoadingIndividualListings
    }

    private var canStartRelationProposal: Bool {
        !aggregate.isEmpty
    }

    private var canStartSimpleProposal: Bool {
        relationDetails.isEmpty && !simpleSenderIDs.isEmpty && !simpleReceiverIDs.isEmpty
    }

    private var relationSeedKey: String {
        [
            currentTargetItem.id.uuidString,
            senderGoods.map(\.id.uuidString).joined(separator: ","),
            partnerGoods.map(\.id.uuidString).joined(separator: ","),
            relationDetails.map(\.id.uuidString).joined(separator: ",")
        ]
        .joined(separator: "|")
    }

    private var swipeItems: [GoodsItem] {
        MatchRelationComposer.relationSwipeItems(
            homeMatchedItems: appState.homeMatchedItems,
            currentTarget: currentTargetItem
        )
    }

    private var previousSwipeTarget: GoodsItem? {
        MatchRelationComposer.adjacentSwipeTarget(
            in: swipeItems,
            currentID: currentTargetItem.id,
            direction: .previous
        )
    }

    private var nextSwipeTarget: GoodsItem? {
        MatchRelationComposer.adjacentSwipeTarget(
            in: swipeItems,
            currentID: currentTargetItem.id,
            direction: .next
        )
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    if isLoading {
                        MatchRelationLoadingPanel()
                    }

                    if !ownDetails.isEmpty {
                        MatchRelationSectionHeader(title: "あなたの個別募集")
                        relationCards(ownDetails)
                    }

                    if !partnerDetails.isEmpty {
                        MatchRelationSectionHeader(title: "@\(partnerHandle) の個別募集")
                        relationCards(partnerDetails)
                    }

                    if relationDetails.isEmpty, !isLoading {
                        MatchRelationSimplePanel(
                            targetItem: currentTargetItem,
                            senderItems: simpleSenderIDs.compactMap { id in senderGoods.first { $0.id == id } }
                        )
                    }

                    if canStartRelationProposal {
                    MatchRelationSummaryPanel(
                        senderItems: aggregate.senderItems,
                        receiverItems: aggregate.receiverItems
                    )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 112)
                .offset(x: relationSwipeOffset)
            }
            .contentShape(Rectangle())
            .simultaneousGesture(relationSwipeGesture(screenWidth: geometry.size.width))
        }
        .background(MatchRelationVisual.background.ignoresSafeArea())
        .megrumHiddenNavigationBar()
        .safeAreaInset(edge: .top, spacing: 0) {
            MatchRelationHeader(
                onClose: { dismiss() }
            )
        }
        .safeAreaInset(edge: .bottom) {
            MatchRelationBottomBar(
                senderCount: currentSenderCount,
                receiverCount: currentReceiverCount,
                isEnabled: canStartRelationProposal || canStartSimpleProposal,
                showsReset: canStartRelationProposal,
                onSecondary: {
                    if canStartRelationProposal {
                        resetRelationSelection()
                    } else {
                        dismiss()
                    }
                },
                onStart: startProposal
            )
        }
        .task(id: currentTargetItem.ownerID) {
            await appState.loadPublicUserProfile(userID: currentTargetItem.ownerID)
            await appState.loadPublicExchangeContent(userID: currentTargetItem.ownerID)
            await appState.loadIndividualListings()
            seedInitialSelection(force: true)
        }
        .task(id: relationSeedKey) {
            seedInitialSelection(force: true)
        }
        .onChange(of: currentTargetItem.id) { _, _ in
            proposalTarget = nil
            popupTarget = nil
            didApplyVisualQACandidateExpansion = false
            seedInitialSelection(force: true)
        }
        .overlay {
            if let target = popupTarget {
                MatchRelationWishBottomSheet(
                    target: target,
                    partnerHandle: partnerHandle,
                    highlightedItemID: currentTargetItem.id,
                    selectedCandidateIDs: selectedCandidateIDsByListingID[target.listingID] ?? [],
                    onToggleCandidate: { candidateID in
                        toggleCandidate(listingID: target.listingID, candidateID: candidateID)
                    },
                    onClose: {
                        popupTarget = nil
                    }
                )
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .zIndex(4)
            }
        }
        .relationProposalPresentation(item: $proposalTarget) { target in
            NavigationStack {
                ProposalCreateFlow(
                    appState: appState,
                    targetItem: target.targetItem,
                    listingID: target.listingID,
                    receiverGoodsIDs: target.receiverGoodsIDs,
                    initialSenderGoodsIDs: target.senderGoodsIDs,
                    matchType: target.matchType,
                    initialStep: .meetup,
                    onCompletionAction: { action in
                        proposalTarget = nil
                        dismiss()
                        onCompletionAction(action)
                    }
                )
            }
        }
    }

    private var ownDetails: [MatchRelationListingDetail] {
        relationDetails.filter(\.isMyListing)
    }

    private var partnerDetails: [MatchRelationListingDetail] {
        relationDetails.filter { !$0.isMyListing }
    }

    private var currentSenderCount: Int {
        canStartRelationProposal ? aggregate.senderIDs.count : simpleSenderIDs.count
    }

    private var currentReceiverCount: Int {
        canStartRelationProposal ? aggregate.receiverIDs.count : simpleReceiverIDs.count
    }

    @ViewBuilder
    private func relationCards(_ details: [MatchRelationListingDetail]) -> some View {
        VStack(spacing: 14) {
            ForEach(Array(details.enumerated()), id: \.element.id) { index, detail in
                MatchRelationTreeCard(
                    detail: detail,
                    index: index,
                    partnerHandle: partnerHandle,
                    highlightedItemID: currentTargetItem.id,
                    selectedCandidateIDs: selectedCandidateIDsByListingID[detail.id] ?? [],
                    selectedHaveIDs: selectedHaveIDsByListingID[detail.id] ?? [],
                    onToggleHave: { haveID in
                        toggleHave(listingID: detail.id, haveID: haveID)
                    },
                    onOpenPopup: { target in
                        popupTarget = target
                    }
                )
            }
        }
    }

    private func seedInitialSelection(force: Bool) {
        let details = relationDetails
        guard force || selectedCandidateIDsByListingID.isEmpty else {
            return
        }
        selectedCandidateIDsByListingID = MatchRelationComposer.initialCandidateSelection(
            for: details,
            highlightedItemID: currentTargetItem.id
        )
        selectedHaveIDsByListingID = MatchRelationComposer.initialHaveSelection(
            for: details,
            highlightedItemID: currentTargetItem.id
        )
        applyVisualQACandidateExpansionIfNeeded(details: details)
    }

    private func applyVisualQACandidateExpansionIfNeeded(details: [MatchRelationListingDetail]) {
        guard visualQAInitialScreen == .matchRelationCandidates,
              !didApplyVisualQACandidateExpansion,
              let target = MatchRelationComposer.defaultPopupTarget(
                for: details,
                highlightedItemID: currentTargetItem.id
              )
        else {
            return
        }
        didApplyVisualQACandidateExpansion = true
        popupTarget = target
    }

    private func resetRelationSelection() {
        selectedCandidateIDsByListingID = [:]
        popupTarget = nil
    }

    private func toggleCandidate(listingID: UUID, candidateID: UUID) {
        var ids = selectedCandidateIDsByListingID[listingID] ?? []
        if ids.contains(candidateID) {
            ids.remove(candidateID)
        } else {
            ids.insert(candidateID)
        }
        if ids.isEmpty {
            selectedCandidateIDsByListingID.removeValue(forKey: listingID)
        } else {
            selectedCandidateIDsByListingID[listingID] = ids
        }
    }

    private func toggleHave(listingID: UUID, haveID: UUID) {
        var ids = selectedHaveIDsByListingID[listingID] ?? []
        if ids.contains(haveID) {
            ids.remove(haveID)
        } else {
            ids.insert(haveID)
        }
        selectedHaveIDsByListingID[listingID] = ids
    }

    private func startProposal() {
        if canStartRelationProposal {
            let listingID = aggregate.referencedListingIDs.count == 1 ? aggregate.referencedListingIDs.first : nil
            let target = aggregate.receiverItems.first ?? currentTargetItem
            proposalTarget = MatchRelationProposalTarget(
                targetItem: target,
                listingID: listingID,
                receiverGoodsIDs: aggregate.receiverIDs,
                senderGoodsIDs: aggregate.senderIDs,
                matchType: matchType
            )
            return
        }

        guard canStartSimpleProposal else {
            return
        }
        proposalTarget = MatchRelationProposalTarget(
            targetItem: currentTargetItem,
            listingID: nil,
            receiverGoodsIDs: simpleReceiverIDs,
            senderGoodsIDs: simpleSenderIDs,
            matchType: matchType
        )
    }

    private func relationSwipeGesture(screenWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard let direction = MatchRelationSwipeResolver.direction(for: value.translation) else {
                    return
                }
                let hasTarget = direction == .next ? nextSwipeTarget != nil : previousSwipeTarget != nil
                guard let offset = MatchRelationSwipeResolver.presentationOffset(
                    translation: value.translation,
                    screenWidth: screenWidth,
                    hasAdjacentTarget: hasTarget
                ) else {
                    return
                }
                relationSwipeOffset = offset
            }
            .onEnded { value in
                guard let direction = MatchRelationSwipeResolver.direction(for: value.translation) else {
                    withAnimation(.snappy) {
                        relationSwipeOffset = 0
                    }
                    return
                }

                let target = direction == .next ? nextSwipeTarget : previousSwipeTarget
                let shouldSwitch = MatchRelationSwipeResolver.shouldSwitchTarget(
                    translation: value.translation,
                    predictedEndTranslationWidth: value.predictedEndTranslation.width,
                    screenWidth: screenWidth,
                    hasAdjacentTarget: target != nil
                )

                if let target, shouldSwitch {
                    withAnimation(.snappy) {
                        currentTargetItem = target
                        relationSwipeOffset = 0
                    }
                } else {
                    withAnimation(.snappy) {
                        relationSwipeOffset = 0
                    }
                }
            }
    }
}

private extension View {
    @ViewBuilder
    func relationProposalPresentation<Content: View>(
        item: Binding<MatchRelationProposalTarget?>,
        @ViewBuilder content: @escaping (MatchRelationProposalTarget) -> Content
    ) -> some View {
        #if os(iOS)
        fullScreenCover(item: item, content: content)
        #else
        sheet(item: item, content: content)
        #endif
    }
}

private struct MatchRelationLoadingPanel: View {
    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
                .controlSize(.small)
                .tint(MegrumTheme.lavender)
            Text("在庫と個別募集を確認しています")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct MatchRelationSectionHeader: View {
    var title: String

    var body: some View {
        Text(title)
            .font(.system(size: 22, weight: .heavy, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MatchRelationTreeCard: View {
    var detail: MatchRelationListingDetail
    var index: Int
    var partnerHandle: String
    var highlightedItemID: UUID
    var selectedCandidateIDs: Set<UUID>
    var selectedHaveIDs: Set<UUID>
    var onToggleHave: (UUID) -> Void
    var onOpenPopup: (MatchRelationWishPopupTarget) -> Void

    private var cashOption: IndividualListingWishOption? {
        detail.listing.options.first(where: \.isCashOffer)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("個別募集\(index + 1)")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Text("選択肢 \(detail.selectableOptionCount) 件")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                Spacer()
                if let cashOption {
                    Text(cashText(cashOption))
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                        .padding(.horizontal, 10)
                        .frame(height: 28)
                        .background(MegrumTheme.lavender.opacity(0.12), in: Capsule())
                }
            }

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 10) {
                    MatchRelationOwnerLabel(
                        title: detail.isMyListing ? "@\(partnerHandle) が譲る候補" : "@\(partnerHandle) が譲るもの",
                        color: MegrumTheme.pink
                    )
                    if detail.isMyListing {
                        MatchRelationOptionList(
                            detail: detail,
                            viewpoint: .mine,
                            partnerHandle: partnerHandle,
                            highlightedItemID: highlightedItemID,
                            selectedCandidateIDs: selectedCandidateIDs,
                            onOpenPopup: onOpenPopup
                        )
                    } else {
                        MatchRelationHaveList(
                            detail: detail,
                            highlightedItemID: highlightedItemID,
                            selectedHaveIDs: selectedHaveIDs,
                            onToggleHave: onToggleHave
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)

                VStack(alignment: .leading, spacing: 10) {
                    MatchRelationOwnerLabel(
                        title: detail.isMyListing ? "あなたが譲るもの" : "あなたが譲れる候補",
                        color: MegrumTheme.lavender
                    )
                    if detail.isMyListing {
                        MatchRelationHaveList(
                            detail: detail,
                            highlightedItemID: highlightedItemID,
                            selectedHaveIDs: selectedHaveIDs,
                            onToggleHave: onToggleHave
                        )
                    } else {
                        MatchRelationOptionList(
                            detail: detail,
                            viewpoint: .partner,
                            partnerHandle: partnerHandle,
                            highlightedItemID: highlightedItemID,
                            selectedCandidateIDs: selectedCandidateIDs,
                            onOpenPopup: onOpenPopup
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: MegrumTheme.ink.opacity(0.04), radius: 8, y: 2)
    }

    private func cashText(_ option: IndividualListingWishOption) -> String {
        option.cashAmount.map { "定価 \(NumberFormatter.localizedString(from: NSNumber(value: $0), number: .decimal))円" } ?? "定価も可"
    }
}

private struct MatchRelationOwnerLabel: View {
    var title: String
    var color: Color

    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .heavy, design: .rounded))
            .foregroundStyle(color)
            .lineLimit(2)
    }
}

private struct MatchRelationOptionList: View {
    var detail: MatchRelationListingDetail
    var viewpoint: MatchRelationViewpoint
    var partnerHandle: String
    var highlightedItemID: UUID
    var selectedCandidateIDs: Set<UUID>
    var onOpenPopup: (MatchRelationWishPopupTarget) -> Void

    private var visibleOptions: [MatchRelationOption] {
        detail.options
            .filter { !$0.option.isCashOffer }
            .filter { option in option.wishes.contains { !$0.candidates.isEmpty } }
            .sorted { lhs, rhs in
                if lhs.matched != rhs.matched {
                    return lhs.matched && !rhs.matched
                }
                return lhs.option.position < rhs.option.position
            }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if visibleOptions.isEmpty {
                Text("候補なし")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .padding(.vertical, 14)
            } else {
                ForEach(visibleOptions) { option in
                    MatchRelationOptionGroup(
                        listingID: detail.id,
                        viewpoint: viewpoint,
                        partnerHandle: partnerHandle,
                        option: option,
                        fallbackHave: MatchRelationComposer.defaultFallbackHave(
                            for: detail,
                            highlightedItemID: highlightedItemID
                        ),
                        highlightedItemID: highlightedItemID,
                        selectedCandidateIDs: selectedCandidateIDs,
                        onOpenPopup: onOpenPopup
                    )
                }
            }
        }
    }
}

private struct MatchRelationOptionGroup: View {
    var listingID: UUID
    var viewpoint: MatchRelationViewpoint
    var partnerHandle: String
    var option: MatchRelationOption
    var fallbackHave: MatchRelationHave?
    var highlightedItemID: UUID
    var selectedCandidateIDs: Set<UUID>
    var onOpenPopup: (MatchRelationWishPopupTarget) -> Void

    private var visibleWishes: [MatchRelationWish] {
        option.wishes.filter { !$0.candidates.isEmpty }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Text("#\(option.option.position)")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundStyle(option.option.logic == .all ? .white : MegrumTheme.lavender)
                    .padding(.horizontal, 6)
                    .frame(height: 18)
                    .background(option.option.logic == .all ? MegrumTheme.lavender : .white, in: Capsule())
                    .overlay {
                        if option.option.logic != .all {
                            Capsule()
                                .strokeBorder(MegrumTheme.lavender.opacity(0.34), lineWidth: 1)
                        }
                    }
                Text(option.option.logic == .all ? "セット（AND）" : "いずれか（OR）")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .lineLimit(1)
            }

            if fallbackHave != nil {
                ForEach(visibleWishes) { wish in
                    MatchRelationWishRow(
                        wish: wish,
                        exchangeType: option.option.exchangeType,
                        highlightedItemID: highlightedItemID,
                        selectedCandidateIDs: selectedCandidateIDs,
                        candidateOwnerTitle: MatchRelationPopupCopy.candidateOwnerTitle(
                            viewpoint: viewpoint,
                            partnerHandle: partnerHandle
                        ),
                        onOpen: {
                            if let fallbackHave {
                                onOpenPopup(
                                    MatchRelationComposer.popupTarget(
                                        listingID: listingID,
                                        viewpoint: viewpoint,
                                        option: option,
                                        wish: wish,
                                        fallbackHave: fallbackHave
                                    )
                                )
                            }
                        }
                    )
                }
            }
        }
        .padding(6)
        .background(
            (option.option.logic == .all ? MegrumTheme.lavender.opacity(0.03) : MegrumTheme.lavender.opacity(0.02)),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    option.option.logic == .all ? MegrumTheme.lavender : MegrumTheme.lavender.opacity(0.34),
                    style: StrokeStyle(lineWidth: option.option.logic == .all ? 2 : 1, dash: option.option.logic == .all ? [] : [5, 4])
                )
        }
    }
}

private struct MatchRelationWishRow: View {
    var wish: MatchRelationWish
    var exchangeType: IndividualListingExchangeType
    var highlightedItemID: UUID
    var selectedCandidateIDs: Set<UUID>
    var candidateOwnerTitle: String
    var onOpen: () -> Void

    private var selectedCandidates: [MatchRelationCandidate] {
        MatchRelationComposer.selectedCandidates(
            for: wish,
            selectedCandidateIDs: selectedCandidateIDs
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onOpen) {
                HStack(spacing: 9) {
                    MatchRelationGoodsThumbnail(item: wish.item, size: 38)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 3) {
                            Text("🎯")
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                            Text(wish.item.title)
                                .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                                .foregroundStyle(MegrumTheme.ink)
                                .lineLimit(1)
                        }
                        Text("\(exchangeType.displayName) / 候補 \(wish.candidates.count) 件")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                    }
                    Spacer(minLength: 0)
                    Text("×\(wish.quantity)")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(MegrumTheme.lavender)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if !selectedCandidates.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("選択中")
                        .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                    HStack(spacing: -8) {
                        ForEach(selectedCandidates) { candidate in
                            MatchRelationGoodsThumbnail(item: candidate.item, size: 34)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(
                                            candidate.item.id == highlightedItemID ? MegrumTheme.pink.opacity(0.9) : .white,
                                            lineWidth: 1.5
                                        )
                                }
                        }
                    }
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 7)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(MegrumTheme.ink.opacity(0.04))
                        .frame(height: 1)
                }
            }
        }
        .accessibilityHint("\(candidateOwnerTitle)をシートで開き、候補グッズをタップして選択します")
        .background(MatchRelationVisual.background, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(MegrumTheme.ink.opacity(0.04), lineWidth: 1)
        }
    }
}

private struct MatchRelationWishBottomSheet: View {
    var target: MatchRelationWishPopupTarget
    var partnerHandle: String
    var highlightedItemID: UUID
    var selectedCandidateIDs: Set<UUID>
    var onToggleCandidate: (UUID) -> Void
    var onClose: () -> Void

    private var candidateAccent: Color {
        target.viewpoint == .mine ? MegrumTheme.pink : MegrumTheme.lavender
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.56)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center, spacing: 8) {
                    Text("🎯")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(target.wish.item.title)
                            .font(.system(size: 12.5, weight: .heavy, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink)
                            .lineLimit(1)
                        Text(MatchRelationPopupCopy.subtitle(
                            quantity: target.wish.quantity,
                            candidateCount: target.wish.candidates.count
                        ))
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                    }
                    Spacer(minLength: 0)
                    Button(action: onClose) {
                        Text("×")
                            .font(.system(size: 17, weight: .heavy, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                            .frame(width: 28, height: 28)
                            .background(MegrumTheme.ink.opacity(0.04), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(MatchRelationVisual.background)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(MegrumTheme.ink.opacity(0.04))
                        .frame(height: 1)
                }

                HStack(alignment: .top, spacing: 14) {
                    VStack(alignment: .center, spacing: 0) {
                        MatchRelationGoodsThumbnail(item: target.wish.item, size: 104)
                        Text(target.exchangeType.displayName)
                            .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(MegrumTheme.lavender, in: Capsule())
                            .padding(.top, 7)
                        Text(MatchRelationPopupCopy.fallbackTitle(target.fallbackHave.item.title))
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                            .padding(.top, 5)
                    }
                    .frame(width: 110, alignment: .top)

                    VStack(alignment: .leading, spacing: 9) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            MatchRelationMiniAvatar(
                                title: target.viewpoint == .mine ? "@\(partnerHandle)" : "あなた",
                                color: candidateAccent
                            )
                            Text(MatchRelationPopupCopy.candidateOwnerTitle(
                                viewpoint: target.viewpoint,
                                partnerHandle: partnerHandle
                            ))
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .foregroundStyle(candidateAccent)
                                .lineLimit(1)
                            Text("（タップで選択）")
                                .font(.system(size: 9.5, weight: .bold, design: .rounded))
                                .foregroundStyle(MegrumTheme.muted)
                        }

                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3),
                            alignment: .leading,
                            spacing: 6
                        ) {
                            ForEach(target.wish.candidates) { candidate in
                                MatchRelationPopupCandidateButton(
                                    candidate: candidate,
                                    isSelected: selectedCandidateIDs.contains(candidate.item.id),
                                    isHighlighted: candidate.item.id == highlightedItemID,
                                    onTap: {
                                        onToggleCandidate(candidate.item.id)
                                    }
                                )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .padding(12)

                Button(action: onClose) {
                    Text("戻る")
                        .font(.system(size: 12.5, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(MegrumTheme.lavender, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.top, 2)
                .padding(.bottom, 22)
            }
            .frame(maxWidth: .infinity)
            .background(.white, in: UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20))
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20))
            .shadow(color: .black.opacity(0.25), radius: 40, y: -10)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

private struct MatchRelationMiniAvatar: View {
    var title: String
    var color: Color

    var body: some View {
        Text(title.prefix(1).uppercased())
            .font(.system(size: 8, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: 16, height: 16)
            .background(color, in: Circle())
    }
}

private struct MatchRelationPopupCandidateButton: View {
    var candidate: MatchRelationCandidate
    var isSelected: Bool
    var isHighlighted: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topLeading) {
                VStack(alignment: .center, spacing: 0) {
                    MatchRelationGoodsThumbnail(item: candidate.item, size: 56)

                    Text(candidate.item.title)
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineLimit(1)
                        .frame(maxWidth: 64)
                        .padding(.top, 3)
                }
                .frame(maxWidth: .infinity, alignment: .center)

                if isHighlighted {
                    Text("選択元")
                        .font(.system(size: 8.5, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(MegrumTheme.pink, in: Capsule())
                        .offset(x: -8, y: -8)
                }

                if isSelected {
                    Text("✓")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 16, height: 16)
                        .background(MegrumTheme.lavender, in: Circle())
                        .frame(maxWidth: .infinity, alignment: .topTrailing)
                        .offset(x: 8, y: -8)
                }
            }
            .padding(4)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 82, alignment: .top)
            .background(
                isHighlighted
                    ? Color(red: 1, green: 247 / 255, blue: 251 / 255)
                    : (isSelected ? MegrumTheme.lavender.opacity(0.08) : .white),
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(
                        isHighlighted ? MegrumTheme.pink : (isSelected ? MegrumTheme.lavender : .clear),
                        lineWidth: isHighlighted || isSelected ? 2 : 0
                    )
            }
        }
        .buttonStyle(.plain)
    }
}

private struct MatchRelationHaveList: View {
    var detail: MatchRelationListingDetail
    var highlightedItemID: UUID
    var selectedHaveIDs: Set<UUID>
    var onToggleHave: (UUID) -> Void

    private var isInteractive: Bool {
        detail.listing.haveLogic == .one && detail.haves.count >= 2
    }

    private var visibleHaves: [MatchRelationHave] {
        let matched = detail.haves.filter { $0.matched || $0.item.id == highlightedItemID }
        return matched.isEmpty ? detail.haves : matched
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            MatchRelationFlowLayout(spacing: 8, rowSpacing: 8) {
                ForEach(visibleHaves) { have in
                    if isInteractive {
                        MatchRelationHaveButton(
                            have: have,
                            isSelected: selectedHaveIDs.contains(have.item.id),
                            isHighlighted: have.item.id == highlightedItemID,
                            onTap: {
                                onToggleHave(have.item.id)
                            }
                        )
                    } else {
                        MatchRelationHaveChip(
                            have: have,
                            isHighlighted: have.item.id == highlightedItemID
                        )
                    }
                }
            }

            if detail.haves.count > 1 {
                Text(detail.listing.haveLogic == .all ? "全部まとめて" : "どれかを選択")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            }
        }
    }
}

private struct MatchRelationHaveButton: View {
    var have: MatchRelationHave
    var isSelected: Bool
    var isHighlighted: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            MatchRelationHaveContent(
                have: have,
                isSelected: isSelected,
                isHighlighted: isHighlighted
            )
        }
        .buttonStyle(.plain)
    }
}

private struct MatchRelationHaveChip: View {
    var have: MatchRelationHave
    var isHighlighted: Bool

    var body: some View {
        MatchRelationHaveContent(
            have: have,
            isSelected: true,
            isHighlighted: isHighlighted
        )
    }
}

private struct MatchRelationHaveContent: View {
    var have: MatchRelationHave
    var isSelected: Bool
    var isHighlighted: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            MatchRelationGoodsThumbnail(item: have.item, size: 54)
                .overlay(alignment: .topTrailing) {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundStyle(MegrumTheme.ok)
                            .background(.white, in: Circle())
                            .offset(x: 4, y: -4)
                    }
                }
            Text(have.item.title)
                .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .lineLimit(2)
            if have.quantity > 1 {
                Text("×\(have.quantity)")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? MegrumTheme.lavender.opacity(0.12) : .white.opacity(0.62), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(isHighlighted ? MegrumTheme.pink.opacity(0.86) : .white.opacity(0.5), lineWidth: 1.2)
        }
    }
}

private struct MatchRelationSummaryPanel: View {
    var senderItems: [GoodsItem]
    var receiverItems: [GoodsItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("📋 結論：この交換")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(0.4)
                .foregroundStyle(MegrumTheme.lavender)
            HStack(spacing: 8) {
                MatchRelationSummarySide(title: "あなたが受", color: MegrumTheme.pink, items: receiverItems)
                Text("⇄")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                MatchRelationSummarySide(title: "あなたが譲", color: MegrumTheme.lavender, items: senderItems)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(MegrumTheme.lavender.opacity(0.04), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(MegrumTheme.lavender.opacity(0.34), lineWidth: 1)
        }
    }
}

private struct MatchRelationSummarySide: View {
    var title: String
    var color: Color
    var items: [GoodsItem]

    var body: some View {
        HStack(spacing: 5) {
            Text(title)
                .font(.system(size: 8.5, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .frame(height: 18)
                .background(color, in: Capsule())
            HStack(spacing: -8) {
                ForEach(items.prefix(4)) { item in
                    MatchRelationGoodsThumbnail(item: item, size: 28)
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(.white, lineWidth: 1.5)
                        }
                }
                if items.count > 4 {
                    Text("+\(items.count - 4)")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .padding(.horizontal, 8)
                        .frame(height: 24)
                        .background(.white.opacity(0.82), in: Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MatchRelationSimplePanel: View {
    var targetItem: GoodsItem
    var senderItems: [GoodsItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("譲る候補とWishのマッチ")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
            HStack(spacing: 12) {
                MatchRelationSummarySide(title: "あなたが譲", color: MegrumTheme.lavender, items: senderItems)
                Text("⇄")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                MatchRelationSummarySide(title: "あなたが受", color: MegrumTheme.pink, items: [targetItem])
            }
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
        }
    }
}

private struct MatchRelationFlowLayout<Content: View>: View {
    var spacing: CGFloat = 8
    var rowSpacing: CGFloat = 8
    var content: Content

    init(spacing: CGFloat = 8, rowSpacing: CGFloat = 8, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.rowSpacing = rowSpacing
        self.content = content()
    }

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 86), spacing: spacing)],
            alignment: .leading,
            spacing: rowSpacing
        ) {
            content
        }
    }
}

private struct MatchRelationGoodsThumbnail: View {
    var item: GoodsItem
    var size: CGFloat?

    var body: some View {
        Group {
            if let imageURL = item.imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .empty:
                        ProgressView()
                            .tint(MegrumTheme.lavender)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case .failure:
                        fallback
                    @unknown default:
                        fallback
                    }
                }
            } else {
                fallback
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .background(MegrumTheme.lavender.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var fallback: some View {
        ZStack {
            LinearGradient(
                colors: [MegrumTheme.lavender.opacity(0.72), MegrumTheme.pink.opacity(0.48)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Text(String(item.title.prefix(1)))
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
        }
    }
}

private struct MatchRelationBottomBar: View {
    var senderCount: Int
    var receiverCount: Int
    var isEnabled: Bool
    var showsReset: Bool
    var onSecondary: () -> Void
    var onStart: () -> Void

    var body: some View {
        let totalSelectionCount = max(senderCount, receiverCount)
        HStack(spacing: 10) {
            Button(action: onSecondary) {
                Text(MatchRelationBottomBarCopy.secondaryTitle(showsReset: showsReset))
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .frame(width: 92)
                    .frame(height: 54)
                    .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(MegrumTheme.ink.opacity(0.10), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)

            Button(action: onStart) {
                Text(
                    MatchRelationBottomBarCopy.primaryTitle(
                        isEnabled: isEnabled,
                        showsReset: showsReset,
                        totalSelectionCount: totalSelectionCount
                    )
                )
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(MegrumTheme.lavender.opacity(isEnabled ? 1 : 0.42), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: MegrumTheme.lavender.opacity(isEnabled ? 0.24 : 0), radius: 14, y: 8)
            }
            .buttonStyle(.plain)
            .disabled(!isEnabled)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(.white)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(MegrumTheme.ink.opacity(0.08))
                .frame(height: 1)
        }
        .shadow(color: MegrumTheme.ink.opacity(0.08), radius: 12, y: -4)
    }
}

private struct MatchRelationHeader: View {
    var onClose: () -> Void

    var body: some View {
        HStack(spacing: 18) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(MegrumTheme.muted)
                    .frame(width: 56, height: 56)
                    .background(.white, in: Circle())
                    .overlay {
                        Circle()
                            .strokeBorder(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)

            Text("関係図")
                .font(.system(size: 27, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 14)
        .background(.white)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(MegrumTheme.ink.opacity(0.06))
                .frame(height: 1)
        }
    }
}

private enum MatchRelationVisual {
    static let background = Color(red: 0.984, green: 0.976, blue: 0.988)
}
