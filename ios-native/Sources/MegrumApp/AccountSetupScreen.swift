import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

@MainActor
public struct AccountSetupScreen: View {
    @ObservedObject private var appState: MegrumAppState
    private let mode: AccountSetupMode

    @State private var step: AccountSetupStep = .welcome
    @State private var isSelectingOshiMembers = false
    @State private var oshiSearchText = ""
    @State private var selectedGenreID: UUID?
    @State private var selectedOshiGroups: [OshiGroup] = []
    @State private var selectedOshiDrafts: [OnboardingOshiDraft] = []
    @State private var charactersByGroupID: [UUID: [OshiCharacter]] = [:]
    @State private var isLoadingSelectedMembers = false
    @State private var oshiRequestSheet: OshiRequestSheetState?
    @State private var oshiMemberRequestContext: OshiMemberRequestContext?
    @State private var toastMessage: String?
    @State private var toastID = UUID()
    @State private var prefectureSearchText = ""
    @State private var displayName: String
    @State private var handle: String
    @State private var prefecture: String
    @State private var birthDate: Date
    @State private var gender: UserGender?
    @State private var setupInputErrorMessage: String?
    @FocusState private var focusedField: AccountSetupFocusedField?

    private var selectedOshiInputs: [AccountSetupOshiInput] {
        OnboardingOshiSelectionLogic.accountSetupInputs(from: selectedOshiDrafts)
    }

    private var filteredOshiGroups: [OshiGroup] {
        let normalizedSearch = oshiSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return appState.oshiGroups.filter { group in
            if let selectedGenreID, group.genreID != selectedGenreID {
                return false
            }
            guard !normalizedSearch.isEmpty else {
                return true
            }
            return ([group.name] + group.aliases).contains { candidate in
                candidate.localizedCaseInsensitiveContains(normalizedSearch)
            }
        }
    }

    private var oshiCategoryOptions: [OshiCategoryOption] {
        [OshiCategoryOption(id: nil, title: "すべて")] + appState.oshiGenres.map {
            OshiCategoryOption(id: $0.id, title: $0.name)
        }
    }

    private var selectedMemberGroups: [OshiGroup] {
        selectedOshiGroups.filter(\.supportsMemberSelection)
    }

    private var selectedMemberTargets: [OnboardingOshiMemberTarget] {
        selectedMemberGroups.map(OnboardingOshiMemberTarget.init(group:))
            + OnboardingOshiSelectionLogic.requestedMemberTargets(from: selectedOshiDrafts)
    }

    public init(appState: MegrumAppState, mode: AccountSetupMode = .onboarding) {
        self.appState = appState
        self.mode = mode
        _displayName = State(initialValue: mode == .onboarding ? "" : (appState.viewer?.displayName ?? ""))
        _handle = State(initialValue: mode == .onboarding ? "" : (appState.viewer?.handle ?? ""))
        _prefecture = State(initialValue: appState.viewer?.prefecture ?? "")
        _birthDate = State(initialValue: appState.viewer?.birthDate ?? Self.defaultBirthDate)
        _gender = State(initialValue: appState.viewer?.gender)
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
        .sheet(item: $oshiRequestSheet) { state in
            OshiRequestSheet(
                state: state,
                genres: appState.oshiGenres,
                onClose: { oshiRequestSheet = nil },
                onSubmit: submitOshiRequestTapped
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
        .sheet(item: $oshiMemberRequestContext) { context in
            OshiMemberRequestSheet(
                context: context,
                onClose: { oshiMemberRequestContext = nil },
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
            showsBackButton: step != .welcome || isSelectingOshiMembers,
            isPrimaryDisabled: appState.isSavingAccountSetup || isLoadingSelectedMembers,
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
            if let toastMessage {
                MeguriToastView(message: toastMessage)
                    .padding(.bottom, 104)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.88), value: toastMessage)
    }

    @ViewBuilder
    private var currentStepContent: some View {
        switch step {
        case .welcome:
            AccountSetupWelcomeStep()
        case .oshi:
            if isSelectingOshiMembers {
                AccountSetupOshiMemberStep(
                    targets: selectedMemberTargets,
                    selectedOshiDrafts: $selectedOshiDrafts,
                    charactersByGroupID: charactersByGroupID,
                    isLoading: isLoadingSelectedMembers || appState.isLoadingOshiCharacters,
                    errorMessage: setupInputErrorMessage ?? appState.errorMessage,
                    onClearError: clearError,
                    onRequestMember: showOshiMemberRequestSheet
                )
            } else {
                AccountSetupOshiMasterStep(
                    groups: filteredOshiGroups,
                    categoryOptions: oshiCategoryOptions,
                    selectedGenreID: $selectedGenreID,
                    searchText: $oshiSearchText,
                    selectedGroups: $selectedOshiGroups,
                    requestedDrafts: selectedOshiDrafts.filter { $0.oshiRequestID != nil },
                    isLoading: appState.isLoadingOshiGroups,
                    errorMessage: setupInputErrorMessage ?? appState.errorMessage,
                    focusedField: $focusedField,
                    onClearError: clearError,
                    onRequestOshi: showOshiRequestSheet
                )
            }
        case .area:
            AccountSetupAreaStep(
                selectedPrefecture: $prefecture,
                searchText: $prefectureSearchText,
                errorMessage: setupInputErrorMessage,
                focusedField: $focusedField,
                onClearError: clearError
            )
        case .displayName:
            AccountSetupTextInputStep(
                label: "表示名",
                placeholder: "みち",
                text: $displayName,
                focusedField: $focusedField,
                focusCase: .displayName,
                footnote: "本名や個人が特定できる情報は避けてください。あとから変更できます。",
                errorMessage: setupInputErrorMessage,
                onClearError: clearError
            )
        case .handle:
            AccountSetupTextInputStep(
                label: "ユーザーID",
                placeholder: "megrum_id",
                text: $handle,
                focusedField: $focusedField,
                focusCase: .handle,
                leadingText: "@",
                isHandleField: true,
                footnote: "半角英数字と _ の3〜20文字で設定してください。",
                errorMessage: setupInputErrorMessage,
                onClearError: clearError
            )
        case .birthDate:
            AccountSetupBirthDateStep(
                birthDate: $birthDate,
                errorMessage: setupInputErrorMessage,
                onClearError: clearError
            )
        case .gender:
            AccountSetupGenderStep(
                gender: $gender,
                errorMessage: setupInputErrorMessage,
                onClearError: clearError
            )
        case .completion:
            AccountSetupCompletionStep(
                displayName: displayName,
                handle: handle,
                prefecture: prefecture,
                birthDate: birthDate,
                gender: gender,
                selectedOshiDrafts: selectedOshiDrafts,
                isSaving: appState.isSavingAccountSetup,
                errorMessage: setupInputErrorMessage ?? appState.errorMessage
            )
        }
    }

    private var currentTitle: String {
        if step == .oshi, isSelectingOshiMembers {
            return "メンバー・キャラクターを選ぶ"
        }
        return step.title
    }

    private var currentSubtitle: String {
        if step == .oshi, isSelectingOshiMembers {
            return "選んだグループ・作品ごとにメンバー・キャラクターを設定します。全体での登録も選べます。"
        }
        return step.subtitle
    }

    private func primaryAction() {
        focusedField = nil
        switch step {
        case .welcome:
            advance(to: .oshi)
        case .oshi:
            if isSelectingOshiMembers {
                advanceFromOshiMembers()
            } else {
                Task { await advanceFromOshiMasters() }
            }
        case .area, .displayName, .handle, .birthDate, .gender:
            advanceFromValidatedStep(step)
        case .completion:
            Task { await save() }
        }
    }

    private func goBack() {
        focusedField = nil
        clearError()
        if step == .oshi, isSelectingOshiMembers {
            isSelectingOshiMembers = false
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

    private func advanceFromValidatedStep(_ validatedStep: AccountSetupStep) {
        let message = AccountSetupDraftValidator.validationMessage(
            for: validatedStep,
            displayName: displayName,
            handle: handle,
            prefecture: prefecture,
            birthDate: birthDate,
            gender: gender,
            oshiSelections: selectedOshiInputs
        )
        guard message == nil else {
            setupInputErrorMessage = message
            return
        }
        guard let next = validatedStep.next else {
            return
        }
        advance(to: next)
    }

    private func advanceFromOshiMasters() async {
        guard !selectedOshiGroups.isEmpty || !selectedOshiDrafts.isEmpty else {
            setupInputErrorMessage = AccountSetupDraftValidator.missingOshiGroupMessage
            return
        }

        seedWholeGroupDraftsForSoloGroups()

        if selectedMemberTargets.isEmpty {
            advance(to: .area)
            return
        }

        await loadCharactersForSelectedMemberGroups()
        withAnimation(.snappy(duration: 0.2)) {
            isSelectingOshiMembers = true
        }
    }

    private func advanceFromOshiMembers() {
        let incompleteTargets = selectedMemberTargets.filter { target in
            !OnboardingOshiSelectionLogic.targetHasSelection(target, in: selectedOshiDrafts)
        }
        guard incompleteTargets.isEmpty else {
            setupInputErrorMessage = AccountSetupDraftValidator.missingOshiMemberMessage
            return
        }
        guard !selectedOshiInputs.isEmpty else {
            setupInputErrorMessage = AccountSetupDraftValidator.missingOshiMessage
            return
        }
        isSelectingOshiMembers = false
        advance(to: .area)
    }

    private func save() async {
        focusedField = nil
        setupInputErrorMessage = AccountSetupDraftValidator.validationMessage(
            displayName: displayName,
            handle: handle,
            prefecture: prefecture,
            birthDate: birthDate,
            gender: gender,
            oshiSelections: selectedOshiInputs
        )
        guard setupInputErrorMessage == nil else {
            return
        }

        let completed = await appState.completeAccountSetup(
            handle: handle,
            displayName: displayName,
            prefecture: prefecture,
            birthDate: birthDate,
            gender: gender,
            oshiSelections: selectedOshiInputs
        )
        if !completed {
            setupInputErrorMessage = appState.errorMessage
        }
    }

    private func prepareInitialState() async {
        if appState.oshiGroups.isEmpty || appState.oshiGenres.isEmpty {
            await appState.loadOshiGroups()
        }
    }

    private func seedWholeGroupDraftsForSoloGroups() {
        let selectedIDs = Set(selectedOshiGroups.map(\.id))
        selectedOshiDrafts.removeAll { draft in
            guard let groupID = draft.groupID else {
                return false
            }
            return !selectedIDs.contains(groupID)
        }

        for group in selectedOshiGroups where !group.supportsMemberSelection {
            guard !OnboardingOshiSelectionLogic.isWholeGroupSelected(group, in: selectedOshiDrafts) else {
                continue
            }
            selectedOshiDrafts = OnboardingOshiSelectionLogic.toggleWholeGroup(group, in: selectedOshiDrafts)
        }
    }

    private func loadCharactersForSelectedMemberGroups() async {
        guard !isLoadingSelectedMembers else {
            return
        }
        isLoadingSelectedMembers = true
        for group in selectedMemberGroups where charactersByGroupID[group.id] == nil {
            await appState.loadOshiCharacters(group: group)
            charactersByGroupID[group.id] = appState.oshiCharacters
        }
        isLoadingSelectedMembers = false
    }

    private func showOshiRequestSheet(_ query: String) {
        focusedField = nil
        clearError()
        oshiRequestSheet = .oshi(initialName: query)
    }

    private func showOshiMemberRequestSheet(_ context: OshiMemberRequestContext) {
        focusedField = nil
        clearError()
        oshiMemberRequestContext = context
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
        oshiRequestSheet = nil
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
            setupInputErrorMessage = appState.errorMessage
            return
        }

        withAnimation(.snappy(duration: 0.2)) {
            selectedOshiDrafts.removeAll { $0.oshiRequestID == requestID }
            selectedOshiDrafts.append(
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
        oshiMemberRequestContext = nil
        let requestedName = payload.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !requestedName.isEmpty else {
            return
        }
        guard context.canCreateCharacterRequest else {
            setupInputErrorMessage = "対象の推しを確認できませんでした"
            return
        }
        guard selectedOshiDrafts.contains(where: { draft in
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
            setupInputErrorMessage = appState.errorMessage
            return
        }

        withAnimation(.snappy(duration: 0.2)) {
            selectedOshiDrafts.removeAll { draft in
                draft.groupID == context.groupID
                    && draft.oshiRequestID == context.oshiRequestID
                    && draft.characterID == nil
                    && draft.characterRequestID == nil
            }
            if let groupID = context.groupID {
                selectedOshiDrafts.append(
                    OnboardingOshiDraft(
                        groupID: groupID,
                        groupName: context.groupName,
                        characterRequestID: requestID,
                        requestedCharacterName: requestedName
                    )
                )
            } else if let oshiRequestID = context.oshiRequestID {
                selectedOshiDrafts.append(
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
        setupInputErrorMessage = nil
    }

    private func showToast(_ message: String) {
        let nextToastID = UUID()
        toastID = nextToastID
        toastMessage = message
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            guard toastID == nextToastID else {
                return
            }
            toastMessage = nil
        }
    }

    private static var defaultBirthDate: Date {
        ProfileBirthDateCodec.date(from: "2000-01-01") ?? Date()
    }
}
