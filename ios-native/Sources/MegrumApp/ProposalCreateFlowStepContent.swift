import MegrumCore
import MegrumDesign
import SwiftUI

extension ProposalCreateFlow {
    var selectionTabs: [ProposalCreateStep] {
        ProposalFlowScreenCopy.selectionTabs(from: visibleSteps)
    }

    var usesInlineBottomBar: Bool {
        ProposalFlowBottomBarPlacement.usesInlineScrollButton(for: selectedStep)
    }

    var horizontalContentPadding: CGFloat {
        selectedStep == .confirm
            ? ProposalFlowContentMetrics.confirmHorizontalPadding
            : ProposalFlowContentMetrics.defaultHorizontalPadding
    }

    var contentSpacing: CGFloat {
        selectedStep == .confirm
            ? ProposalFlowContentMetrics.confirmContentSpacing
            : ProposalFlowContentMetrics.defaultContentSpacing
    }

    var giveStep: some View {
        ProposalGiveGoodsStep(
            selectableGoods: selectableSenderGoods,
            filteredGoods: filteredSenderGoods,
            groupChoices: senderGroupFilterChoices,
            goodsTypeChoices: senderGoodsTypeFilterChoices,
            selectedGoodsIDs: selectedSenderGoodsIDs,
            cashReferenceRows: listingCashReferenceRows,
            selectionMode: $valueSelectionState.senderSelectionMode,
            cashAmountText: $valueSelectionState.senderCashAmountText,
            selectedGroupID: $filterState.senderGroupID,
            selectedGoodsTypeID: $filterState.senderGoodsTypeID,
            onToggleGoods: toggleSenderGoods
        )
    }

    var receiveStep: some View {
        ProposalReceiveGoodsStep(
            filteredGoods: filteredReceiverGoods,
            groupChoices: receiverGroupFilterChoices,
            goodsTypeChoices: receiverGoodsTypeFilterChoices,
            selectedGoodsIDs: selectedReceiverGoodsIDs,
            cashReferenceRows: listingCashReferenceRows,
            selectionMode: $valueSelectionState.receiverSelectionMode,
            cashAmountText: $valueSelectionState.receiverCashAmountText,
            selectedGroupID: $filterState.receiverGroupID,
            selectedGoodsTypeID: $filterState.receiverGoodsTypeID,
            onToggleGoods: toggleReceiverGoods
        )
    }

    var conditionsStep: some View {
        ProposalExchangeConditionsStep(
            exchangeMethod: $exchangeMethod,
            requiresPaymentSelection: configuration.requiresPaymentSelection,
            meetupContent: { meetupStep },
            shippingContent: { shippingStep },
            paymentContent: { paymentStep }
        )
    }

    var meetupStep: some View {
        ProposalMeetupConditionStep(
            prefecture: $meetupPrefecture,
            placeMemo: $meetupPlaceMemo,
            scheduleDate: $meetupStartAt,
            viewerConditionText: viewerLocalConditionText,
            partnerConditionText: partnerLocalConditionText
        )
    }

    var shippingStep: some View {
        ProposalShippingConditionStep(
            shippingFee: $shippingFee,
            shippingDays: $shippingDays,
            viewerConditionText: viewerShippingConditionText,
            partnerConditionText: partnerShippingConditionText
        )
    }

    var paymentStep: some View {
        ProposalPaymentMethodStepView(
            sections: paymentOptionSections,
            selectedOptionID: $valueSelectionState.selectedPaymentOptionID
        )
        .onAppear {
            syncPaymentSelectionIfNeeded()
        }
    }

    var confirmStep: some View {
        ProposalConfirmStepView(
            requiresMeetupBeforeSubmit: configuration.requiresMeetupBeforeSubmit,
            requiresShippingBeforeSubmit: configuration.requiresShippingBeforeSubmit,
            senderGoods: selectedSenderGoods,
            receiverGoods: selectedReceiverGoods,
            senderCashAmount: senderCashAmount,
            receiverCashAmount: receiverCashAmount,
            exchangeMethod: exchangeMethod,
            mailingAddress: appState.mailingAddress,
            isLoadingMailingAddress: appState.isLoadingMailingAddress,
            meetupInputs: meetupInputsForSubmission,
            meetupSummaryText: proposalMeetupSummaryText,
            shippingSummaryText: proposalShippingSummaryText,
            selectedPaymentSummaryText: selectedPaymentSummaryText,
            message: $message,
            messageLimit: Self.messageLimit,
            shareSchedule: $shareSchedule,
            errorMessage: appState.errorMessage,
            onOpenAddressSettings: {
                showsAddressSettings = true
            }
        )
    }

    private var filteredSenderGoods: [GoodsItem] {
        filterState.filteredSenderGoods(from: selectableSenderGoods)
    }

    private var senderGroupFilterChoices: [ProposalFilterChoice] {
        ProposalGoodsFilterCatalog.groupChoices(items: selectableSenderGoods, groups: appState.oshiGroups)
    }

    private var senderGoodsTypeFilterChoices: [ProposalFilterChoice] {
        ProposalGoodsFilterCatalog.goodsTypeChoices(items: selectableSenderGoods, goodsTypes: appState.goodsTypes)
    }

    private var filteredReceiverGoods: [GoodsItem] {
        filterState.filteredReceiverGoods(from: receiverChoiceGoods)
    }

    private var receiverGroupFilterChoices: [ProposalFilterChoice] {
        ProposalGoodsFilterCatalog.groupChoices(items: receiverChoiceGoods, groups: appState.oshiGroups)
    }

    private var receiverGoodsTypeFilterChoices: [ProposalFilterChoice] {
        ProposalGoodsFilterCatalog.goodsTypeChoices(items: receiverChoiceGoods, goodsTypes: appState.goodsTypes)
    }
}
