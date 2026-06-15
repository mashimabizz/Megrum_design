import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct ProposalCreateFlow: View {
    private static let messageLimit = 400

    @ObservedObject var appState: MegrumAppState
    var targetItem: GoodsItem
    var listingID: UUID?
    var receiverGoodsIDs: [UUID]?
    var initialSenderGoodsIDs: [UUID] = []
    var matchType: ProposalMatchType = .perfect
    var initialExchangeMethod: ExchangeMethod? = nil
    var initialCashAmount: Int? = nil
    var initialStep: ProposalCreateStep = .give
    var visualQAInitialScreen: VisualQAInitialScreen? = nil
    var onCompletionAction: (ProposalCompletionAction) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss
    @State private var selectedStep: ProposalCreateStep = .give
    @State private var selectedSenderGoodsIDs: Set<UUID> = []
    @State private var selectedReceiverGoodsIDs: Set<UUID> = []
    @State private var proposalCashAmount: Int?
    @State private var senderGroupFilterID: UUID?
    @State private var senderGoodsTypeFilterID: UUID?
    @State private var receiverGroupFilterID: UUID?
    @State private var receiverGoodsTypeFilterID: UUID?
    @State private var exchangeMethod: ExchangeMethod = .hand
    @State private var shareSchedule = true
    @State private var message = ""
    @State private var meetupStartAt = Date()
    @State private var meetupEndAt = Date().addingTimeInterval(30 * 60)
    @State private var meetupPlaceName = ""
    @State private var meetupLatitudeText = ""
    @State private var meetupLongitudeText = ""
    @State private var meetupCandidateDrafts: [ProposalMeetupCandidateDraft] = []
    @State private var selectedMeetupCandidateIndex = 0
    @State private var meetupCalendarAnchorDate = Date()
    @State private var meetupPlaceSheetRoute: ProposalMeetupPlaceSheetRoute?
    @State private var submittedSummary: ProposalSubmittedSummary?
    @State private var didApplyInitialExchangeMethod = false
    @State private var didApplyInitialStep = false
    @State private var didApplyVisualQAState = false
    @State private var showsAddressSettings = false
    @StateObject private var locationState = MegrumLocationState()

    private var visibleSteps: [ProposalCreateStep] {
        var steps: [ProposalCreateStep] = [.give, .receive]
        if configuration.requiresMeetupBeforeSubmit {
            steps.append(.meetup)
        }
        steps.append(.confirm)
        return steps
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

    private var selectableSenderGoods: [GoodsItem] {
        let senderGoods = MatchRelationComposer.selectableSenderGoods(from: appState.inventory)
        guard let viewerID = appState.viewer?.id else {
            return senderGoods
        }
        return senderGoods.filter { $0.ownerID == viewerID }
    }

    private var receiverChoiceGoods: [GoodsItem] {
        let loaded = appState.publicTradeGoodsByUserID[targetItem.ownerID] ?? []
        return MatchRelationComposer.deduplicatedGoods([targetItem] + loaded)
            .filter { $0.marketAvailableQuantity > 0 }
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

    private var orderedSenderGoodsIDs: [UUID] {
        selectableSenderGoods.map(\.id).filter { selectedSenderGoodsIDs.contains($0) }
    }

    private var orderedReceiverGoodsIDs: [UUID] {
        receiverChoiceGoods.map(\.id).filter { selectedReceiverGoodsIDs.contains($0) }
    }

    private var selectedSenderGoods: [GoodsItem] {
        selectableSenderGoods.filter { selectedSenderGoodsIDs.contains($0.id) }
    }

    private var selectedReceiverGoods: [GoodsItem] {
        receiverChoiceGoods.filter { selectedReceiverGoodsIDs.contains($0.id) }
    }

    private var resolvedReceiverGoodsIDs: [UUID] {
        orderedReceiverGoodsIDs
    }

    private var configuration: ProposalCreateConfiguration {
        ProposalCreateConfiguration(
            exchangeMethod: exchangeMethod,
            hasSelectedSenderGoods: !orderedSenderGoodsIDs.isEmpty,
            hasCashOffer: proposalCashAmount != nil,
            isCreatingProposal: appState.isCreatingProposal,
            hasReadyMailingAddress: appState.mailingAddress?.isReady == true,
            isLoadingMailingAddress: appState.isLoadingMailingAddress,
            hasValidMeetup: meetupInput?.isValid == true,
            receiverGoodsCount: resolvedReceiverGoodsIDs.count,
            isListingSource: listingID != nil
        )
    }

    private var meetupInput: ProposalMeetupInput? {
        guard meetupCandidateDrafts.indices.contains(selectedMeetupCandidateIndex) else {
            return nil
        }
        return selectedMeetupCandidateDraft.meetupInput
    }

    private var meetupInputsForSubmission: [ProposalMeetupInput] {
        let drafts = displayMeetupCandidateDrafts
        let orderedIndices = [selectedMeetupCandidateIndex]
            + drafts.indices.filter { $0 != selectedMeetupCandidateIndex }
        return Array(
            orderedIndices
                .compactMap { index in drafts.indices.contains(index) ? drafts[index].meetupInput : nil }
                .prefix(ProposalMeetupCandidateDraft.maxCandidates)
        )
    }

    private var selectedMeetupCandidateDraft: ProposalMeetupCandidateDraft {
        let candidateID = meetupCandidateDrafts.indices.contains(selectedMeetupCandidateIndex)
            ? meetupCandidateDrafts[selectedMeetupCandidateIndex].id
            : UUID()
        return ProposalMeetupCandidateDraft(
            id: candidateID,
            startAt: meetupStartAt,
            endAt: meetupEndAt,
            placeName: meetupPlaceName,
            latitudeText: meetupLatitudeText,
            longitudeText: meetupLongitudeText
        )
    }

    private var displayMeetupCandidateDrafts: [ProposalMeetupCandidateDraft] {
        var drafts = meetupCandidateDrafts
        if drafts.indices.contains(selectedMeetupCandidateIndex) {
            drafts[selectedMeetupCandidateIndex] = selectedMeetupCandidateDraft
        }
        return drafts
    }

    private var proposalScheduleContext: ProposalScheduleContext {
        let cachedSchedules = appState.schedulesByProposalID.values.reduce(into: [PersonalSchedule]()) { result, schedules in
            result.append(contentsOf: schedules)
        }
        return ProposalScheduleContext(
            schedules: cachedSchedules,
            viewerID: appState.viewer?.id,
            partnerID: targetItem.ownerID,
            selectedStartAt: meetupStartAt,
            selectedEndAt: meetupEndAt
        )
    }

    private var meetupSummary: String {
        if let meetupInput {
            return "\(Self.dateText(meetupInput.startAt)) / \(meetupInput.normalizedPlaceName)"
        }
        return configuration.requiresMeetupBeforeSubmit ? "未設定" : "現地では会わない設定"
    }

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
                    senderCount: orderedSenderGoodsIDs.count,
                    receiverCount: resolvedReceiverGoodsIDs.count,
                    contentSpacing: contentSpacing,
                    horizontalContentPadding: horizontalContentPadding,
                    usesInlineBottomBar: usesInlineBottomBar,
                    meetupHasTimeDraft: !displayMeetupCandidateDrafts.isEmpty,
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
                    meetupHasTimeDraft: !displayMeetupCandidateDrafts.isEmpty,
                    isCreating: appState.isCreatingProposal,
                    onPrimary: primaryAction
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MegrumTheme.canvas.ignoresSafeArea())
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

    private var giveStep: some View {
        ProposalGiveGoodsStep(
            selectableGoods: selectableSenderGoods,
            filteredGoods: filteredSenderGoods,
            groupChoices: senderGroupFilterChoices,
            goodsTypeChoices: senderGoodsTypeFilterChoices,
            selectedGoodsIDs: selectedSenderGoodsIDs,
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
            selectedGroupID: $receiverGroupFilterID,
            selectedGoodsTypeID: $receiverGoodsTypeFilterID,
            onToggleGoods: toggleReceiverGoods
        )
    }

    private var meetupStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            if configuration.requiresMeetupBeforeSubmit {
                ProposalMeetupCalendarEditor(
                    drafts: displayMeetupCandidateDrafts,
                    selectedIndex: selectedMeetupCandidateIndex,
                    anchorDate: meetupCalendarAnchorDate,
                    scheduleContext: proposalScheduleContext,
                    onSelectDraft: selectMeetupCandidate,
                    onShiftWeek: shiftMeetupWeek,
                    onSelectMonthDay: selectMeetupCalendarDay,
                    onShiftMonth: shiftMeetupMonth,
                    onCreateDraft: createMeetupCandidate,
                    onUpdateDraft: updateMeetupCandidate,
                    onRemoveDraft: removeMeetupCandidate,
                    onOpenPlaceEntry: { index in
                        openMeetupPlaceSheet(for: index)
                    }
                )
            }

        }
    }

    private var confirmStep: some View {
        ProposalConfirmStepView(
            requiresMeetupBeforeSubmit: configuration.requiresMeetupBeforeSubmit,
            senderGoods: selectedSenderGoods,
            receiverGoods: selectedReceiverGoods,
            exchangeMethod: exchangeMethod,
            mailingAddress: appState.mailingAddress,
            isLoadingMailingAddress: appState.isLoadingMailingAddress,
            meetupInputs: meetupInputsForSubmission,
            message: $message,
            messageLimit: Self.messageLimit,
            shareSchedule: $shareSchedule,
            errorMessage: appState.errorMessage,
            onOpenAddressSettings: {
                showsAddressSettings = true
            }
        )
    }

    private var methodNotice: String? {
        if configuration.requiresMailingAddressBeforeSubmit && appState.isLoadingMailingAddress {
            return "住所登録を確認しています。"
        }
        if configuration.requiresMailingAddressBeforeSubmit && appState.mailingAddress?.isReady != true {
            return "郵送交換は住所登録が必要です。設定から住所を登録してください。"
        }
        if configuration.requiresMeetupBeforeSubmit && meetupInput == nil {
            return "日時、場所名、緯度経度を入れると次へ進めます。"
        }
        return nil
    }

    private func handleHeaderLeadingAction() {
        if selectedStep == .confirm {
            previousStep()
        } else {
            dismiss()
        }
    }

    private func handleCompletionSearchMore() {
        onCompletionAction(.searchMore)
        dismiss()
    }

    private func handleCompletionOpenTrades() {
        onCompletionAction(.openTrades)
        dismiss()
    }

    private func prepareInitialProposalState() {
        applyInitialExchangeMethodIfNeeded()
        applyInitialCashAmountIfNeeded()
        seedDefaultSenderSelection()
        seedDefaultReceiverSelection()
        normalizeMeetupEnd()
        applyVisualQAStateIfNeeded()
        applyInitialStepIfNeeded()
        meetupCalendarAnchorDate = calendarAnchorDate(for: meetupStartAt)
    }

    private func loadTargetOwnerExchangeContent() async {
        await appState.loadPublicExchangeContent(userID: targetItem.ownerID)
    }

    private func loadMailingAddressIfNeeded() async {
        if appState.mailingAddress == nil {
            await appState.loadMailingAddress()
        }
        applyInitialStepIfNeeded()
    }

    private func loadProposalChoiceCatalogsIfNeeded() async {
        if appState.oshiGroups.isEmpty {
            await appState.loadOshiGroups()
        }
        if appState.goodsTypes.isEmpty {
            await appState.loadGoodsTypes()
        }
    }

    private func reconcileSenderSelection(with ids: [UUID]) {
        selectedSenderGoodsIDs = selectedSenderGoodsIDs.intersection(Set(ids))
        seedDefaultSenderSelection()
    }

    private func reconcileReceiverSelection(with ids: [UUID]) {
        selectedReceiverGoodsIDs = selectedReceiverGoodsIDs.intersection(Set(ids))
        seedDefaultReceiverSelection()
    }

    private func handleExchangeMethodChange() {
        if selectedStep == .meetup && !configuration.requiresMeetupBeforeSubmit {
            selectedStep = .confirm
        }
        applyInitialStepIfNeeded()
    }

    private func enforceMessageLimit(_ newValue: String) {
        guard newValue.count > Self.messageLimit else {
            return
        }
        message = String(newValue.prefix(Self.messageLimit))
    }

    private func ensureMeetupEndAfterStart(_ newValue: Date) {
        if meetupEndAt <= newValue {
            meetupEndAt = newValue.addingTimeInterval(30 * 60)
        }
    }

    private func applyCurrentLocationToSelectedMeetupCandidate() {
        guard let coordinate = locationState.coordinate, configuration.requiresMeetupBeforeSubmit else {
            return
        }
        let updatedDraft = selectedMeetupCandidateDraft.applyingCurrentLocation(coordinate)
        applyMeetupCandidate(updatedDraft, at: selectedMeetupCandidateIndex)
    }

    private func toggleSenderGoods(_ id: UUID) {
        if selectedSenderGoodsIDs.contains(id) {
            guard selectedSenderGoodsIDs.count > 1 else {
                return
            }
            selectedSenderGoodsIDs.remove(id)
        } else {
            selectedSenderGoodsIDs.insert(id)
        }
    }

    private func toggleReceiverGoods(_ id: UUID) {
        if selectedReceiverGoodsIDs.contains(id) {
            guard selectedReceiverGoodsIDs.count > 1 else {
                return
            }
            selectedReceiverGoodsIDs.remove(id)
        } else {
            selectedReceiverGoodsIDs.insert(id)
        }
    }

    private func seedDefaultSenderSelection() {
        guard selectedSenderGoodsIDs.isEmpty else {
            return
        }
        guard proposalCashAmount == nil else {
            return
        }
        let availableIDs = Set(selectableSenderGoods.map(\.id))
        let seededIDs = initialSenderGoodsIDs.filter { availableIDs.contains($0) }
        if !seededIDs.isEmpty {
            selectedSenderGoodsIDs = Set(seededIDs)
            return
        }
        guard let firstID = selectableSenderGoods.first?.id else {
            return
        }
        selectedSenderGoodsIDs.insert(firstID)
    }

    private func seedDefaultReceiverSelection() {
        guard selectedReceiverGoodsIDs.isEmpty else {
            return
        }
        let availableIDs = Set(receiverChoiceGoods.map(\.id))
        let candidateIDs = (receiverGoodsIDs ?? [targetItem.id]).filter { availableIDs.contains($0) }
        if !candidateIDs.isEmpty {
            selectedReceiverGoodsIDs = Set(candidateIDs)
            return
        }
        if availableIDs.contains(targetItem.id) {
            selectedReceiverGoodsIDs.insert(targetItem.id)
            return
        }
        if let firstID = receiverChoiceGoods.first?.id {
            selectedReceiverGoodsIDs.insert(firstID)
        }
    }

    private func applyInitialExchangeMethodIfNeeded() {
        guard !didApplyInitialExchangeMethod else {
            return
        }
        didApplyInitialExchangeMethod = true
        guard let initialExchangeMethod else {
            return
        }
        exchangeMethod = initialExchangeMethod
    }

    private func applyInitialCashAmountIfNeeded() {
        guard proposalCashAmount == nil,
              let initialCashAmount,
              initialCashAmount > 0
        else {
            return
        }
        proposalCashAmount = initialCashAmount
    }

    private func applyVisualQAStateIfNeeded() {
        guard !didApplyVisualQAState else {
            return
        }
        didApplyVisualQAState = true
        guard visualQAInitialScreen == .proposalConfirm || visualQAInitialScreen == .proposalComplete else {
            return
        }
        seedVisualQAMeetupCandidateIfNeeded()
        message = ""
        shareSchedule = true
        selectedStep = .confirm
        if visualQAInitialScreen == .proposalComplete {
            submittedSummary = ProposalSubmittedSummary(
                senderCount: max(orderedSenderGoodsIDs.count, 1),
                receiverCount: max(resolvedReceiverGoodsIDs.count, 1),
                partnerHandle: displayPartnerHandle,
                methodTitle: Self.methodTitle(exchangeMethod),
                meetupSummary: meetupSummary,
                conditionTags: [],
                exchangeMethod: exchangeMethod
            )
        }
    }

    private func seedVisualQAMeetupCandidateIfNeeded() {
        guard configuration.requiresMeetupBeforeSubmit, meetupCandidateDrafts.isEmpty else {
            return
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current
        let start = calendar.date(from: DateComponents(year: 2026, month: 6, day: 7, hour: 16, minute: 30)) ?? Date()
        let end = start.addingTimeInterval(45 * 60)
        let draft = ProposalMeetupCandidateDraft(
            startAt: start,
            endAt: end,
            placeName: "東京ドーム 22ゲート前",
            latitudeText: "35.7056",
            longitudeText: "139.7519"
        )
        meetupCandidateDrafts = [draft]
        applyMeetupCandidate(draft, at: 0)
    }

    private func applyInitialStepIfNeeded() {
        guard !didApplyInitialStep else {
            return
        }
        guard visibleSteps.contains(initialStep) else {
            didApplyInitialStep = true
            return
        }
        if visibleSteps
            .prefix(while: { $0 != initialStep })
            .allSatisfy({ configuration.canAdvance(from: $0) })
        {
            selectedStep = initialStep
            didApplyInitialStep = true
        }
    }

    private func normalizeMeetupEnd() {
        if meetupEndAt <= meetupStartAt {
            meetupEndAt = meetupStartAt.addingTimeInterval(30 * 60)
        }
    }

    private func saveSelectedMeetupCandidate() {
        guard meetupCandidateDrafts.indices.contains(selectedMeetupCandidateIndex) else {
            return
        }
        meetupCandidateDrafts[selectedMeetupCandidateIndex] = selectedMeetupCandidateDraft
    }

    private func applyMeetupCandidate(
        _ draft: ProposalMeetupCandidateDraft,
        at index: Int,
        reanchorCalendar: Bool = true
    ) {
        selectedMeetupCandidateIndex = index
        meetupStartAt = draft.startAt
        meetupEndAt = draft.endAt
        meetupPlaceName = draft.placeName
        meetupLatitudeText = draft.latitudeText
        meetupLongitudeText = draft.longitudeText
        if reanchorCalendar {
            meetupCalendarAnchorDate = calendarAnchorDate(for: draft.startAt)
        }
        normalizeMeetupEnd()
    }

    private func selectMeetupCandidate(_ index: Int) {
        guard meetupCandidateDrafts.indices.contains(index), index != selectedMeetupCandidateIndex else {
            return
        }
        saveSelectedMeetupCandidate()
        applyMeetupCandidate(meetupCandidateDrafts[index], at: index)
    }

    private func openMeetupPlaceSheet(for index: Int) {
        guard meetupCandidateDrafts.indices.contains(index) else {
            return
        }
        saveSelectedMeetupCandidate()
        let draft = meetupCandidateDrafts[index]
        applyMeetupCandidate(draft, at: index)
        meetupPlaceSheetRoute = ProposalMeetupPlaceSheetRoute(index: index, draft: draft)
    }

    private func previousMeetupPlaceDraft(before index: Int) -> ProposalMeetupCandidateDraft? {
        let drafts = displayMeetupCandidateDrafts
        return drafts.indices
            .filter { $0 != index }
            .reversed()
            .map { drafts[$0] }
            .first { draft in
                !draft.normalizedPlaceName.isEmpty
                    || ProposalMeetupMapDraft.coordinate(
                        latitudeText: draft.latitudeText,
                        longitudeText: draft.longitudeText
                    ) != nil
            }
    }

    private func saveMeetupPlaceSheetDraft(_ draft: ProposalMeetupCandidateDraft, at index: Int) {
        guard meetupCandidateDrafts.indices.contains(index) else {
            return
        }
        meetupCandidateDrafts[index] = draft
        applyMeetupCandidate(draft, at: index)
    }

    private func addMeetupCandidate() {
        guard meetupCandidateDrafts.count < ProposalMeetupCandidateDraft.maxCandidates else {
            return
        }
        saveSelectedMeetupCandidate()
        let start = meetupEndAt.addingTimeInterval(30 * 60)
        let draft = ProposalMeetupCandidateDraft(
            startAt: start,
            placeName: meetupPlaceName,
            latitudeText: meetupLatitudeText,
            longitudeText: meetupLongitudeText
        )
        meetupCandidateDrafts.append(draft)
        let newIndex = meetupCandidateDrafts.count - 1
        applyMeetupCandidate(draft, at: newIndex)
        meetupPlaceSheetRoute = ProposalMeetupPlaceSheetRoute(index: newIndex, draft: draft)
    }

    private func removeMeetupCandidate(_ index: Int) {
        guard meetupCandidateDrafts.indices.contains(index) else {
            return
        }
        saveSelectedMeetupCandidate()
        meetupCandidateDrafts.remove(at: index)
        if meetupCandidateDrafts.isEmpty {
            selectedMeetupCandidateIndex = 0
            meetupPlaceName = ""
            meetupLatitudeText = ""
            meetupLongitudeText = ""
            meetupEndAt = meetupStartAt.addingTimeInterval(ProposalMeetupCandidateDraft.defaultDuration)
            meetupPlaceSheetRoute = nil
            return
        }
        let nextIndex: Int
        if index < selectedMeetupCandidateIndex {
            nextIndex = max(0, selectedMeetupCandidateIndex - 1)
        } else if index == selectedMeetupCandidateIndex {
            nextIndex = min(index, meetupCandidateDrafts.count - 1)
        } else {
            nextIndex = selectedMeetupCandidateIndex
        }
        applyMeetupCandidate(meetupCandidateDrafts[nextIndex], at: nextIndex)
    }

    private func previousStep() {
        guard let index = visibleSteps.firstIndex(of: selectedStep), index > 0 else {
            return
        }
        withAnimation(.snappy) {
            selectedStep = visibleSteps[index - 1]
        }
    }

    private func primaryAction() {
        if selectedStep == .confirm {
            Task {
                await createProposal()
            }
            return
        }
        guard let destination = ProposalCreatePrimaryStepDestination.destination(
            from: selectedStep,
            configuration: configuration,
            visibleSteps: visibleSteps
        ) else {
            return
        }
        withAnimation(.snappy) {
            selectedStep = destination
        }
    }

    private var stepSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .onEnded { value in
                guard selectedStep != .meetup, selectedStep != .confirm else {
                    return
                }
                guard let destination = ProposalStepSwipeNavigator.destination(
                    from: selectedStep,
                    translationWidth: value.translation.width,
                    translationHeight: value.translation.height,
                    visibleSteps: visibleSteps
                ) else {
                    return
                }
                withAnimation(.snappy) {
                    selectedStep = destination
                }
            }
    }

    private func createProposal() async {
        guard configuration.canSubmit, let targetStatus = configuration.targetStatus else {
            return
        }
        saveSelectedMeetupCandidate()
        let meetupCandidates = configuration.requiresMeetupBeforeSubmit ? meetupInputsForSubmission : []
        let meetup = meetupCandidates.first
        guard !configuration.requiresMeetupBeforeSubmit || meetup != nil else {
            return
        }
        let draft = ProposalCreateSubmissionDraft(
            receiverID: targetItem.ownerID,
            senderGoodsIDs: orderedSenderGoodsIDs,
            receiverGoodsIDs: resolvedReceiverGoodsIDs,
            exchangeMethod: exchangeMethod,
            conditionTags: [],
            message: message,
            matchType: matchType,
            status: targetStatus,
            meetupCandidates: meetupCandidates,
            exposeCalendar: shareSchedule,
            listingID: listingID,
            cashAmount: proposalCashAmount,
            senderCount: orderedSenderGoodsIDs.count,
            receiverCount: resolvedReceiverGoodsIDs.count,
            partnerHandle: partnerHandle,
            methodTitle: Self.methodTitle(exchangeMethod),
            meetupSummary: meetupSummary
        )
        let created = await appState.createProposal(draft.input)
        if created {
            withAnimation(.snappy) {
                submittedSummary = draft.summary
            }
        }
    }

    private func shiftMeetupWeek(_ direction: Int) {
        meetupCalendarAnchorDate = ProposalMeetupCalendarModel.shiftedAnchor(
            anchorDate: meetupCalendarAnchorDate,
            direction: direction
        )
    }

    private func shiftMeetupMonth(_ direction: Int) {
        meetupCalendarAnchorDate = ProposalMeetupCalendarModel.shiftedMonthAnchor(
            anchorDate: meetupCalendarAnchorDate,
            direction: direction
        )
    }

    private func selectMeetupCalendarDay(_ day: Date) {
        meetupCalendarAnchorDate = calendarAnchorDate(for: day)
    }

    private func createMeetupCandidate(day: Date, startSlot: Int, endSlot: Int) {
        let draft = ProposalMeetupCandidateDraft(
            startAt: ProposalMeetupCalendarModel.date(for: day, slot: startSlot),
            endAt: ProposalMeetupCalendarModel.date(for: day, slot: endSlot)
        )
        saveSelectedMeetupCandidate()
        if meetupCandidateDrafts.count < ProposalMeetupCandidateDraft.maxCandidates {
            meetupCandidateDrafts.append(draft)
            let newIndex = meetupCandidateDrafts.count - 1
            applyMeetupCandidate(draft, at: newIndex)
            meetupPlaceSheetRoute = ProposalMeetupPlaceSheetRoute(index: newIndex, draft: draft)
        } else if meetupCandidateDrafts.indices.contains(selectedMeetupCandidateIndex) {
            meetupCandidateDrafts[selectedMeetupCandidateIndex] = draft
            applyMeetupCandidate(draft, at: selectedMeetupCandidateIndex)
            meetupPlaceSheetRoute = ProposalMeetupPlaceSheetRoute(index: selectedMeetupCandidateIndex, draft: draft)
        }
    }

    private func updateMeetupCandidate(index: Int, day: Date, startSlot: Int, endSlot: Int) {
        guard meetupCandidateDrafts.indices.contains(index) else {
            return
        }
        let updated = meetupCandidateDrafts[index].applyingCalendarRange(
            day: day,
            startSlot: startSlot,
            endSlot: endSlot
        )
        meetupCandidateDrafts[index] = updated
        if index == selectedMeetupCandidateIndex {
            applyMeetupCandidate(updated, at: index, reanchorCalendar: false)
        }
    }

    private func calendarAnchorDate(for date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    private static func methodTitle(_ method: ExchangeMethod) -> String {
        switch method {
        case .hand:
            "現地交換"
        case .mail:
            "郵送交換"
        case .both:
            "現地 / 郵送"
        }
    }

    private static func dateText(_ date: Date) -> String {
        date.formatted(
            .dateTime
                .locale(Locale(identifier: "ja_JP"))
                .month()
                .day()
                .hour()
                .minute()
        )
    }

    private var partnerHandle: String {
        appState.publicProfilesByUserID[targetItem.ownerID]?.profile.handle ?? "相手"
    }

    private var displayPartnerHandle: String {
        visualQAInitialScreen == nil ? partnerHandle : "michilion"
    }
}
