import Foundation
import SwiftUI

extension ProposalCreateFlow {
    func reconcileSenderSelection(with ids: [UUID]) {
        selectedSenderGoodsIDs = selectedSenderGoodsIDs.intersection(Set(ids))
        seedDefaultSenderSelection()
    }

    func reconcileReceiverSelection(with ids: [UUID]) {
        selectedReceiverGoodsIDs = selectedReceiverGoodsIDs.intersection(Set(ids))
        seedDefaultReceiverSelection()
    }

    func handleSenderSelectionModeChange(_ newValue: ProposalSideSelectionMode) {
        _ = newValue
    }

    func handleReceiverSelectionModeChange(_ newValue: ProposalSideSelectionMode) {
        _ = newValue
    }

    func normalizeSenderCashAmountText(_ newValue: String) {
        let normalized = TradeAmountFormatter.cashInputText(from: newValue)
        if normalized != newValue {
            senderCashAmountText = normalized
        }
    }

    func normalizeReceiverCashAmountText(_ newValue: String) {
        let normalized = TradeAmountFormatter.cashInputText(from: newValue)
        if normalized != newValue {
            receiverCashAmountText = normalized
        }
    }

    func syncPaymentSelectionIfNeeded() {
        guard requiresPaymentStep else {
            selectedPaymentOptionID = nil
            return
        }
        let options = paymentOptionSections.flatMap(\.options)
        guard !options.isEmpty else {
            selectedPaymentOptionID = nil
            return
        }
        if let selectedPaymentOptionID,
           options.contains(where: { $0.id == selectedPaymentOptionID }) {
            return
        }
        selectedPaymentOptionID = options.first?.id
    }

    func toggleSenderGoods(_ id: UUID) {
        senderSelectionMode = .goods
        if selectedSenderGoodsIDs.contains(id) {
            selectedSenderGoodsIDs.remove(id)
        } else {
            selectedSenderGoodsIDs.insert(id)
        }
    }

    func toggleReceiverGoods(_ id: UUID) {
        receiverSelectionMode = .goods
        if selectedReceiverGoodsIDs.contains(id) {
            selectedReceiverGoodsIDs.remove(id)
        } else {
            selectedReceiverGoodsIDs.insert(id)
        }
    }

    func seedDefaultSenderSelection() {
        guard selectedSenderGoodsIDs.isEmpty else {
            return
        }
        let availableIDs = Set(selectableSenderGoods.map(\.id))
        let seededIDs = initialSenderGoodsIDs.filter { availableIDs.contains($0) }
        if !seededIDs.isEmpty {
            selectedSenderGoodsIDs = Set(seededIDs)
            return
        }
    }

    func seedDefaultReceiverSelection() {
        guard selectedReceiverGoodsIDs.isEmpty else {
            return
        }
        let availableIDs = Set(receiverChoiceGoods.map(\.id))
        let candidateIDs = (receiverGoodsIDs ?? [targetItem.id]).filter { availableIDs.contains($0) }
        if !candidateIDs.isEmpty {
            selectedReceiverGoodsIDs = Set(candidateIDs)
            return
        }
    }

    func applyInitialCashAmountIfNeeded() {
        guard senderCashAmount == nil,
              let initialCashAmount,
              initialCashAmount > 0
        else {
            return
        }
        senderSelectionMode = .cash
        senderCashAmountText = TradeAmountFormatter.cashInputText(from: String(initialCashAmount))
    }
}
