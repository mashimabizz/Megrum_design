import Foundation
import MegrumCore

enum IndividualListingInputNormalizer {
    static func normalized(_ input: IndividualListingCreateInput) -> IndividualListingCreateInput {
        IndividualListingCreateInput(
            haveItems: input.haveItems.map(normalizedQuantity),
            haveLogic: input.haveLogic,
            haveMinimumCount: input.haveMinimumCount,
            haveIsCashOffer: input.haveIsCashOffer,
            haveCashAmount: input.haveCashAmount,
            wishItems: input.wishItems.map(normalizedQuantity),
            wishLogic: input.wishLogic,
            wishMinimumCount: input.wishMinimumCount,
            exchangeType: input.exchangeType,
            isCashOffer: input.isCashOffer,
            cashAmount: input.cashAmount,
            wishGroupID: input.wishGroupID,
            wishGoodsTypeID: input.wishGoodsTypeID,
            additionalOptions: input.additionalOptions.map(normalizedOption),
            note: input.note.nilIfBlank
        )
    }

    private static func normalizedOption(_ option: IndividualListingOptionInput) -> IndividualListingOptionInput {
        var normalized = option
        normalized.wishItems = option.wishItems.map(normalizedQuantity)
        return normalized
    }

    private static func normalizedQuantity(_ item: ListingItemQuantity) -> ListingItemQuantity {
        ListingItemQuantity(itemID: item.itemID, quantity: max(1, min(item.quantity, 99)))
    }
}

extension IndividualListingCreateInput {
    var hasOfferCondition: Bool {
        !haveItems.isEmpty || haveIsCashOffer
    }

    var hasReceivableCondition: Bool {
        !wishItems.isEmpty || isCashOffer || wishGroupID != nil || wishGoodsTypeID != nil
    }
}
