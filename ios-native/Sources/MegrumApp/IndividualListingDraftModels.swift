import Foundation
import MegrumCore

struct IndividualListingDraft: Equatable {
    var mode: IndividualListingEditorMode
    var selectedHaveIDs: Set<UUID>
    var haveQuantities: [UUID: Int]
    var haveOfferKind: IndividualListingHaveOfferKind
    var haveCashPricingMode: IndividualListingCashPricingMode
    var haveCashAmount: Int
    var selectedWishIDs: Set<UUID>
    var wishQuantities: [UUID: Int]
    var optionKind: IndividualListingOptionKind
    var conditionGroupID: UUID?
    var conditionMemberIDs: Set<UUID>
    var excludesSelectedConditionMembers: Bool
    var conditionGoodsTypeID: UUID?
    var conditionTagNames: [String]
    var conditionQuantity: Int
    var cashPricingMode: IndividualListingCashPricingMode
    var cashAmount: Int
    var haveLogic: ListingLogic
    var haveMinimumCount: Int
    var wishLogic: ListingLogic
    var wishMinimumCount: Int
    var exchangeType: IndividualListingExchangeType
    var status: IndividualListingStatus
    var note: String
    var handoffMethod: IndividualListingHandoffDraft
    var localPrefecture: String
    var localPlaceMemo: String
    var localSchedule: String
    var shippingFee: IndividualListingShippingFeeDraft
    var shippingDays: IndividualListingShippingDaysDraft
    var acceptsOutsideCondition: Bool
    var includesExchangeConditionSummary: Bool

    init(mode: IndividualListingEditorMode) {
        self.mode = mode
        switch mode {
        case .create(let preselectedWishID):
            self.selectedHaveIDs = []
            self.haveQuantities = [:]
            self.haveOfferKind = .goods
            self.haveCashPricingMode = .listPrice
            self.haveCashAmount = 1_100
            self.selectedWishIDs = preselectedWishID.map { Set([$0]) } ?? []
            self.wishQuantities = preselectedWishID.map { [$0: 1] } ?? [:]
            self.optionKind = .wish
            self.conditionGroupID = nil
            self.conditionMemberIDs = []
            self.excludesSelectedConditionMembers = false
            self.conditionGoodsTypeID = nil
            self.conditionTagNames = []
            self.conditionQuantity = 1
            self.cashPricingMode = .listPrice
            self.cashAmount = 1_100
            self.haveLogic = .all
            self.haveMinimumCount = 1
            self.wishLogic = .one
            self.wishMinimumCount = 1
            self.exchangeType = .any
            self.status = .active
            self.note = ""
            self.handoffMethod = .both
            self.localPrefecture = "東京都"
            self.localPlaceMemo = ""
            self.localSchedule = IndividualListingExchangeSummary.defaultLocalSchedule
            self.shippingFee = .negotiate
            self.shippingDays = .twoToFourDays
            self.acceptsOutsideCondition = true
            self.includesExchangeConditionSummary = true
        case .edit(let listing):
            let primaryOption = listing.options.sorted { $0.position < $1.position }.first
            let extractedHaveCash = IndividualListingHaveCashSummary.extract(from: listing.note)
            let extractedNote = IndividualListingExchangeSummary.extract(from: extractedHaveCash.remainingNote)
            let exchangeSummary = extractedNote.summary ?? IndividualListingExchangeSummary()
            self.selectedHaveIDs = Set(listing.haves.map(\.itemID))
            self.haveQuantities = Dictionary(uniqueKeysWithValues: listing.haves.map { ($0.itemID, boundedQuantity($0.quantity)) })
            self.haveOfferKind = extractedHaveCash.summary == nil ? .goods : .cash
            self.haveCashPricingMode = extractedHaveCash.summary?.pricingMode ?? .listPrice
            self.haveCashAmount = max(1, extractedHaveCash.summary?.amount ?? 1_100)
            self.selectedWishIDs = Set(primaryOption?.wishes.map(\.itemID) ?? [])
            self.wishQuantities = Dictionary(uniqueKeysWithValues: (primaryOption?.wishes ?? []).map { ($0.itemID, boundedQuantity($0.quantity)) })
            if primaryOption?.isCashOffer == true {
                self.optionKind = .cash
            } else if primaryOption?.wishes.isEmpty == true {
                self.optionKind = .condition
            } else {
                self.optionKind = .wish
            }
            self.conditionGroupID = primaryOption?.wishGroupID
            self.conditionMemberIDs = []
            self.excludesSelectedConditionMembers = false
            self.conditionGoodsTypeID = primaryOption?.wishGoodsTypeID
            self.conditionTagNames = []
            self.conditionQuantity = 1
            self.cashPricingMode = primaryOption?.cashAmount == nil ? .listPrice : .specifiedAmount
            self.cashAmount = max(1, primaryOption?.cashAmount ?? 1_100)
            self.haveLogic = listing.haveLogic
            self.haveMinimumCount = listing.haveMinimumCount
            self.wishLogic = primaryOption?.logic ?? .one
            self.wishMinimumCount = primaryOption?.minimumCount ?? 1
            self.exchangeType = primaryOption?.exchangeType ?? .any
            self.status = listing.status
            self.note = extractedNote.remainingNote ?? ""
            self.handoffMethod = exchangeSummary.handoffMethod
            self.localPrefecture = exchangeSummary.localPrefecture
            self.localPlaceMemo = exchangeSummary.localPlaceMemo
            self.localSchedule = exchangeSummary.localSchedule
            self.shippingFee = exchangeSummary.shippingFee
            self.shippingDays = exchangeSummary.shippingDays
            self.acceptsOutsideCondition = exchangeSummary.acceptsOutsideCondition
            self.includesExchangeConditionSummary = true
        }
    }

    var navigationTitle: String {
        mode.isEditing ? "個別募集を編集" : "個別募集を作成"
    }

    var confirmationTitle: String {
        mode.isEditing ? "反映" : "保存"
    }

    mutating func toggleHave(_ id: UUID, maxQuantity: Int = 99) {
        let previousCount = selectedHaveIDs.count
        haveOfferKind = .goods
        if selectedHaveIDs.contains(id) {
            selectedHaveIDs.remove(id)
            haveQuantities.removeValue(forKey: id)
        } else {
            selectedHaveIDs.insert(id)
            haveQuantities[id] = boundedQuantity(haveQuantities[id] ?? 1, maxQuantity: maxQuantity)
        }
        normalizeHaveMinimumCount()
        defaultHaveMinimumLogicIfNeeded(previousCount: previousCount)
    }

    mutating func selectAllHaves(_ items: [GoodsItem]) {
        guard !items.isEmpty else {
            return
        }
        let previousCount = selectedHaveIDs.count
        haveOfferKind = .goods
        for item in items {
            selectedHaveIDs.insert(item.id)
            haveQuantities[item.id] = boundedQuantity(
                haveQuantities[item.id] ?? 1,
                maxQuantity: maxHaveQuantity(for: item)
            )
        }
        normalizeHaveMinimumCount()
        defaultHaveMinimumLogicIfNeeded(previousCount: previousCount)
    }

    mutating func deselectHaves(_ items: [GoodsItem]) {
        guard !items.isEmpty else {
            return
        }
        for item in items {
            selectedHaveIDs.remove(item.id)
            haveQuantities.removeValue(forKey: item.id)
        }
        normalizeHaveMinimumCount()
    }

    mutating func toggleWish(_ id: UUID) {
        let previousCount = selectedWishIDs.count
        if selectedWishIDs.contains(id) {
            selectedWishIDs.remove(id)
            wishQuantities.removeValue(forKey: id)
        } else {
            selectedWishIDs.insert(id)
            wishQuantities[id] = boundedQuantity(wishQuantities[id] ?? 1)
        }
        normalizeWishMinimumCount()
        defaultWishMinimumLogicIfNeeded(previousCount: previousCount)
    }

    mutating func selectAllWishes(_ items: [WishItem]) {
        guard !items.isEmpty else {
            return
        }
        let previousCount = selectedWishIDs.count
        for item in items {
            selectedWishIDs.insert(item.id)
            wishQuantities[item.id] = boundedQuantity(wishQuantities[item.id] ?? 1)
        }
        normalizeWishMinimumCount()
        defaultWishMinimumLogicIfNeeded(previousCount: previousCount)
    }

    mutating func deselectWishes(_ items: [WishItem]) {
        guard !items.isEmpty else {
            return
        }
        for item in items {
            selectedWishIDs.remove(item.id)
            wishQuantities.removeValue(forKey: item.id)
        }
        normalizeWishMinimumCount()
    }

    mutating func setOptionKind(_ kind: IndividualListingOptionKind) {
        optionKind = kind
        if kind != .wish, wishLogic == .atLeast {
            wishLogic = .one
            wishMinimumCount = 1
        }
    }

    mutating func setHaveOfferKind(_ kind: IndividualListingHaveOfferKind) {
        haveOfferKind = kind
        if kind == .cash {
            selectedHaveIDs.removeAll()
            haveQuantities.removeAll()
            haveLogic = .all
            haveMinimumCount = 1
        }
    }

    mutating func ensureDefaultCondition(groupID: UUID?, goodsTypeID: UUID?) {
        if conditionGroupID == nil {
            conditionGroupID = groupID
        }
        if conditionGoodsTypeID == nil {
            conditionGoodsTypeID = goodsTypeID
        }
    }

    mutating func setConditionGroupID(_ id: UUID?) {
        guard conditionGroupID != id else {
            return
        }
        conditionGroupID = id
        conditionMemberIDs.removeAll()
        excludesSelectedConditionMembers = false
        conditionTagNames.removeAll()
    }

    mutating func toggleConditionMember(_ id: UUID) {
        if conditionMemberIDs.contains(id) {
            conditionMemberIDs.remove(id)
            if conditionMemberIDs.isEmpty {
                excludesSelectedConditionMembers = false
            }
        } else {
            conditionMemberIDs.insert(id)
        }
    }

    mutating func setExcludesSelectedConditionMembers(_ value: Bool) {
        excludesSelectedConditionMembers = value && !conditionMemberIDs.isEmpty
    }

    mutating func toggleConditionTag(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return
        }
        if let index = conditionTagNames.firstIndex(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            conditionTagNames.remove(at: index)
        } else if conditionTagNames.count < 5 {
            conditionTagNames.append(trimmed)
        }
    }

    mutating func setConditionQuantity(_ quantity: Int) {
        conditionQuantity = boundedQuantity(quantity)
    }

    mutating func resetCurrentOptionSelection() {
        switch optionKind {
        case .wish:
            selectedWishIDs.removeAll()
            wishQuantities.removeAll()
            wishLogic = .one
            wishMinimumCount = 1
        case .condition:
            conditionGroupID = nil
            conditionMemberIDs.removeAll()
            excludesSelectedConditionMembers = false
            conditionGoodsTypeID = nil
            conditionTagNames.removeAll()
            conditionQuantity = 1
            if wishLogic == .atLeast {
                wishLogic = .one
                wishMinimumCount = 1
            }
        case .cash:
            cashPricingMode = .listPrice
            cashAmount = 1_100
            if wishLogic == .atLeast {
                wishLogic = .one
                wishMinimumCount = 1
            }
        }
    }

    var usesConditionLogicChoice: Bool {
        conditionMemberIDs.count > 1 || excludesSelectedConditionMembers
    }

    mutating func setHaveQuantity(_ id: UUID, quantity: Int, maxQuantity: Int = 99) {
        guard selectedHaveIDs.contains(id) else {
            return
        }
        haveQuantities[id] = boundedQuantity(quantity, maxQuantity: maxQuantity)
    }

    mutating func setWishQuantity(_ id: UUID, quantity: Int) {
        guard selectedWishIDs.contains(id) else {
            return
        }
        wishQuantities[id] = boundedQuantity(quantity)
    }

    func haveQuantity(for id: UUID) -> Int {
        boundedQuantity(haveQuantities[id] ?? 1)
    }

    func wishQuantity(for id: UUID) -> Int {
        boundedQuantity(wishQuantities[id] ?? 1)
    }

    var resolvedHaveMinimumCount: Int {
        guard haveLogic == .atLeast else {
            return 1
        }
        return boundedMinimumCount(haveMinimumCount, itemCount: selectedHaveIDs.count)
    }

    var resolvedWishMinimumCount: Int {
        guard wishLogic == .atLeast else {
            return 1
        }
        return boundedMinimumCount(wishMinimumCount, itemCount: selectedWishIDs.count)
    }

    mutating func setHaveLogic(_ logic: ListingLogic) {
        haveLogic = logic
        if logic == .atLeast {
            haveMinimumCount = defaultMinimumCount(for: selectedHaveIDs.count, current: haveMinimumCount)
        } else {
            haveMinimumCount = 1
        }
    }

    mutating func setWishLogic(_ logic: ListingLogic) {
        wishLogic = logic
        if logic == .atLeast {
            wishMinimumCount = defaultMinimumCount(for: selectedWishIDs.count, current: wishMinimumCount)
        } else {
            wishMinimumCount = 1
        }
    }

    mutating func setHaveMinimumCount(_ count: Int) {
        haveMinimumCount = boundedMinimumCount(count, itemCount: selectedHaveIDs.count)
        if selectedHaveIDs.count >= 2 {
            haveLogic = .atLeast
        }
    }

    mutating func setWishMinimumCount(_ count: Int) {
        wishMinimumCount = boundedMinimumCount(count, itemCount: selectedWishIDs.count)
        if selectedWishIDs.count >= 2 {
            wishLogic = .atLeast
        }
    }

    func validationMessage(inventory: [GoodsItem], wishes: [WishItem]) -> String? {
        let selectedHaveItems = selectedInventoryItems(from: inventory)
        switch haveOfferKind {
        case .goods:
            if selectedHaveIDs.isEmpty {
                return "譲るものを選択してください"
            }
            if selectedHaveItems.count != selectedHaveIDs.count {
                return "選択したマイグッズを読み込めませんでした"
            }
            if selectedHaveItems.contains(where: { maxHaveQuantity(for: $0) <= 0 }) {
                return "選択した譲るものの残数が足りません"
            }
            if selectedHaveItems.contains(where: { haveQuantity(for: $0.id) > maxHaveQuantity(for: $0) }) {
                return "選択した譲るものの残数が足りません"
            }
            if !hasSameGroupAndType(selectedHaveItems) {
                return "譲るものは同じグループ・同じ種別で選んでください"
            }
            if haveLogic == .atLeast, selectedHaveIDs.count < 2 {
                return "「何個以上」は2件以上選んだ時に設定できます"
            }
        case .cash:
            if haveCashPricingMode == .specifiedAmount, haveCashAmount <= 0 {
                return "金額を入力してください"
            }
        }

        switch optionKind {
        case .wish:
            if selectedWishIDs.isEmpty {
                return "求めるものを選択してください"
            }
            let selectedWishItems = selectedWishItems(from: wishes)
            if selectedWishItems.count != selectedWishIDs.count {
                return "選択したWishを読み込めませんでした"
            }
            if !hasSameGroupAndType(selectedWishItems) {
                return "求めるものは同じグループ・同じ種別で選んでください"
            }
            if wishLogic == .atLeast, selectedWishIDs.count < 2 {
                return "「何個以上」は2件以上選んだ時に設定できます"
            }
            if haveLogic == .one, wishLogic == .one, selectedHaveIDs.count > 1, selectedWishIDs.count > 1 {
                return "両方を「どれか1つだけ」にする場合は、片方を1件にしてください"
            }
        case .condition:
            if conditionGroupID == nil || conditionGoodsTypeID == nil {
                return "グループとグッズ種別を選択してください"
            }
        case .cash:
            if cashPricingMode == .specifiedAmount, cashAmount <= 0 {
                return "金額を入力してください"
            }
        }
        return nil
    }

    func createInput(inventory: [GoodsItem], wishes: [WishItem]) -> IndividualListingCreateInput? {
        guard validationMessage(inventory: inventory, wishes: wishes) == nil else {
            return nil
        }
        let selectedWishItems = optionKind == .wish ? selectedWishItems(from: wishes) : []
        return IndividualListingCreateInput(
            haveItems: haveOfferKind == .cash ? [] : selectedInventoryItems(from: inventory).map { item in
                ListingItemQuantity(
                    itemID: item.id,
                    quantity: min(haveQuantity(for: item.id), max(1, maxHaveQuantity(for: item)))
                )
            },
            haveLogic: haveLogic,
            haveMinimumCount: haveLogic == .atLeast ? resolvedHaveMinimumCount : 1,
            wishItems: selectedWishItems.map { item in
                ListingItemQuantity(itemID: item.id, quantity: wishQuantity(for: item.id))
            },
            wishLogic: wishLogic,
            wishMinimumCount: wishLogic == .atLeast ? resolvedWishMinimumCount : 1,
            exchangeType: exchangeType,
            isCashOffer: optionKind == .cash,
            cashAmount: optionKind == .cash && cashPricingMode == .specifiedAmount ? cashAmount : nil,
            wishGroupID: optionWishGroupID(selectedWishItems: selectedWishItems),
            wishGoodsTypeID: optionWishGoodsTypeID(selectedWishItems: selectedWishItems),
            note: trimmedNoteWithListingMetadata
        )
    }

    func updatedListing(from original: IndividualListing, inventory: [GoodsItem], wishes: [WishItem]) -> IndividualListing? {
        guard let input = createInput(inventory: inventory, wishes: wishes) else {
            return nil
        }
        let selectedHaveItems = selectedInventoryItems(from: inventory)
        var options = original.options.sorted { $0.position < $1.position }
        let existingOption = options.first
        let updatedOption = IndividualListingWishOption(
            id: existingOption?.id ?? UUID(),
            listingID: original.id,
            position: existingOption?.position ?? 1,
            wishes: input.wishItems,
            logic: input.wishLogic,
            minimumCount: input.wishMinimumCount,
            exchangeType: input.exchangeType,
            isCashOffer: input.isCashOffer,
            cashAmount: input.cashAmount,
            wishGroupID: input.wishGroupID,
            wishGoodsTypeID: input.wishGoodsTypeID,
            createdAt: existingOption?.createdAt,
            updatedAt: Date()
        )
        if options.isEmpty {
            options = [updatedOption]
        } else {
            options[0] = updatedOption
        }
        return IndividualListing(
            id: original.id,
            ownerID: original.ownerID,
            haves: input.haveItems,
            haveLogic: input.haveLogic,
            haveMinimumCount: input.haveMinimumCount,
            haveGroupID: haveOfferKind == .cash ? nil : selectedHaveItems.first?.groupID,
            haveGoodsTypeID: haveOfferKind == .cash ? nil : selectedHaveItems.first?.goodsTypeID,
            status: status,
            note: input.note,
            options: options,
            createdAt: original.createdAt,
            updatedAt: Date()
        )
    }

    private var trimmedNote: String? {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private var trimmedNoteWithListingMetadata: String? {
        var lines: [String] = []
        if let trimmedNote {
            lines.append(trimmedNote)
        }
        if includesExchangeConditionSummary {
            lines.append(exchangeConditionSummary)
        }
        if haveOfferKind == .cash {
            lines.append(haveCashSummary.storageLine)
        }
        let joined = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return joined.isEmpty ? nil : joined
    }

    private var haveCashSummary: IndividualListingHaveCashSummary {
        IndividualListingHaveCashSummary(
            pricingMode: haveCashPricingMode,
            amount: haveCashPricingMode == .specifiedAmount ? haveCashAmount : nil
        )
    }

    private var exchangeConditionSummary: String {
        IndividualListingExchangeSummary(
            handoffMethod: handoffMethod,
            localPrefecture: localPrefecture,
            localPlaceMemo: localPlaceMemo,
            localSchedule: localSchedule,
            shippingFee: shippingFee,
            shippingDays: shippingDays,
            acceptsOutsideCondition: acceptsOutsideCondition
        )
        .storageLine
    }

    private func selectedInventoryItems(from inventory: [GoodsItem]) -> [GoodsItem] {
        inventory.filter { selectedHaveIDs.contains($0.id) }
    }

    func maxHaveQuantity(for item: GoodsItem) -> Int {
        max(0, item.marketAvailableQuantity) + originalHaveQuantity(for: item.id)
    }

    private func originalHaveQuantity(for id: UUID) -> Int {
        guard case .edit(let listing) = mode else {
            return 0
        }
        return listing.haves.first(where: { $0.itemID == id })?.quantity ?? 0
    }

    private func selectedWishItems(from wishes: [WishItem]) -> [WishItem] {
        wishes.filter { selectedWishIDs.contains($0.id) }
    }

    private func optionWishGroupID(selectedWishItems: [WishItem]) -> UUID? {
        switch optionKind {
        case .wish:
            selectedWishItems.first?.groupID
        case .condition:
            conditionGroupID
        case .cash:
            nil
        }
    }

    private func optionWishGoodsTypeID(selectedWishItems: [WishItem]) -> UUID? {
        switch optionKind {
        case .wish:
            selectedWishItems.first?.goodsTypeID
        case .condition:
            conditionGoodsTypeID
        case .cash:
            nil
        }
    }

    private func hasSameGroupAndType(_ items: [GoodsItem]) -> Bool {
        guard let first = items.first else {
            return true
        }
        return items.allSatisfy { $0.groupID == first.groupID && $0.goodsTypeID == first.goodsTypeID }
    }

    private func hasSameGroupAndType(_ items: [WishItem]) -> Bool {
        guard let first = items.first else {
            return true
        }
        return items.allSatisfy { $0.groupID == first.groupID && $0.goodsTypeID == first.goodsTypeID }
    }

    private mutating func normalizeHaveMinimumCount() {
        guard haveLogic == .atLeast else {
            haveMinimumCount = 1
            return
        }
        if selectedHaveIDs.count < 2 {
            haveLogic = .all
            haveMinimumCount = 1
        } else {
            haveMinimumCount = boundedMinimumCount(haveMinimumCount, itemCount: selectedHaveIDs.count)
        }
    }

    private mutating func normalizeWishMinimumCount() {
        guard wishLogic == .atLeast else {
            wishMinimumCount = 1
            return
        }
        if selectedWishIDs.count < 2 {
            wishLogic = .one
            wishMinimumCount = 1
        } else {
            wishMinimumCount = boundedMinimumCount(wishMinimumCount, itemCount: selectedWishIDs.count)
        }
    }

    private mutating func defaultHaveMinimumLogicIfNeeded(previousCount: Int) {
        guard previousCount < 2, selectedHaveIDs.count >= 2 else {
            return
        }
        haveLogic = .atLeast
        haveMinimumCount = 1
    }

    private mutating func defaultWishMinimumLogicIfNeeded(previousCount: Int) {
        guard previousCount < 2, selectedWishIDs.count >= 2 else {
            return
        }
        wishLogic = .atLeast
        wishMinimumCount = 1
    }
}

private func boundedQuantity(_ quantity: Int, maxQuantity: Int = 99) -> Int {
    max(1, min(quantity, max(1, maxQuantity), 99))
}

private func defaultMinimumCount(for itemCount: Int, current: Int) -> Int {
    guard itemCount > 0 else {
        return 1
    }
    return boundedMinimumCount(current, itemCount: itemCount)
}

private func boundedMinimumCount(_ count: Int, itemCount: Int) -> Int {
    guard itemCount > 0 else {
        return 1
    }
    return max(1, min(count, itemCount))
}
