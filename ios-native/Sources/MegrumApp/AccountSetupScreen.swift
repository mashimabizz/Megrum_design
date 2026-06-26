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

    public init(appState: MegrumAppState, mode: AccountSetupMode = .onboarding) {
        self.appState = appState
        self.mode = mode
        _displayName = State(initialValue: appState.viewer?.displayName ?? "")
        _handle = State(initialValue: appState.viewer?.handle ?? "")
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
    }

    @ViewBuilder
    private var currentStepContent: some View {
        switch step {
        case .welcome:
            AccountSetupWelcomeStep()
        case .oshi:
            if isSelectingOshiMembers {
                AccountSetupOshiMemberStep(
                    selectedGroups: selectedMemberGroups,
                    selectedOshiDrafts: $selectedOshiDrafts,
                    charactersByGroupID: charactersByGroupID,
                    isLoading: isLoadingSelectedMembers || appState.isLoadingOshiCharacters,
                    errorMessage: setupInputErrorMessage ?? appState.errorMessage,
                    onClearError: clearError
                )
            } else {
                AccountSetupOshiMasterStep(
                    groups: filteredOshiGroups,
                    categoryOptions: oshiCategoryOptions,
                    selectedGenreID: $selectedGenreID,
                    searchText: $oshiSearchText,
                    selectedGroups: $selectedOshiGroups,
                    isLoading: appState.isLoadingOshiGroups,
                    errorMessage: setupInputErrorMessage ?? appState.errorMessage,
                    focusedField: $focusedField,
                    onClearError: clearError
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
            return "推しメンバーを選ぶ"
        }
        return step.title
    }

    private var currentSubtitle: String {
        if step == .oshi, isSelectingOshiMembers {
            return "選んだ推しマスタごとにメンバーを設定します。箱推しも選べます。"
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
        guard !selectedOshiGroups.isEmpty else {
            setupInputErrorMessage = AccountSetupDraftValidator.missingL1OshiMessage
            return
        }

        seedWholeGroupDraftsForSoloGroups()

        if selectedMemberGroups.isEmpty {
            advance(to: .area)
            return
        }

        await loadCharactersForSelectedMemberGroups()
        withAnimation(.snappy(duration: 0.2)) {
            isSelectingOshiMembers = true
        }
    }

    private func advanceFromOshiMembers() {
        let incompleteGroups = selectedMemberGroups.filter { group in
            !OnboardingOshiSelectionLogic.groupHasSelection(group, in: selectedOshiDrafts)
        }
        guard incompleteGroups.isEmpty else {
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
        selectedOshiDrafts.removeAll { !selectedIDs.contains($0.groupID) }

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

    private func clearError() {
        setupInputErrorMessage = nil
    }

    private static var defaultBirthDate: Date {
        ProfileBirthDateCodec.date(from: "2000-01-01") ?? Date()
    }
}
