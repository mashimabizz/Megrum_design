struct SubscriptionSettingsPresentationState: Equatable {
    var offer: MegrumPlusPurchaseOffer?
    var isLoadingOffer = false
    var isPurchasing = false
    var purchaseMessage: String?
    var purchaseErrorMessage: String?

    func displayOffer(fallback: MegrumPlusPurchaseOffer) -> MegrumPlusPurchaseOffer {
        offer ?? fallback
    }

    mutating func beginLoadingOfferIfNeeded() -> Bool {
        guard offer == nil, !isLoadingOffer else {
            return false
        }
        isLoadingOffer = true
        return true
    }

    mutating func finishLoadingOffer(_ offer: MegrumPlusPurchaseOffer) {
        self.offer = offer
        isLoadingOffer = false
    }

    mutating func beginPurchaseAction() -> Bool {
        guard !isPurchasing else {
            return false
        }
        isPurchasing = true
        purchaseMessage = nil
        purchaseErrorMessage = nil
        return true
    }

    mutating func finishPurchaseAction() {
        isPurchasing = false
    }

    mutating func setPurchaseMessage(_ message: String) {
        purchaseMessage = message
        purchaseErrorMessage = nil
    }

    mutating func setPurchaseErrorMessage(_ message: String) {
        purchaseMessage = nil
        purchaseErrorMessage = message
    }
}
