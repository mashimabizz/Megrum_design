import Foundation
import MegrumCore

enum IndividualListingEditorStep: Int, CaseIterable, Identifiable {
    case haves = 1
    case options = 2
    case exchange = 3

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .haves:
            "譲るものを選ぶ"
        case .options:
            "受け取れる条件を追加"
        case .exchange:
            "交換条件を設定する"
        }
    }

    var subtitle: String {
        switch self {
        case .haves:
            "まず、あなたが譲れるものを選びます"
        case .options:
            "相手から受け取りたいものを選びます"
        case .exchange:
            "この募集で受け付ける交換の条件を設定してください"
        }
    }
}

enum IndividualListingHandoffDraft: String, CaseIterable, Identifiable {
    case local
    case mail
    case both

    var id: String { rawValue }

    var title: String {
        switch self {
        case .local:
            "現地交換"
        case .mail:
            "郵送交換"
        case .both:
            "どちらもOK"
        }
    }

    var symbolName: String {
        switch self {
        case .local:
            "mappin"
        case .mail:
            "envelope"
        case .both:
            "mappin.and.ellipse"
        }
    }
}

enum IndividualListingShippingFeeDraft: String, CaseIterable, Identifiable {
    case owner
    case partner
    case negotiate

    var id: String { rawValue }

    var title: String {
        switch self {
        case .owner:
            "自己負担"
        case .partner:
            "相手負担"
        case .negotiate:
            "要相談"
        }
    }
}

enum IndividualListingShippingDaysDraft: String, CaseIterable, Identifiable {
    case oneDay
    case twoToFourDays
    case afterFiveDays

    var id: String { rawValue }

    var title: String {
        switch self {
        case .oneDay:
            "成立後1日以内"
        case .twoToFourDays:
            "2〜4日以内"
        case .afterFiveDays:
            "5日以降"
        }
    }
}

enum IndividualListingEditorMode: Equatable {
    case create(preselectedWishID: UUID?)
    case edit(IndividualListing)

    var isEditing: Bool {
        if case .edit = self {
            return true
        }
        return false
    }
}

enum IndividualListingOptionKind: String, CaseIterable, Identifiable {
    case wish
    case condition
    case cash

    var id: String { rawValue }

    var title: String {
        switch self {
        case .wish:
            "Wishから選ぶ"
        case .condition:
            "条件から選ぶ"
        case .cash:
            "定価"
        }
    }
}

struct IndividualListingDraft: Equatable {
    var mode: IndividualListingEditorMode
    var selectedHaveIDs: Set<UUID>
    var haveQuantities: [UUID: Int]
    var selectedWishIDs: Set<UUID>
    var wishQuantities: [UUID: Int]
    var optionKind: IndividualListingOptionKind
    var conditionGroupID: UUID?
    var conditionGoodsTypeID: UUID?
    var cashAmount: Int
    var haveLogic: ListingLogic
    var wishLogic: ListingLogic
    var exchangeType: IndividualListingExchangeType
    var status: IndividualListingStatus
    var note: String
    var handoffMethod: IndividualListingHandoffDraft
    var localPrefecture: String
    var localPlaceMemo: String
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
            self.selectedWishIDs = preselectedWishID.map { Set([$0]) } ?? []
            self.wishQuantities = preselectedWishID.map { [$0: 1] } ?? [:]
            self.optionKind = .wish
            self.conditionGroupID = nil
            self.conditionGoodsTypeID = nil
            self.cashAmount = 1_100
            self.haveLogic = .all
            self.wishLogic = .one
            self.exchangeType = .any
            self.status = .active
            self.note = ""
            self.handoffMethod = .both
            self.localPrefecture = "東京都"
            self.localPlaceMemo = ""
            self.shippingFee = .negotiate
            self.shippingDays = .twoToFourDays
            self.acceptsOutsideCondition = true
            self.includesExchangeConditionSummary = false
        case .edit(let listing):
            let primaryOption = listing.options.sorted { $0.position < $1.position }.first
            self.selectedHaveIDs = Set(listing.haves.map(\.itemID))
            self.haveQuantities = Dictionary(uniqueKeysWithValues: listing.haves.map { ($0.itemID, boundedQuantity($0.quantity)) })
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
            self.conditionGoodsTypeID = primaryOption?.wishGoodsTypeID
            self.cashAmount = max(1, primaryOption?.cashAmount ?? 1_100)
            self.haveLogic = listing.haveLogic
            self.wishLogic = primaryOption?.logic ?? .one
            self.exchangeType = primaryOption?.exchangeType ?? .any
            self.status = listing.status
            self.note = listing.note ?? ""
            self.handoffMethod = .both
            self.localPrefecture = "東京都"
            self.localPlaceMemo = ""
            self.shippingFee = .negotiate
            self.shippingDays = .twoToFourDays
            self.acceptsOutsideCondition = true
            self.includesExchangeConditionSummary = false
        }
    }

    var navigationTitle: String {
        mode.isEditing ? "個別募集を編集" : "個別募集を作成"
    }

    var confirmationTitle: String {
        mode.isEditing ? "反映" : "保存"
    }

    mutating func toggleHave(_ id: UUID, maxQuantity: Int = 99) {
        if selectedHaveIDs.contains(id) {
            selectedHaveIDs.remove(id)
            haveQuantities.removeValue(forKey: id)
        } else {
            selectedHaveIDs.insert(id)
            haveQuantities[id] = boundedQuantity(haveQuantities[id] ?? 1, maxQuantity: maxQuantity)
        }
    }

    mutating func toggleWish(_ id: UUID) {
        if selectedWishIDs.contains(id) {
            selectedWishIDs.remove(id)
            wishQuantities.removeValue(forKey: id)
        } else {
            selectedWishIDs.insert(id)
            wishQuantities[id] = boundedQuantity(wishQuantities[id] ?? 1)
        }
    }

    mutating func setOptionKind(_ kind: IndividualListingOptionKind) {
        optionKind = kind
    }

    mutating func ensureDefaultCondition(groupID: UUID?, goodsTypeID: UUID?) {
        if conditionGroupID == nil {
            conditionGroupID = groupID
        }
        if conditionGoodsTypeID == nil {
            conditionGoodsTypeID = goodsTypeID
        }
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

    func validationMessage(inventory: [GoodsItem], wishes: [WishItem]) -> String? {
        if selectedHaveIDs.isEmpty {
            return "譲るものを選択してください"
        }
        let selectedHaveItems = selectedInventoryItems(from: inventory)
        if selectedHaveItems.count != selectedHaveIDs.count {
            return "選択したマイグッズを読み込めませんでした"
        }
        if !hasSameGroupAndType(selectedHaveItems) {
            return "譲るものは同じグループ・同じ種別で選んでください"
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
            if haveLogic == .one, wishLogic == .one, selectedHaveIDs.count > 1, selectedWishIDs.count > 1 {
                return "両方を「どれか1つだけ」にする場合は、片方を1件にしてください"
            }
        case .condition:
            if conditionGroupID == nil || conditionGoodsTypeID == nil {
                return "グループとグッズ種別を選択してください"
            }
        case .cash:
            if cashAmount <= 0 {
                return "定価を入力してください"
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
            haveItems: selectedInventoryItems(from: inventory).map { item in
                ListingItemQuantity(itemID: item.id, quantity: haveQuantity(for: item.id))
            },
            haveLogic: haveLogic,
            wishItems: selectedWishItems.map { item in
                ListingItemQuantity(itemID: item.id, quantity: wishQuantity(for: item.id))
            },
            wishLogic: wishLogic,
            exchangeType: exchangeType,
            isCashOffer: optionKind == .cash,
            cashAmount: optionKind == .cash ? cashAmount : nil,
            wishGroupID: optionWishGroupID(selectedWishItems: selectedWishItems),
            wishGoodsTypeID: optionWishGoodsTypeID(selectedWishItems: selectedWishItems),
            note: trimmedNoteWithExchangeCondition
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
            haveGroupID: selectedHaveItems.first?.groupID,
            haveGoodsTypeID: selectedHaveItems.first?.goodsTypeID,
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

    private var trimmedNoteWithExchangeCondition: String? {
        guard includesExchangeConditionSummary else {
            return trimmedNote
        }
        let condition = exchangeConditionSummary
        guard let trimmedNote else {
            return condition
        }
        return "\(trimmedNote)\n\(condition)"
    }

    private var exchangeConditionSummary: String {
        var parts: [String] = ["交換手段: \(handoffMethod.title)"]
        if handoffMethod != .mail {
            let place = localPlaceMemo.trimmingCharacters(in: .whitespacesAndNewlines)
            parts.append("現地: \(localPrefecture)\(place.isEmpty ? "" : " / \(place)")")
        }
        if handoffMethod != .local {
            parts.append("送料: \(shippingFee.title)")
            parts.append("発送目安: \(shippingDays.title)")
        }
        parts.append(acceptsOutsideCondition ? "条件外打診: 可" : "条件外打診: 不可")
        return parts.joined(separator: " / ")
    }

    private func selectedInventoryItems(from inventory: [GoodsItem]) -> [GoodsItem] {
        inventory.filter { selectedHaveIDs.contains($0.id) }
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
}

private func boundedQuantity(_ quantity: Int, maxQuantity: Int = 99) -> Int {
    max(1, min(quantity, max(1, maxQuantity), 99))
}
