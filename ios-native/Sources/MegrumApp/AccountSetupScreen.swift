import MegrumCore
import MegrumDesign
import SwiftUI

@MainActor
public struct AccountSetupScreen: View {
    @ObservedObject private var appState: MegrumAppState
    private let mode: AccountSetupMode
    @State private var displayName: String
    @State private var prefecture: String
    @State private var groupSearchText = ""
    @State private var activeGroup: OshiGroup?
    @State private var selectedOshiDrafts: [OnboardingOshiDraft] = []
    @State private var didSeedEditSelections = false
    @State private var showsCompletionAlert = false
    @State private var setupInputErrorMessage: String?
    @FocusState private var focusedField: AccountSetupFocusedField?

    public init(appState: MegrumAppState, mode: AccountSetupMode = .onboarding) {
        self.appState = appState
        self.mode = mode
        _displayName = State(initialValue: appState.viewer?.displayName ?? "")
        _prefecture = State(initialValue: appState.viewer?.prefecture ?? "")
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                form
                oshiSection
                saveButton
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 42)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(mode.navigationTitle)
        .megrumInlineNavigationTitle()
        .alert(mode.completionTitle, isPresented: $showsCompletionAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(mode.completionMessage)
        }
        .task {
            await prepareInitialOshiState()
        }
    }

    private var header: some View {
        AccountSetupHeader(mode: mode)
    }

    private var form: some View {
        AccountSetupProfileForm(
            displayName: $displayName,
            prefecture: $prefecture,
            setupInputErrorMessage: $setupInputErrorMessage,
            focusedField: $focusedField,
            appErrorMessage: appState.errorMessage,
            onSubmit: saveFromForm
        )
    }

    private var oshiSection: some View {
        AccountSetupOshiSection(
            groupSearchText: $groupSearchText,
            activeGroup: $activeGroup,
            selectedOshiDrafts: $selectedOshiDrafts,
            setupInputErrorMessage: $setupInputErrorMessage,
            focusedField: $focusedField,
            oshiGroups: appState.oshiGroups,
            oshiCharacters: appState.oshiCharacters,
            isLoading: appState.isLoadingOshiGroups || appState.isLoadingOshiCharacters || appState.isLoadingUserOshiSelections,
            onSearchSubmit: { searchText in
                Task { await appState.loadOshiGroups(searchText: searchText) }
            },
            onSelectGroup: { group in
                Task { await appState.loadOshiCharacters(group: group) }
            }
        )
    }

    private var saveButton: some View {
        AccountSetupSaveSection(
            mode: mode,
            isSaving: appState.isSavingAccountSetup,
            onSave: saveFromForm
        )
    }

    private func saveFromForm() {
        Task { await save() }
    }

    private func save() async {
        focusedField = nil
        setupInputErrorMessage = AccountSetupDraftValidator.validationMessage(
            displayName: displayName,
            oshiSelections: selectedOshiInputs
        )
        guard setupInputErrorMessage == nil else {
            return
        }

        let completed = await appState.completeAccountSetup(
            displayName: displayName,
            prefecture: prefecture,
            oshiSelections: selectedOshiInputs
        )
        if completed {
            setupInputErrorMessage = nil
        }
        if completed, mode == .edit {
            showsCompletionAlert = true
        }
    }

    private var selectedOshiInputs: [AccountSetupOshiInput] {
        OnboardingOshiSelectionLogic.accountSetupInputs(from: selectedOshiDrafts)
    }

    private func prepareInitialOshiState() async {
        if appState.oshiGroups.isEmpty {
            await appState.loadOshiGroups()
        }

        guard mode == .edit else {
            return
        }

        await appState.loadUserOshiSelections()

        if activeGroup == nil,
           let selectionGroupID = appState.userOshiSelections.first(where: { $0.groupID != nil })?.groupID,
           let group = appState.oshiGroups.first(where: { $0.id == selectionGroupID }) {
            activeGroup = group
            await appState.loadOshiCharacters(group: group)
        }

        seedEditSelectionsIfNeeded()
    }

    private func seedEditSelectionsIfNeeded() {
        guard mode == .edit,
              !didSeedEditSelections,
              selectedOshiDrafts.isEmpty,
              !appState.userOshiSelections.isEmpty else {
            return
        }

        selectedOshiDrafts = OnboardingOshiSelectionLogic.drafts(
            from: appState.userOshiSelections,
            groups: appState.oshiGroups,
            characters: appState.oshiCharacters
        )
        didSeedEditSelections = true
    }
}
