import MegrumCore
import MegrumDesign
import SwiftUI

extension ProposalCreateFlow {
    var body: some View {
        Group {
            if let submittedSummary {
                ProposalCreateCompletionView(
                    summary: submittedSummary,
                    onSearchMore: handleCompletionSearchMore,
                    onOpenTrades: handleCompletionOpenTrades
                )
            } else {
                ProposalCreateActiveContent(
                    selectedStep: $selectedStep,
                    exchangeMethod: $exchangeMethod,
                    selectionTabs: selectionTabs,
                    configuration: configuration,
                    senderCount: senderSelectionCount,
                    receiverCount: receiverSelectionCount,
                    contentSpacing: contentSpacing,
                    horizontalContentPadding: horizontalContentPadding,
                    usesInlineBottomBar: usesInlineBottomBar,
                    meetupHasTimeDraft: meetupInput != nil,
                    isCreating: appState.isCreatingProposal,
                    onBack: handleHeaderLeadingAction,
                    onPrimary: primaryAction,
                    giveContent: {
                        giveStep
                            .contentShape(Rectangle())
                            .simultaneousGesture(stepSwipeGesture)
                    },
                    receiveContent: {
                        receiveStep
                            .contentShape(Rectangle())
                            .simultaneousGesture(stepSwipeGesture)
                    },
                    meetupContent: {
                        meetupStep
                    },
                    shippingContent: {
                        shippingStep
                    },
                    paymentContent: {
                        paymentStep
                    },
                    confirmContent: {
                        confirmStep
                    }
                )
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if submittedSummary == nil && !usesInlineBottomBar {
                ProposalFlowBottomBar(
                    selectedStep: selectedStep,
                    configuration: configuration,
                    meetupHasTimeDraft: meetupInput != nil,
                    isCreating: appState.isCreatingProposal,
                    onPrimary: primaryAction
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .megrumEdgeBackSwipe(
            isEnabled: submittedSummary == nil && !appState.isCreatingProposal,
            action: handleHeaderLeadingAction
        )
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #else
        .megrumInlineNavigationTitle()
        #endif
        .interactiveDismissDisabled(appState.isCreatingProposal || submittedSummary != nil)
        .onAppear {
            prepareInitialProposalState()
        }
        .task(id: targetItem.ownerID) {
            await loadTargetOwnerExchangeContent()
        }
        .task {
            await loadMailingAddressIfNeeded()
        }
        .task {
            await loadProposalChoiceCatalogsIfNeeded()
        }
        .task {
            await loadPaymentSettingsIfNeeded()
        }
        .sheet(isPresented: $showsAddressSettings) {
            NavigationStack {
                AddressSettingsScreen(
                    appState: appState,
                    saveButtonTitle: "更新して戻る"
                )
            }
        }
        .sheet(
            item: $meetupPlaceSheetRoute,
            onDismiss: {
                meetupPlaceSheetRoute = nil
            }
        ) { route in
            ProposalMeetupPlaceSheet(
                route: route,
                previousDraft: previousMeetupPlaceDraft(before: route.index),
                currentCoordinate: locationState.coordinate,
                isRequestingLocation: locationState.isRequestingLocation,
                locationErrorMessage: locationState.locationErrorMessage,
                onRequestCurrentLocation: {
                    locationState.requestCurrentLocation()
                },
                onSave: saveMeetupPlaceSheetDraft
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: selectableSenderGoods.map(\.id)) { _, ids in
            reconcileSenderSelection(with: ids)
        }
        .onChange(of: receiverChoiceGoods.map(\.id)) { _, ids in
            reconcileReceiverSelection(with: ids)
        }
        .onChange(of: exchangeMethod) { _, _ in
            handleExchangeMethodChange()
        }
        .onChange(of: senderSelectionMode) { _, newValue in
            handleSenderSelectionModeChange(newValue)
        }
        .onChange(of: receiverSelectionMode) { _, newValue in
            handleReceiverSelectionModeChange(newValue)
        }
        .onChange(of: senderCashAmountText) { _, newValue in
            normalizeSenderCashAmountText(newValue)
            syncPaymentSelectionIfNeeded()
        }
        .onChange(of: receiverCashAmountText) { _, newValue in
            normalizeReceiverCashAmountText(newValue)
            syncPaymentSelectionIfNeeded()
        }
        .onChange(of: message) { _, newValue in
            enforceMessageLimit(newValue)
        }
        .onChange(of: meetupStartAt) { _, newValue in
            ensureMeetupEndAfterStart(newValue)
        }
        .onChange(of: locationState.coordinate) { _, _ in
            applyCurrentLocationToSelectedMeetupCandidate()
        }
    }

    private var selectionTabs: [ProposalCreateStep] {
        ProposalFlowScreenCopy.selectionTabs(from: visibleSteps)
    }

    private var usesInlineBottomBar: Bool {
        ProposalFlowBottomBarPlacement.usesInlineScrollButton(for: selectedStep)
    }

    private var horizontalContentPadding: CGFloat {
        selectedStep == .confirm
            ? ProposalFlowContentMetrics.confirmHorizontalPadding
            : ProposalFlowContentMetrics.defaultHorizontalPadding
    }

    private var contentSpacing: CGFloat {
        selectedStep == .confirm
            ? ProposalFlowContentMetrics.confirmContentSpacing
            : ProposalFlowContentMetrics.defaultContentSpacing
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

    private var giveStep: some View {
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

    private var receiveStep: some View {
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

    private var meetupStep: some View {
        ProposalMeetupConditionStep(
            prefecture: $meetupPrefecture,
            placeMemo: $meetupPlaceMemo,
            scheduleDate: $meetupStartAt,
            viewerConditionText: viewerLocalConditionText,
            partnerConditionText: partnerLocalConditionText
        )
    }

    private var shippingStep: some View {
        ProposalShippingConditionStep(
            shippingFee: $shippingFee,
            shippingDays: $shippingDays,
            viewerConditionText: viewerShippingConditionText,
            partnerConditionText: partnerShippingConditionText
        )
    }

    private var paymentStep: some View {
        ProposalPaymentMethodStepView(
            sections: paymentOptionSections,
            selectedOptionID: $selectedPaymentOptionID
        )
        .onAppear {
            syncPaymentSelectionIfNeeded()
        }
    }

    private var confirmStep: some View {
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
}
