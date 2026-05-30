import MegrumCore
import MegrumDesign
import SwiftUI

@MainActor
public struct AccountSetupScreen: View {
    @ObservedObject private var appState: MegrumAppState
    @State private var displayName: String
    @State private var prefecture: String
    @State private var groupSearchText = ""
    @State private var selectedGroup: OshiGroup?
    @State private var selectedCharacter: OshiCharacter?
    @FocusState private var focusedField: Field?

    public init(appState: MegrumAppState) {
        self.appState = appState
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
        .navigationTitle("プロフィール設定")
        .megrumInlineNavigationTitle()
        .task {
            if appState.oshiGroups.isEmpty {
                await appState.loadOshiGroups()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Megrumへようこそ")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Text("まずはアプリ内で表示する名前と都道府県を設定します")
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
                    Text("グループを選び、必要ならメンバーも選択します")
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

            if let selectedGroup {
                VStack(alignment: .leading, spacing: 10) {
                    Text("\(selectedGroup.name) のメンバー")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)

                    Button {
                        selectedCharacter = nil
                    } label: {
                        HStack {
                            Text("グループ全体")
                            Spacer()
                            if selectedCharacter == nil {
                                Image(systemName: "checkmark.circle.fill")
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 14)
                    .frame(height: 48)
                    .background(selectedCharacter == nil ? MegrumTheme.lavender.opacity(0.16) : Color.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(selectedCharacter == nil ? MegrumTheme.lavender : MegrumTheme.ink)

                    oshiCharacterScroller
                }
            }
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
                    oshiChip(
                        title: group.name,
                        systemImage: selectedGroup?.id == group.id ? "checkmark.circle.fill" : "sparkle",
                        isSelected: selectedGroup?.id == group.id
                    ) {
                        selectedGroup = group
                        selectedCharacter = nil
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
                    oshiChip(
                        title: character.name,
                        systemImage: selectedCharacter?.id == character.id ? "checkmark.circle.fill" : "person.crop.circle",
                        isSelected: selectedCharacter?.id == character.id
                    ) {
                        selectedCharacter = character
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

    private var saveButton: some View {
        Button {
            Task { await save() }
        } label: {
            HStack(spacing: 10) {
                if appState.isSavingAccountSetup {
                    ProgressView()
                        .controlSize(.small)
                }
                Text("設定を完了する")
                    .font(.system(size: 16, weight: .black, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.roundedRectangle(radius: 18))
        .tint(MegrumTheme.lavender)
        .disabled(appState.isSavingAccountSetup || displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedGroup == nil)
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
        guard let selectedGroup else {
            return []
        }
        return [
            AccountSetupOshiInput(
                groupID: selectedGroup.id,
                characterID: selectedCharacter?.id,
                kind: selectedCharacter == nil ? .box : .specific,
                priority: 1
            )
        ]
    }

    private enum Field {
        case displayName
        case prefecture
        case groupSearch
    }
}
