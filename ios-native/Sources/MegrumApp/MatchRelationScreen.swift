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
        let havesByID = Dictionary(uniqueKeysWithValues: havesSource.map { ($0.id, $0) })
        let candidatesByID = Dictionary(uniqueKeysWithValues: candidateSource.map { ($0.id, $0) })
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

        let goodsByID = Dictionary(uniqueKeysWithValues: (havesSource + candidateSource).map { ($0.id, $0) })
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
    @State private var selectedCandidateIDsByListingID: [UUID: Set<UUID>] = [:]
    @State private var selectedHaveIDsByListingID: [UUID: Set<UUID>] = [:]
    @State private var proposalTarget: MatchRelationProposalTarget?

    private var partnerProfile: PublicUserProfile? {
        appState.publicProfilesByUserID[targetItem.ownerID]
    }

    private var partnerHandle: String {
        partnerProfile?.profile.handle ?? "相手"
    }

    private var partnerGoods: [GoodsItem] {
        let loaded = appState.publicTradeGoodsByUserID[targetItem.ownerID] ?? []
        return MatchRelationComposer.deduplicatedGoods([targetItem] + loaded)
    }

    private var senderGoods: [GoodsItem] {
        MatchRelationComposer.selectableSenderGoods(from: appState.inventory)
    }

    private var partnerListings: [IndividualListing] {
        (appState.publicListingsByUserID[targetItem.ownerID] ?? [])
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
            highlightedItemID: targetItem.id
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
        [targetItem.id]
    }

    private var simpleSenderIDs: [UUID] {
        MatchRelationComposer.fallbackSenderIDs(for: targetItem, inventory: senderGoods)
    }

    private var isLoading: Bool {
        appState.loadingPublicExchangeUserID == targetItem.ownerID
            || appState.loadingPublicProfileUserID == targetItem.ownerID
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
            targetItem.id.uuidString,
            senderGoods.map(\.id.uuidString).joined(separator: ","),
            partnerGoods.map(\.id.uuidString).joined(separator: ","),
            relationDetails.map(\.id.uuidString).joined(separator: ",")
        ]
        .joined(separator: "|")
    }

    var body: some View {
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
                        targetItem: targetItem,
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
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .navigationTitle("関係図")
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            MatchRelationBottomBar(
                senderCount: currentSenderCount,
                receiverCount: currentReceiverCount,
                isEnabled: canStartRelationProposal || canStartSimpleProposal,
                showsReset: canStartRelationProposal,
                onReset: resetRelationSelection,
                onStart: startProposal
            )
        }
        .task(id: targetItem.ownerID) {
            await appState.loadPublicUserProfile(userID: targetItem.ownerID)
            await appState.loadPublicExchangeContent(userID: targetItem.ownerID)
            await appState.loadIndividualListings()
            seedInitialSelection(force: true)
        }
        .task(id: relationSeedKey) {
            seedInitialSelection(force: true)
        }
        .sheet(item: $proposalTarget) { target in
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
                    highlightedItemID: targetItem.id,
                    selectedCandidateIDs: selectedCandidateIDsByListingID[detail.id] ?? [],
                    selectedHaveIDs: selectedHaveIDsByListingID[detail.id] ?? [],
                    onToggleCandidate: { candidateID in
                        toggleCandidate(listingID: detail.id, candidateID: candidateID)
                    },
                    onToggleHave: { haveID in
                        toggleHave(listingID: detail.id, haveID: haveID)
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
            highlightedItemID: targetItem.id
        )
        selectedHaveIDsByListingID = MatchRelationComposer.initialHaveSelection(
            for: details,
            highlightedItemID: targetItem.id
        )
    }

    private func resetRelationSelection() {
        selectedCandidateIDsByListingID = [:]
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
            let target = aggregate.receiverItems.first ?? targetItem
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
            targetItem: targetItem,
            listingID: nil,
            receiverGoodsIDs: simpleReceiverIDs,
            senderGoodsIDs: simpleSenderIDs,
            matchType: matchType
        )
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
    var onToggleCandidate: (UUID) -> Void
    var onToggleHave: (UUID) -> Void

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
                            highlightedItemID: highlightedItemID,
                            selectedCandidateIDs: selectedCandidateIDs,
                            onToggleCandidate: onToggleCandidate
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
                            highlightedItemID: highlightedItemID,
                            selectedCandidateIDs: selectedCandidateIDs,
                            onToggleCandidate: onToggleCandidate
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.62), lineWidth: 1)
        }
        .shadow(color: MegrumTheme.ink.opacity(0.08), radius: 18, y: 10)
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
    var highlightedItemID: UUID
    var selectedCandidateIDs: Set<UUID>
    var onToggleCandidate: (UUID) -> Void

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
                        option: option,
                        highlightedItemID: highlightedItemID,
                        selectedCandidateIDs: selectedCandidateIDs,
                        onToggleCandidate: onToggleCandidate
                    )
                }
            }
        }
    }
}

private struct MatchRelationOptionGroup: View {
    var option: MatchRelationOption
    var highlightedItemID: UUID
    var selectedCandidateIDs: Set<UUID>
    var onToggleCandidate: (UUID) -> Void

    private var visibleWishes: [MatchRelationWish] {
        option.wishes.filter { !$0.candidates.isEmpty }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if option.option.wishes.count > 1 {
                Text(option.option.logic == .all ? "すべてほしい" : "どれか1つだけ")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(option.option.logic == .all ? MegrumTheme.ok : MegrumTheme.lavender)
                    .padding(.horizontal, 8)
                    .frame(height: 24)
                    .background(.white.opacity(0.72), in: Capsule())
            }

            ForEach(visibleWishes) { wish in
                MatchRelationWishRow(
                    wish: wish,
                    exchangeType: option.option.exchangeType,
                    highlightedItemID: highlightedItemID,
                    selectedCandidateIDs: selectedCandidateIDs,
                    onToggleCandidate: onToggleCandidate
                )
            }
        }
        .padding(10)
        .background(.white.opacity(0.54), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct MatchRelationWishRow: View {
    var wish: MatchRelationWish
    var exchangeType: IndividualListingExchangeType
    var highlightedItemID: UUID
    var selectedCandidateIDs: Set<UUID>
    var onToggleCandidate: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                MatchRelationGoodsThumbnail(item: wish.item, size: 38)
                VStack(alignment: .leading, spacing: 2) {
                    Text(wish.item.title)
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineLimit(1)
                    Text("\(exchangeType.displayName) / 候補 \(wish.candidates.count) 件")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }
                Spacer(minLength: 0)
                Text("×\(wish.quantity)")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
            }

            MatchRelationFlowLayout(spacing: 7, rowSpacing: 7) {
                ForEach(wish.candidates) { candidate in
                    MatchRelationCandidateButton(
                        item: candidate.item,
                        isSelected: selectedCandidateIDs.contains(candidate.item.id),
                        isHighlighted: candidate.item.id == highlightedItemID
                    ) {
                        onToggleCandidate(candidate.item.id)
                    }
                }
            }
        }
    }
}

private struct MatchRelationCandidateButton: View {
    var item: GoodsItem
    var isSelected: Bool
    var isHighlighted: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                MatchRelationGoodsThumbnail(item: item, size: 28)
                Text(item.title)
                    .lineLimit(1)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                }
            }
            .font(.system(size: 11.5, weight: .heavy, design: .rounded))
            .foregroundStyle(isSelected ? .white : MegrumTheme.ink)
            .padding(.horizontal, 8)
            .frame(height: 36)
            .background(
                isSelected ? AnyShapeStyle(MegrumTheme.lavender) : AnyShapeStyle(.white.opacity(0.78)),
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .strokeBorder(isHighlighted ? MegrumTheme.pink.opacity(0.78) : .clear, lineWidth: 1.4)
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
        VStack(alignment: .leading, spacing: 12) {
            Text("この内容で打診")
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
            HStack(spacing: 12) {
                MatchRelationSummarySide(title: "私が出す", items: senderItems)
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(MegrumTheme.lavender)
                MatchRelationSummarySide(title: "受け取る", items: receiverItems)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.62), lineWidth: 1)
        }
    }
}

private struct MatchRelationSummarySide: View {
    var title: String
    var items: [GoodsItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
            HStack(spacing: -8) {
                ForEach(items.prefix(4)) { item in
                    MatchRelationGoodsThumbnail(item: item, size: 34)
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(.white, lineWidth: 1.5)
                        }
                }
                if items.count > 4 {
                    Text("+\(items.count - 4)")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .padding(.horizontal, 8)
                        .frame(height: 28)
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
                MatchRelationSummarySide(title: "私が出す", items: senderItems)
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(MegrumTheme.lavender)
                MatchRelationSummarySide(title: "受け取る", items: [targetItem])
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.62), lineWidth: 1)
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
    var onReset: () -> Void
    var onStart: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            if showsReset {
                Button(action: onReset) {
                    Text("リセット")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .frame(width: 92)
                        .frame(height: 54)
                        .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            Button(action: onStart) {
                Text(isEnabled ? "打診に進む（\(senderCount) ⇄ \(receiverCount)）" : "候補を読み込んでいます")
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
        .background(.ultraThinMaterial)
    }
}
