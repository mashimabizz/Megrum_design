import Foundation
import MegrumCore

extension TradeProposal {
    var canRespondToProposal: Bool {
        [.sent, .negotiating, .agreementOneSide].contains(status)
    }

    func resolvedExchangeMethod(forAcceptance selectedMethod: ExchangeMethod?) throws -> ExchangeMethod {
        switch exchangeMethod {
        case .both:
            guard let selectedMethod, selectedMethod != .both else {
                throw SupabaseProposalClientError.invalidStatus
            }
            return selectedMethod
        case .hand, .mail:
            if let selectedMethod, selectedMethod != exchangeMethod {
                throw SupabaseProposalClientError.invalidStatus
            }
            return exchangeMethod
        }
    }

    func nextAgreementApproved(by userID: UUID) -> (agreedBySender: Bool, agreedByReceiver: Bool) {
        let senderIsImplicitlyAgreed = status == .sent
        let nextSender = isSender(userID) ? true : (agreedBySender || senderIsImplicitlyAgreed)
        let nextReceiver = isSender(userID) ? agreedByReceiver : true
        return (nextSender, nextReceiver)
    }
}
