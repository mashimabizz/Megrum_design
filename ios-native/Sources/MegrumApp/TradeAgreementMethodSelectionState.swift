import MegrumCore

struct TradeAgreementMethodSelectionState: Equatable {
    var selectedExchangeMethod: ExchangeMethod = .hand

    func agreementExchangeMethod(needsChoice: Bool) -> ExchangeMethod? {
        needsChoice ? selectedExchangeMethod : nil
    }
}
