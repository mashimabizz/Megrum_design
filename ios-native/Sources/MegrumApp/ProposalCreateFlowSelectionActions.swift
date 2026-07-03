import Foundation
import SwiftUI

extension ProposalCreateFlow {
    func reconcileSenderSelection(with ids: [UUID]) {
        selectedSenderGoodsIDs = ProposalCreateGoodsSelectionReducer.reconciled(
            selectedIDs: selectedSenderGoodsIDs,
            availableIDs: ids,
            fallbackIDs: initialSenderGoodsIDs
        )
    }

    func reconcileReceiverSelection(with ids: [UUID]) {
        selectedReceiverGoodsIDs = ProposalCreateGoodsSelectionReducer.reconciled(
            selectedIDs: selectedReceiverGoodsIDs,
            availableIDs: ids,
            fallbackIDs: receiverGoodsIDs ?? [targetItem.id]
        )
    }

    func handleSenderSelectionModeChange(_ newValue: ProposalSideSelectionMode) {
        _ = newValue
    }

    func handleReceiverSelectionModeChange(_ newValue: ProposalSideSelectionMode) {
        _ = newValue
    }

    func normalizeSenderCashAmountText(_ newValue: String) {
        valueSelectionState.normalizeSenderCashAmountText(newValue)
    }

    func normalizeReceiverCashAmountText(_ newValue: String) {
        valueSelectionState.normalizeReceiverCashAmountText(newValue)
    }

    func syncPaymentSelectionIfNeeded() {
        valueSelectionState.syncPaymentSelectionIfNeeded(options: paymentOptionSections.flatMap(\.options))
    }

    func toggleSenderGoods(_ id: UUID) {
        valueSelectionState.selectSenderGoodsMode()
        selectedSenderGoodsIDs = ProposalCreateGoodsSelectionReducer.toggled(selectedSenderGoodsIDs, id: id)
    }

    func toggleReceiverGoods(_ id: UUID) {
        valueSelectionState.selectReceiverGoodsMode()
        selectedReceiverGoodsIDs = ProposalCreateGoodsSelectionReducer.toggled(selectedReceiverGoodsIDs, id: id)
    }

    func seedDefaultSenderSelection() {
        selectedSenderGoodsIDs = ProposalCreateGoodsSelectionReducer.seeded(
            selectedIDs: selectedSenderGoodsIDs,
            availableIDs: selectableSenderGoods.map(\.id),
            fallbackIDs: initialSenderGoodsIDs
        )
    }

    func seedDefaultReceiverSelection() {
        selectedReceiverGoodsIDs = ProposalCreateGoodsSelectionReducer.seeded(
            selectedIDs: selectedReceiverGoodsIDs,
            availableIDs: receiverChoiceGoods.map(\.id),
            fallbackIDs: receiverGoodsIDs ?? [targetItem.id]
        )
    }

    func applyInitialCashAmountIfNeeded() {
        guard senderCashAmount == nil,
              let initialCashAmount,
              initialCashAmount > 0
        else {
            return
        }
        valueSelectionState.applyInitialSenderCashAmount(initialCashAmount)
    }
}
