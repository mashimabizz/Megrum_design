import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

@MainActor
public struct AccountSetupScreen: View {
    @ObservedObject private var appState: MegrumAppState
    private let mode: AccountSetupMode

    @State private var step: AccountSetupStep = .welcome
    @State private var oshiState = AccountSetupOshiState()
    @State private var profileState: AccountSetupProfileState
    @State private var toastState = AccountSetupToastState()
    /// iter1226.422：ユーザーID重複チェック中フラグと代替候補（タップで採用）。
    @State private var isCheckingHandleAvailability = false
    @State private var handleSuggestions: [String] = []
    @FocusState private var focusedField: AccountSetupFocusedField?

    private var oshiPresentationState: AccountSetupOshiPresentationState {
        AccountSetupOshiPresentationState(
            groups: appState.oshiGroups,
            genres: appState.oshiGenres,
            selectedGenreID: oshiState.selectedGenreID,
            searchText: oshiState.searchText,
            selectedGroups: oshiState.selectedGroups,
            selectedDrafts: oshiState.selectedDrafts
        )
    }

    private var selectedOshiInputs: [AccountSetupOshiInput] {
        oshiPresentationState.selectedInputs
    }

    private var filteredOshiGroups: [OshiGroup] {
        oshiPresentationState.filteredGroups
    }

    private var oshiCategoryOptions: [OshiCategoryOption] {
        oshiPresentationState.categoryOptions
    }

    private var selectedMemberGroups: [OshiGroup] {
        oshiPresentationState.selectedMemberGroups
    }

    private var selectedMemberTargets: [OnboardingOshiMemberTarget] {
        oshiPresentationState.selectedMemberTargets
    }

    public init(appState: MegrumAppState, mode: AccountSetupMode = .onboarding) {
        self.appState = appState
        self.mode = mode
        _profileState = State(
            initialValue: AccountSetupProfileState(
                displayName: mode == .onboarding ? "" : (appState.viewer?.displayName ?? ""),
                handle: mode == .onboarding ? "" : (appState.viewer?.handle ?? ""),
                prefecture: appState.viewer?.prefecture ?? "",
                birthDate: appState.viewer?.birthDate ?? Self.defaultBirthDate,
                gender: AccountSetupGenderOptions.contains(appState.viewer?.gender) ? appState.viewer?.gender : nil
            )
        )
    }

    public var body: some View {
        Group {
            if mode == .edit {
                OshiSettingsScreen(appState: appState)
            } else {
                onboardingFlow
            }
        }
        .task {
            await prepareInitialState()
        }
        .sheet(item: $oshiState.requestSheet) { state in
            OshiRequestSheet(
                state: state,
                genres: appState.oshiGenres,
                onClose: { oshiState.requestSheet = nil },
                onSubmit: submitOshiRequestTapped
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
        .sheet(item: $oshiState.memberRequestContext) { context in
            OshiMemberRequestSheet(
                context: context,
                onClose: { oshiState.memberRequestContext = nil },
                onSubmit: { payload in
                    submitOshiMemberRequestTapped(payload, context: context)
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.hidden)
        }
    }

    private var onboardingFlow: some View {
        AccountSetupStepContainer(
            step: step,
            title: currentTitle,
            subtitle: currentSubtitle,
            showsBackButton: step != .welcome || oshiState.isSelectingMembers,
            isPrimaryDisabled: appState.isSavingAccountSetup || oshiState.isLoadingSelectedMembers,
            primaryTitle: step.primaryButtonTitle,
            onBack: goBack,
            onPrimary: primaryAction
        ) {
            currentStepContent
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .megrumHiddenNavigationBar()
        .scrollDismissesKeyboard(.interactively)
        .overlay(alignment: .bottom) {
            if let toastMessage = toastState.message {
                MeguriToastView(message: toastMessage)
                    .padding(.bottom, 104)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.88), value: toastState.message)
    }

    @ViewBuilder
    private var currentStepContent: some View {
        AccountSetupStepContent(
            step: step,
            isSelectingOshiMembers: oshiState.isSelectingMembers,
            selectedMemberTargets: selectedMemberTargets,
            selectedOshiDrafts: $oshiState.selectedDrafts,
            charactersByGroupID: oshiState.charactersByGroupID,
            isLoadingSelectedMembers: oshiState.isLoadingSelectedMembers,
            isLoadingOshiCharacters: appState.isLoadingOshiCharacters,
            groups: filteredOshiGroups,
            categoryOptions: oshiCategoryOptions,
            selectedGenreID: $oshiState.selectedGenreID,
            oshiSearchText: $oshiState.searchText,
            selectedOshiGroups: $oshiState.selectedGroups,
            isLoadingOshiGroups: appState.isLoadingOshiGroups,
            selectedPrefecture: $profileState.prefecture,
            prefectureSearchText: $profileState.prefectureSearchText,
            displayName: $profileState.displayName,
            handle: $profileState.handle,
            handleSuggestions: handleSuggestions,
            onSelectHandleSuggestion: { suggestion in
                profileState.handle = suggestion
                handleSuggestions = []
                clearError()
            },
            birthDate: $profileState.birthDate,
            gender: $profileState.gender,
            isSaving: appState.isSavingAccountSetup,
            setupErrorMessage: profileState.inputErrorMessage,
            appErrorMessage: appState.errorMessage,
            focusedField: $focusedField,
            onClearError: clearError,
            onRequestOshi: showOshiRequestSheet,
            onRequestMember: showOshiMemberRequestSheet
        )
    }

    private var currentTitle: String {
        if step == .oshi, oshiState.isSelectingMembers {
            return "メンバー・キャラクターを選ぶ"
        }
        return step.title
    }

    private var currentSubtitle: String {
        if step == .oshi, oshiState.isSelectingMembers {
            return "推しのメンバー・キャラクターを選びます。選ばなければグループ・作品全体で登録されます。"
        }
        return step.subtitle
    }

    private func primaryAction() {
        focusedField = nil
        switch step {
        case .welcome:
            advance(to: .oshi)
        case .oshi:
            if oshiState.isSelectingMembers {
                advanceFromOshiMembers()
            } else {
                Task { await advanceFromOshiMasters() }
            }
        case .handle:
            Task { await advanceFromHandleStep() }
        case .area, .displayName, .birthDate, .gender:
            advanceFromValidatedStep(step)
        case .completion:
            Task { await save() }
        }
    }

    private func goBack() {
        focusedField = nil
        clearError()
        if step == .oshi, oshiState.isSelectingMembers {
            oshiState.isSelectingMembers = false
            return
        }
        if let previous = step.previous {
            advance(to: previous)
        }
    }

    private func advance(to nextStep: AccountSetupStep) {
        clearError()
        withAnimation(.snappy(duration: 0.22)) {
            step = nextStep
        }
    }

    /// iter1226.422：ユーザーIDは進む前に重複チェック。重複ならNG＋空いている候補を提示する。
    private func advanceFromHandleStep() async {
        let message = profileState.draft.validationMessage(
            for: .handle,
            oshiSelections: selectedOshiInputs
        )
        guard message == nil else {
            profileState.inputErrorMessage = message
            return
        }
        isCheckingHandleAvailability = true
        let availability = await appState.checkAccountHandleAvailability(profileState.handle)
        isCheckingHandleAvailability = false
        if let availability, !availability.isAvailable {
            profileState.inputErrorMessage = MegrumAppState.handleTakenErrorMessage
            handleSuggestions = availability.suggestions
            return
        }
        handleSuggestions = []
        guard let next = AccountSetupStep.handle.next else {
            return
        }
        advance(to: next)
    }

    private func advanceFromValidatedStep(_ validatedStep: AccountSetupStep) {
        let message = profileState.draft.validationMessage(
            for: validatedStep,
            oshiSelections: selectedOshiInputs
        )
        guard message == nil else {
            profileState.inputErrorMessage = message
            return
        }
        guard let next = validatedStep.next else {
            return
        }
        advance(to: next)
    }

    private func advanceFromOshiMasters() async {
        guard !oshiState.selectedGroups.isEmpty || !oshiState.selectedDrafts.isEmpty else {
            profileState.inputErrorMessage = AccountSetupDraftValidator.missingOshiGroupMessage
            return
        }

        seedWholeGroupDraftsForSoloGroups()

        if selectedMemberTargets.isEmpty {
            advance(to: .area)
            return
        }

        await loadCharactersForSelectedMemberGroups()
        withAnimation(.snappy(duration: 0.2)) {
            oshiState.isSelectingMembers = true
        }
    }

    private func advanceFromOshiMembers() {
        // FB(iter1226.422)：メンバー未選択でも次へ進める。未選択のグループは「グループ全体」として登録する。
        oshiState.selectedDrafts = OnboardingOshiSelectionLogic.draftsFillingWholeGroupForUnselected(
            selectedGroups: oshiState.selectedGroups,
            currentDrafts: oshiState.selectedDrafts
        )
        guard !selectedOshiInputs.isEmpty else {
            profileState.inputErrorMessage = AccountSetupDraftValidator.missingOshiMessage
            return
        }
        oshiState.isSelectingMembers = false
        advance(to: .area)
    }

    private func save() async {
        focusedField = nil
        let draft = profileState.draft
        profileState.inputErrorMessage = draft.validationMessage(oshiSelections: selectedOshiInputs)
        guard profileState.inputErrorMessage == nil else {
            return
        }

        let completed = await appState.completeAccountSetup(
            draft.accountSetupInput(oshiSelections: selectedOshiInputs)
        )
        if !completed {
            profileState.inputErrorMessage = appState.errorMessage
            // 重複IDで弾かれたらID入力ステップへ戻し、候補を出す（iter1226.422）。
            if appState.errorMessage == MegrumAppState.handleTakenErrorMessage {
                handleSuggestions = appState.accountSetupHandleSuggestions
                advance(to: .handle)
                profileState.inputErrorMessage = MegrumAppState.handleTakenErrorMessage
            }
        }
    }

    private func prepareInitialState() async {
        if appState.oshiGroups.isEmpty || appState.oshiGenres.isEmpty {
            await appState.loadOshiGroups()
        }
    }

    private func seedWholeGroupDraftsForSoloGroups() {
        oshiState.selectedDrafts = OnboardingOshiSelectionLogic.draftsAfterSeedingWholeGroupSelections(
            selectedGroups: oshiState.selectedGroups,
            currentDrafts: oshiState.selectedDrafts
        )
    }

    private func loadCharactersForSelectedMemberGroups() async {
        guard !oshiState.isLoadingSelectedMembers else {
            return
        }
        oshiState.isLoadingSelectedMembers = true
        for group in selectedMemberGroups where oshiState.charactersByGroupID[group.id] == nil {
            await appState.loadOshiCharacters(group: group)
            oshiState.charactersByGroupID[group.id] = appState.oshiCharacters
        }
        oshiState.isLoadingSelectedMembers = false
    }

    private func showOshiRequestSheet(_ query: String) {
        focusedField = nil
        clearError()
        oshiState.requestSheet = .oshi(initialName: query)
    }

    private func showOshiMemberRequestSheet(_ context: OshiMemberRequestContext) {
        focusedField = nil
        clearError()
        oshiState.memberRequestContext = context
    }

    private func submitOshiRequestTapped(_ payload: OshiRequestSheetPayload) {
        Task { await submitOshiRequest(payload) }
    }

    private func submitOshiMemberRequestTapped(
        _ payload: OshiMemberRequestSheetPayload,
        context: OshiMemberRequestContext
    ) {
        Task { await submitOshiMemberRequest(payload, context: context) }
    }

    private func submitOshiRequest(_ payload: OshiRequestSheetPayload) async {
        oshiState.requestSheet = nil
        let requestedName = payload.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !requestedName.isEmpty else {
            return
        }
        guard let requestID = await appState.createOshiRequest(
            OshiRequestCreateInput(
                requestedName: requestedName,
                requestedKind: payload.kind,
                requestedGenreID: payload.genreID,
                note: payload.note
            )
        ) else {
            profileState.inputErrorMessage = appState.errorMessage
            return
        }

        withAnimation(.snappy(duration: 0.2)) {
            oshiState.selectedDrafts.removeAll { $0.oshiRequestID == requestID }
            oshiState.selectedDrafts.append(
                OnboardingOshiDraft(
                    oshiRequestID: requestID,
                    requestedName: requestedName,
                    requestedKind: payload.kind
                )
            )
        }
        clearError()
        showToast("「\(requestedName)」を追加リクエストしました")
    }

    private func submitOshiMemberRequest(
        _ payload: OshiMemberRequestSheetPayload,
        context: OshiMemberRequestContext
    ) async {
        oshiState.memberRequestContext = nil
        let requestedName = payload.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !requestedName.isEmpty else {
            return
        }
        guard context.canCreateCharacterRequest else {
            profileState.inputErrorMessage = "対象の推しを確認できませんでした"
            return
        }
        guard oshiState.selectedDrafts.contains(where: { draft in
            draft.groupID == context.groupID
                && draft.oshiRequestID == context.oshiRequestID
                && draft.characterName?.compare(
                    requestedName,
                    options: [.caseInsensitive, .widthInsensitive, .diacriticInsensitive]
                ) == .orderedSame
        }) == false else {
            showToast("「\(requestedName)」は追加リクエスト済みです")
            return
        }
        guard let requestID = await appState.createCharacterRequest(
            CharacterRequestCreateInput(
                groupID: context.groupID,
                oshiRequestID: context.oshiRequestID,
                requestedName: requestedName,
                note: payload.note
            )
        ) else {
            profileState.inputErrorMessage = appState.errorMessage
            return
        }

        withAnimation(.snappy(duration: 0.2)) {
            oshiState.selectedDrafts.removeAll { draft in
                draft.groupID == context.groupID
                    && draft.oshiRequestID == context.oshiRequestID
                    && draft.characterID == nil
                    && draft.characterRequestID == nil
            }
            if let groupID = context.groupID {
                oshiState.selectedDrafts.append(
                    OnboardingOshiDraft(
                        groupID: groupID,
                        groupName: context.groupName,
                        characterRequestID: requestID,
                        requestedCharacterName: requestedName
                    )
                )
            } else if let oshiRequestID = context.oshiRequestID {
                oshiState.selectedDrafts.append(
                    OnboardingOshiDraft(
                        oshiRequestID: oshiRequestID,
                        requestedName: context.groupName,
                        characterRequestID: requestID,
                        requestedCharacterName: requestedName
                    )
                )
            }
        }
        clearError()
        showToast("「\(requestedName)」をメンバー・キャラクターとして追加リクエストしました")
    }

    private func clearError() {
        profileState.inputErrorMessage = nil
    }

    private func showToast(_ message: String) {
        let nextToastID = UUID()
        toastState.showToast(message, id: nextToastID)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            toastState.clearToast(ifMatching: nextToastID)
        }
    }

    private static var defaultBirthDate: Date {
        ProfileBirthDateCodec.date(from: "2000-01-01") ?? Date()
    }
}
