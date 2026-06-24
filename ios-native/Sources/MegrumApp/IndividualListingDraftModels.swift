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
            self.haveQuantities = Dictionary(uniqueKeysWithValues: listing.haves.map { ($0.itemID, Self.boundedQuantity($0.quantity)) })
            self.haveOfferKind = extractedHaveCash.summary == nil ? .goods : .cash
            self.haveCashPricingMode = extractedHaveCash.summary?.pricingMode ?? .listPrice
            self.haveCashAmount = max(1, extractedHaveCash.summary?.amount ?? 1_100)
            self.selectedWishIDs = Set(primaryOption?.wishes.map(\.itemID) ?? [])
            self.wishQuantities = Dictionary(uniqueKeysWithValues: (primaryOption?.wishes ?? []).map { ($0.itemID, Self.boundedQuantity($0.quantity)) })
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
}
