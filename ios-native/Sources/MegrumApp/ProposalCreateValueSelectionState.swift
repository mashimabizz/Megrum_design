import Foundation

struct ProposalCreateValueSelectionState: Equatable, Sendable {
    var senderSelectionMode: ProposalSideSelectionMode = .goods
    var receiverSelectionMode: ProposalSideSelectionMode = .goods
    var senderCashAmountText = ""
    var receiverCashAmountText = ""
    var selectedPaymentOptionID: String?

    var senderCashAmount: Int? {
        TradeAmountFormatter.cashInputValue(from: senderCashAmountText)
    }

    var receiverCashAmount: Int? {
        TradeAmountFormatter.cashInputValue(from: receiverCashAmountText)
    }

    var requiresPaymentStep: Bool {
        senderCashAmount != nil || receiverCashAmount != nil
    }

    mutating func normalizeSenderCashAmountText(_ newValue: String) {
        let normalized = TradeAmountFormatter.cashInputText(from: newValue)
        if normalized != newValue {
            senderCashAmountText = normalized
        }
    }

    mutating func normalizeReceiverCashAmountText(_ newValue: String) {
        let normalized = TradeAmountFormatter.cashInputText(from: newValue)
        if normalized != newValue {
            receiverCashAmountText = normalized
        }
    }

    mutating func syncPaymentSelectionIfNeeded(options: [ProposalPaymentOption]) {
        selectedPaymentOptionID = ProposalPaymentOptionSelectionResolver.resolvedSelectionID(
            currentID: selectedPaymentOptionID,
            requiresPaymentStep: requiresPaymentStep,
            options: options
        )
    }

    mutating func selectSenderGoodsMode() {
        senderSelectionMode = .goods
    }

    mutating func selectReceiverGoodsMode() {
        receiverSelectionMode = .goods
    }

    mutating func applyInitialSenderCashAmount(_ amount: Int) {
        senderSelectionMode = .cash
        senderCashAmountText = TradeAmountFormatter.cashInputText(from: String(amount))
    }
}
