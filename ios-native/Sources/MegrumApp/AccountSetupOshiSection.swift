import MegrumCore
import MegrumDesign
import SwiftUI

struct AccountSetupOshiSection: View {
    @Binding var groupSearchText: String
    @Binding var activeGroup: OshiGroup?
    @Binding var selectedOshiDrafts: [OnboardingOshiDraft]
    @Binding var setupInputErrorMessage: String?
    @FocusState.Binding var focusedField: AccountSetupFocusedField?
    var oshiGroups: [OshiGroup]
    var oshiCharacters: [OshiCharacter]
    var isLoading: Bool
    var onSearchSubmit: (String) -> Void
    var onSelectGroup: (OshiGroup) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            searchField
            oshiGroupScroller
            activeGroupMembers
            selectedOshiSummary
        }
        .padding(18)
        .background(Color.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(Color.white.opacity(0.84), lineWidth: 1)
        )
    }

    private var header: some View {
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
            if isLoading {
                ProgressView()
                    .controlSize(.small)
            }
        }
    }

    private var searchField: some View {
        TextField("グループ名で検索", text: $groupSearchText)
            .focused($focusedField, equals: .groupSearch)
            .submitLabel(.search)
            .onSubmit {
                onSearchSubmit(groupSearchText)
            }
            .megrumTextFieldStyle()
            .accessibilityLabel("推しグループ検索")
            .accessibilityHint("グループ名で候補を絞り込みます")
    }

    private var oshiGroupScroller: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(oshiGroups) { group in
                    let hasSelection = OnboardingOshiSelectionLogic.groupHasSelection(group, in: selectedOshiDrafts)
                    oshiChip(
                        title: group.name,
                        systemImage: hasSelection ? "checkmark.circle.fill" : "sparkle",
                        isSelected: activeGroup?.id == group.id || hasSelection,
                        accessibilityHint: "タップするとこのグループのメンバー選択を表示します"
                    ) {
                        setupInputErrorMessage = nil
                        activeGroup = group
                        onSelectGroup(group)
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    @ViewBuilder
    private var activeGroupMembers: some View {
        if let activeGroup {
            VStack(alignment: .leading, spacing: 10) {
                Text("\(activeGroup.name) のメンバー")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)

                wholeGroupButton(activeGroup)
                oshiCharacterScroller
            }
        }
    }

    private func wholeGroupButton(_ activeGroup: OshiGroup) -> some View {
        let isSelected = isWholeGroupSelected(activeGroup)
        return Button {
            setupInputErrorMessage = nil
            selectedOshiDrafts = OnboardingOshiSelectionLogic.toggleWholeGroup(
                activeGroup,
                in: selectedOshiDrafts
            )
        } label: {
            HStack {
                Text("グループ全体")
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(isSelected ? MegrumTheme.lavender.opacity(0.16) : Color.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 16))
        .foregroundStyle(isSelected ? MegrumTheme.lavender : MegrumTheme.ink)
        .accessibilityLabel("\(activeGroup.name) 全体")
        .accessibilityValue(isSelected ? "選択済み" : "未選択")
        .accessibilityHint("タップするとグループ全体の選択を切り替えます")
    }

    private var oshiCharacterScroller: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(oshiCharacters) { character in
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
                selectedOshiDraftScroller
            }
        }
    }

    private var selectedOshiDraftScroller: some View {
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

    private func isWholeGroupSelected(_ group: OshiGroup) -> Bool {
        OnboardingOshiSelectionLogic.isWholeGroupSelected(group, in: selectedOshiDrafts)
    }
}
