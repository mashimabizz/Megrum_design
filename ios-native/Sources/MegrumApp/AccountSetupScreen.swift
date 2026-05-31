import MegrumCore
import MegrumDesign
import SwiftUI

public enum AccountSetupMode: Sendable {
    case onboarding
    case edit

    var headerTitle: String {
        switch self {
        case .onboarding:
            "Megrumへようこそ"
        case .edit:
            "プロフィールを整える"
        }
    }

    var headerSubtitle: String {
        switch self {
        case .onboarding:
            "まずはアプリ内で表示する名前、活動エリア、推しを設定します"
        case .edit:
            "表示名、活動エリア、推し設定をまとめて更新できます"
        }
    }

    var navigationTitle: String {
        switch self {
        case .onboarding:
            "プロフィール設定"
        case .edit:
            "プロフィール編集"
        }
    }

    var saveTitle: String {
        switch self {
        case .onboarding:
            "設定を完了する"
        case .edit:
            "プロフィールを更新する"
        }
    }
}

@MainActor
public struct AccountSetupScreen: View {
    @ObservedObject private var appState: MegrumAppState
    private let mode: AccountSetupMode
    @State private var displayName: String
    @State private var prefecture: String
    @State private var groupSearchText = ""
    @State private var activeGroup: OshiGroup?
    @State private var selectedOshiDrafts: [OnboardingOshiDraft] = []
    @FocusState private var focusedField: Field?

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
        .task {
            if appState.oshiGroups.isEmpty {
                await appState.loadOshiGroups()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(mode.headerTitle)
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Text(mode.headerSubtitle)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var form: some View {
        VStack(spacing: 16) {
            TextField("表示名", text: $displayName)
                .focused($focusedField, equals: .displayName)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .prefecture
                }
                .megrumTextFieldStyle()

            TextField("都道府県", text: $prefecture)
                .focused($focusedField, equals: .prefecture)
                .submitLabel(.done)
                .onSubmit {
                    Task { await save() }
                }
                .megrumTextFieldStyle()

            if let errorMessage = appState.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.851, green: 0.51, blue: 0.42))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color(red: 0.851, green: 0.51, blue: 0.42).opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
            }
        }
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
                if appState.isLoadingOshiGroups || appState.isLoadingOshiCharacters {
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

            oshiGroupScroller

            if let activeGroup {
                VStack(alignment: .leading, spacing: 10) {
                    Text("\(activeGroup.name) のメンバー")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)

                    Button {
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
                        isSelected: activeGroup?.id == group.id || hasSelection
                    ) {
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
                        isSelected: isSelected
                    ) {
                        guard let activeGroup else {
                            return
                        }
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
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private var saveButton: some View {
        Button {
            Task { await save() }
        } label: {
            HStack(spacing: 10) {
                if appState.isSavingAccountSetup {
                    ProgressView()
                        .controlSize(.small)
                }
                Text(mode.saveTitle)
                    .font(.system(size: 16, weight: .black, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.roundedRectangle(radius: 18))
        .tint(MegrumTheme.lavender)
        .disabled(appState.isSavingAccountSetup || displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedOshiDrafts.isEmpty)
    }

    private func save() async {
        focusedField = nil
        _ = await appState.completeAccountSetup(
            displayName: displayName,
            prefecture: prefecture,
            oshiSelections: selectedOshiInputs
        )
    }

    private var selectedOshiInputs: [AccountSetupOshiInput] {
        OnboardingOshiSelectionLogic.accountSetupInputs(from: selectedOshiDrafts)
    }

    private func isWholeGroupSelected(_ group: OshiGroup) -> Bool {
        OnboardingOshiSelectionLogic.isWholeGroupSelected(group, in: selectedOshiDrafts)
    }

    private enum Field {
        case displayName
        case prefecture
        case groupSearch
    }
}
