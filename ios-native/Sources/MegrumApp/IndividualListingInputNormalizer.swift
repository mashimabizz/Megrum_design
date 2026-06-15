import Foundation
import MegrumCore

enum IndividualListingInputNormalizer {
    static func normalized(_ input: IndividualListingCreateInput) -> IndividualListingCreateInput {
        IndividualListingCreateInput(
            haveItems: input.haveItems.map(normalizedQuantity),
            haveLogic: input.haveLogic,
            wishItems: input.wishItems.map(normalizedQuantity),
            wishLogic: input.wishLogic,
            exchangeType: input.exchangeType,
            isCashOffer: input.isCashOffer,
            cashAmount: input.cashAmount,
            wishGroupID: input.wishGroupID,
            wishGoodsTypeID: input.wishGoodsTypeID,
            note: input.note.nilIfBlank
        )
    }

    private static func normalizedQuantity(_ item: ListingItemQuantity) -> ListingItemQuantity {
        ListingItemQuantity(itemID: item.itemID, quantity: max(1, min(item.quantity, 99)))
    }
}

extension IndividualListingCreateInput {
    var hasReceivableCondition: Bool {
        !wishItems.isEmpty || isCashOffer || wishGroupID != nil || wishGoodsTypeID != nil
    }
}
