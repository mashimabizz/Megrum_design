import MegrumCore

struct TradeDetailPinnedSummaryPresentationState {
    var detailRoute: TradeSummaryDetailRoute?
    var selectedExchangeMethod: ExchangeMethod?
    var selectedPaymentOptionID: String?

    mutating func openTradeContentDetails() {
        detailRoute = .tradeContent
    }

    func agreementExchangeMethod(for presentation: TradeProposalResponsePresentation) -> ExchangeMethod? {
        if presentation.needsExchangeMethodSelection {
            return selectedExchangeMethod ?? presentation.defaultSelectedExchangeMethod
        }
        return nil
    }
}
