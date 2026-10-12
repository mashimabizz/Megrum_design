import MegrumCore
import MegrumDesign
import SwiftUI

extension ProposalCreateFlow {
    var body: some View {
        ZStack {
            if submittedSummary == nil {
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
                        conditionsStep
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
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .zIndex(0)
            }

            if let submittedSummary {
                ProposalCreateCompletionView(
                    summary: submittedSummary,
                    onSearchMore: handleCompletionSearchMore,
                    onOpenTrades: handleCompletionOpenTrades
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
                .zIndex(1)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if submittedSummary == nil && !usesInlineBottomBar {
                ProposalFlowBottomBar(
                    selectedStep: selectedStep,
                    configuration: configuration,
                    meetupHasTimeDraft: meetupInput != nil,
                    isCreating: appState.isCreatingProposal,
                    onPrimary: primaryAction,
                    onBack: handleHeaderLeadingAction
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .megrumInteractiveBackSwipe(
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
        .sheet(isPresented: $showsPartnerScheduleCalendar) {
            // ホーム・プロフィールの「相手の交換条件」カレンダーと同一モジュール。
            HomePartnerExchangeCalendarSheet(context: partnerExchangeCalendarContext)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showsViewerScheduleCalendar) {
            // 自分の交換条件も相手と同じカレンダーモジュールで表示する。
            HomePartnerExchangeCalendarSheet(context: viewerExchangeCalendarContext)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
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
        .onChange(of: valueSelectionState.senderSelectionMode) { _, newValue in
            handleSenderSelectionModeChange(newValue)
        }
        .onChange(of: valueSelectionState.receiverSelectionMode) { _, newValue in
            handleReceiverSelectionModeChange(newValue)
        }
        .onChange(of: valueSelectionState.senderCashAmountText) { _, newValue in
            normalizeSenderCashAmountText(newValue)
            syncPaymentSelectionIfNeeded()
        }
        .onChange(of: valueSelectionState.receiverCashAmountText) { _, newValue in
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

}
