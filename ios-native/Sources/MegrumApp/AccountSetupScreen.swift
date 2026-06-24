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
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("推しを選ぶ")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    Text("グループやメンバーを複数選べます")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }
                Spacer()
                if appState.isLoadingOshiGroups || appState.isLoadingOshiCharacters || appState.isLoadingUserOshiSelections {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            TextField("グループ名で検索", text: $groupSearchText)
                .focused($focusedField, equals: .groupSearch)
                .submitLabel(.search)
                .onSubmit {
                    Task { await appState.loadOshiGroups(searchText: groupSearchText) }
                }
                .megrumTextFieldStyle()
                .accessibilityLabel("推しグループ検索")
                .accessibilityHint("グループ名で候補を絞り込みます")

            oshiGroupScroller

            if let activeGroup {
                VStack(alignment: .leading, spacing: 10) {
                    Text("\(activeGroup.name) のメンバー")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)

                    Button {
                        setupInputErrorMessage = nil
                        selectedOshiDrafts = OnboardingOshiSelectionLogic.toggleWholeGroup(
                            activeGroup,
                            in: selectedOshiDrafts
                        )
                    } label: {
                        HStack {
                            Text("グループ全体")
                            Spacer()
                            if isWholeGroupSelected(activeGroup) {
                                Image(systemName: "checkmark.circle.fill")
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 14)
                    .frame(height: 48)
                    .background(isWholeGroupSelected(activeGroup) ? MegrumTheme.lavender.opacity(0.16) : Color.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(isWholeGroupSelected(activeGroup) ? MegrumTheme.lavender : MegrumTheme.ink)
                    .accessibilityLabel("\(activeGroup.name) 全体")
                    .accessibilityValue(isWholeGroupSelected(activeGroup) ? "選択済み" : "未選択")
                    .accessibilityHint("タップするとグループ全体の選択を切り替えます")

                    oshiCharacterScroller
                }
            }

            selectedOshiSummary
        }
        .padding(18)
        .background(Color.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(Color.white.opacity(0.84), lineWidth: 1)
        )
    }

    private var oshiGroupScroller: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(appState.oshiGroups) { group in
                    let hasSelection = OnboardingOshiSelectionLogic.groupHasSelection(group, in: selectedOshiDrafts)
                    oshiChip(
                        title: group.name,
                        systemImage: hasSelection ? "checkmark.circle.fill" : "sparkle",
                        isSelected: activeGroup?.id == group.id || hasSelection,
                        accessibilityHint: "タップするとこのグループのメンバー選択を表示します"
                    ) {
                        setupInputErrorMessage = nil
                        activeGroup = group
                        Task { await appState.loadOshiCharacters(group: group) }
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var oshiCharacterScroller: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(appState.oshiCharacters) { character in
                    let isSelected = OnboardingOshiSelectionLogic.isCharacterSelected(character, in: selectedOshiDrafts)
                    oshiChip(
                        title: character.name,
                        systemImage: isSelected ? "checkmark.circle.fill" : "person.crop.circle",
                        isSelected: isSelected,
                        accessibilityHint: isSelected ? "タップするとこのメンバーを選択から外します" : "タップするとこのメンバーを推しに追加します"
                    ) {
                        guard let activeGroup else {
                            return
                        }
                        setupInputErrorMessage = nil
                        selectedOshiDrafts = OnboardingOshiSelectionLogic.toggleCharacter(
                            character,
                            group: activeGroup,
                            in: selectedOshiDrafts
                        )
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func oshiChip(
        title: String,
        systemImage: String,
        isSelected: Bool,
        accessibilityHint: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .lineLimit(1)
                .padding(.horizontal, 14)
                .frame(height: 42)
                .background(isSelected ? MegrumTheme.lavender : Color.white.opacity(0.88), in: Capsule())
                .foregroundStyle(isSelected ? Color.white : MegrumTheme.ink)
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? Color.white.opacity(0.35) : MegrumTheme.lavender.opacity(0.18), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityLabel(title)
        .accessibilityValue(isSelected ? "選択済み" : "未選択")
        .accessibilityHint(accessibilityHint)
    }

    private var selectedOshiSummary: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("選択中")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            if selectedOshiDrafts.isEmpty {
                Text("まだ選択されていません")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 16))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(selectedOshiDrafts) { draft in
                            Button {
                                setupInputErrorMessage = nil
                                selectedOshiDrafts.removeAll { $0.id == draft.id }
                            } label: {
                                Label(draft.displayName, systemImage: "xmark.circle.fill")
                                    .font(.system(size: 13, weight: .black, design: .rounded))
                                    .lineLimit(1)
                                    .padding(.horizontal, 12)
                                    .frame(height: 34)
                                    .background(MegrumTheme.lavender.opacity(0.14), in: Capsule())
                                    .foregroundStyle(MegrumTheme.lavender)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(draft.displayName)を選択から外す")
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
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

    private func isWholeGroupSelected(_ group: OshiGroup) -> Bool {
        OnboardingOshiSelectionLogic.isWholeGroupSelected(group, in: selectedOshiDrafts)
    }
}
