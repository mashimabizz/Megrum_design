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
            selectionMode: $senderSelectionMode,
            cashAmountText: $senderCashAmountText,
            selectedGroupID: $senderGroupFilterID,
            selectedGoodsTypeID: $senderGoodsTypeFilterID,
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
            selectionMode: $receiverSelectionMode,
            cashAmountText: $receiverCashAmountText,
            selectedGroupID: $receiverGroupFilterID,
            selectedGoodsTypeID: $receiverGoodsTypeFilterID,
            onToggleGoods: toggleReceiverGoods
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
            selectedOptionID: $selectedPaymentOptionID
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
        selectableSenderGoods.filter { item in
            (senderGroupFilterID == nil || item.groupID == senderGroupFilterID)
                && (senderGoodsTypeFilterID == nil || item.goodsTypeID == senderGoodsTypeFilterID)
        }
    }

    private var senderGroupFilterChoices: [ProposalFilterChoice] {
        ProposalGoodsFilterCatalog.groupChoices(items: selectableSenderGoods, groups: appState.oshiGroups)
    }

    private var senderGoodsTypeFilterChoices: [ProposalFilterChoice] {
        ProposalGoodsFilterCatalog.goodsTypeChoices(items: selectableSenderGoods, goodsTypes: appState.goodsTypes)
    }

    private var filteredReceiverGoods: [GoodsItem] {
        receiverChoiceGoods.filter { item in
            (receiverGroupFilterID == nil || item.groupID == receiverGroupFilterID)
                && (receiverGoodsTypeFilterID == nil || item.goodsTypeID == receiverGoodsTypeFilterID)
        }
    }

    private var receiverGroupFilterChoices: [ProposalFilterChoice] {
        ProposalGoodsFilterCatalog.groupChoices(items: receiverChoiceGoods, groups: appState.oshiGroups)
    }

    private var receiverGoodsTypeFilterChoices: [ProposalFilterChoice] {
        ProposalGoodsFilterCatalog.goodsTypeChoices(items: receiverChoiceGoods, goodsTypes: appState.goodsTypes)
    }
}
