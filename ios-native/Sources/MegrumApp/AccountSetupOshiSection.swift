import MegrumCore
import MegrumDesign
import SwiftUI

struct AccountSetupOshiMasterStep: View {
    var groups: [OshiGroup]
    var categoryOptions: [OshiCategoryOption]
    @Binding var selectedGenreID: UUID?
    @Binding var searchText: String
    @Binding var selectedGroups: [OshiGroup]
    var requestedDrafts: [OnboardingOshiDraft]
    var isLoading: Bool
    var errorMessage: String?
    @FocusState.Binding var focusedField: AccountSetupFocusedField?
    var onClearError: () -> Void
    var onRequestOshi: (String) -> Void

    private var selectedGroupIDs: Set<UUID> {
        Set(selectedGroups.map(\.id))
    }

    private var requestCandidateName: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            AccountSetupSearchField(
                placeholder: "作品名・グループ名を検索",
                text: $searchText,
                focusedField: $focusedField,
                focusCase: .groupSearch
            )

            OshiGenreSegmentBar(options: categoryOptions, selection: $selectedGenreID)
                .padding(.horizontal, -18)

            if isLoading {
                HStack(spacing: 10) {
                    ProgressView()
                        .controlSize(.small)
                        .tint(MegrumTheme.lavender)
                    Text("グループ・作品を読み込み中…")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else if groups.isEmpty {
                AccountSetupOshiNoResultsCard(
                    query: requestCandidateName,
                    onRequest: {
                        onRequestOshi(requestCandidateName)
                    }
                )
            } else {
                OshiMasterCandidateGrid(
                    groups: groups,
                    selectedGroupIDs: [],
                    isSelected: { selectedGroupIDs.contains($0.id) },
                    onSelect: toggleGroup
                )
                .padding(.horizontal, -18)
            }

            AccountSetupSelectedGroupSummary(
                selectedGroups: selectedGroups,
                requestedDrafts: requestedDrafts
            )
            AccountSetupErrorText(message: errorMessage)
        }
        .padding(.top, 10)
    }

    private func toggleGroup(_ group: OshiGroup) {
        onClearError()
        if selectedGroups.contains(where: { $0.id == group.id }) {
            selectedGroups.removeAll { $0.id == group.id }
        } else {
            selectedGroups.append(group)
        }
    }
}

private struct AccountSetupOshiNoResultsCard: View {
    var query: String
    var onRequest: () -> Void

    private var canRequest: Bool {
        !query.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("該当するグループ・作品が見つかりません")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)

            if canRequest {
                Button(action: onRequest) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                        Text("「\(query)」を追加リクエスト")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.up.forward")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(MegrumTheme.lavender)
                    .padding(.horizontal, 14)
                    .frame(height: 46)
                    .background(MegrumTheme.lavender.opacity(0.12), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct AccountSetupSelectedGroupSummary: View {
    var selectedGroups: [OshiGroup]
    var requestedDrafts: [OnboardingOshiDraft]

    private var hasSelection: Bool {
        !selectedGroups.isEmpty || !requestedDrafts.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("選択中")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            if !hasSelection {
                Text("まだ選択されていません")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(selectedGroups) { group in
                            AccountSetupSelectedGroupChip(
                                title: group.name,
                                foregroundColor: MegrumTheme.lavender,
                                backgroundColor: MegrumTheme.lavender.opacity(0.14)
                            )
                        }

                        ForEach(requestedDrafts) { draft in
                            AccountSetupSelectedGroupChip(
                                title: draft.displayName,
                                foregroundColor: MegrumTheme.pink,
                                backgroundColor: MegrumTheme.pink.opacity(0.18)
                            )
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
}

private struct AccountSetupSelectedGroupChip: View {
    var title: String
    var foregroundColor: Color
    var backgroundColor: Color

    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .black, design: .rounded))
            .lineLimit(1)
            .padding(.horizontal, 12)
            .frame(height: 34)
            .background(backgroundColor, in: Capsule())
            .foregroundStyle(foregroundColor)
    }
}

struct AccountSetupOshiMemberStep: View {
    var targets: [OnboardingOshiMemberTarget]
    @Binding var selectedOshiDrafts: [OnboardingOshiDraft]
    var charactersByGroupID: [UUID: [OshiCharacter]]
    var isLoading: Bool
    var errorMessage: String?
    var onClearError: () -> Void
    var onRequestMember: (OshiMemberRequestContext) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isLoading {
                HStack(spacing: 10) {
                    ProgressView()
                        .controlSize(.small)
                        .tint(MegrumTheme.lavender)
                    Text("メンバー・キャラクター候補を読み込み中…")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            ForEach(targets) { target in
                AccountSetupOshiMemberGroupCard(
                    target: target,
                    characters: target.groupID.flatMap { charactersByGroupID[$0] } ?? [],
                    selectedOshiDrafts: $selectedOshiDrafts,
                    onClearError: onClearError,
                    onRequestMember: onRequestMember
                )
            }

            AccountSetupSelectedOshiSummary(
                selectedOshiDrafts: $selectedOshiDrafts,
                onClearInputError: onClearError
            )

            AccountSetupErrorText(message: errorMessage)
        }
        .padding(.top, 10)
    }
}

private struct AccountSetupOshiMemberGroupCard: View {
    var target: OnboardingOshiMemberTarget
    var characters: [OshiCharacter]
    @Binding var selectedOshiDrafts: [OnboardingOshiDraft]
    var onClearError: () -> Void
    var onRequestMember: (OshiMemberRequestContext) -> Void

    private var activeGroup: OshiGroup? {
        target.groupID.map { OshiGroup(id: $0, name: target.name) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(target.name)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Spacer(minLength: 0)
                Text(target.pending ? "承認待ち" : (characters.isEmpty ? "全体で登録OK" : "複数選択OK"))
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .padding(.horizontal, 9)
                    .frame(height: 24)
                    .background(MegrumTheme.lavender.opacity(0.12), in: Capsule())
            }

            if let activeGroup {
                AccountSetupWholeGroupButton(
                    activeGroup: activeGroup,
                    isSelected: OnboardingOshiSelectionLogic.isWholeGroupSelected(activeGroup, in: selectedOshiDrafts),
                    onToggle: toggleWholeGroup
                )
            }

            if target.pending {
                AccountSetupPendingOshiRequestCard(
                    memberDrafts: OnboardingOshiSelectionLogic.memberRequestDrafts(for: target, in: selectedOshiDrafts),
                    onRequestMember: { onRequestMember(target.requestContext) }
                )
            } else if characters.isEmpty {
                Text("このグループ・作品にはメンバー・キャラクター候補がありません。全体で登録できます。")
                    .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .lineSpacing(3)
                OshiMemberRequestTag(action: { onRequestMember(target.requestContext) })
            } else if let activeGroup {
                AccountSetupOshiCharacterScroller(
                    activeGroup: activeGroup,
                    oshiCharacters: characters,
                    selectedOshiDrafts: selectedOshiDrafts,
                    onToggleCharacter: toggleCharacter,
                    onRequestMember: { onRequestMember(target.requestContext) }
                )
            }
        }
        .padding(16)
        .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(MegrumTheme.lavender.opacity(0.16), lineWidth: 1)
        }
    }

    private func toggleWholeGroup() {
        guard let activeGroup else {
            return
        }
        onClearError()
        selectedOshiDrafts = OnboardingOshiSelectionLogic.toggleWholeGroup(
            activeGroup,
            in: selectedOshiDrafts
        )
    }

    private func toggleCharacter(_ character: OshiCharacter, _ group: OshiGroup) {
        onClearError()
        selectedOshiDrafts = OnboardingOshiSelectionLogic.toggleCharacter(
            character,
            group: group,
            in: selectedOshiDrafts
        )
    }
}

private struct AccountSetupPendingOshiRequestCard: View {
    var memberDrafts: [OnboardingOshiDraft]
    var onRequestMember: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("グループ・作品全体で仮登録されています。必要な場合だけ、メンバー・キャラクターを追加リクエストしてください。")
                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .lineSpacing(3)

            if !memberDrafts.isEmpty {
                WrappingTagFlow(spacing: 8, rowSpacing: 8) {
                    ForEach(memberDrafts) { draft in
                        AccountSetupSelectedGroupChip(
                            title: draft.characterName ?? draft.displayName,
                            foregroundColor: MegrumTheme.pink,
                            backgroundColor: MegrumTheme.pink.opacity(0.18)
                        )
                    }
                }
            }

            Button(action: onRequestMember) {
                Label("メンバーを追加リクエスト", systemImage: "plus.circle.fill")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .padding(.horizontal, 13)
                    .frame(height: 40)
                    .background(MegrumTheme.lavender.opacity(0.12), in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }
}

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
            AccountSetupOshiHeader(isLoading: isLoading)
            AccountSetupOshiSearchField(
                groupSearchText: $groupSearchText,
                focusedField: $focusedField,
                onSearchSubmit: onSearchSubmit
            )
            AccountSetupOshiGroupScroller(
                oshiGroups: oshiGroups,
                activeGroup: activeGroup,
                selectedOshiDrafts: selectedOshiDrafts,
                onSelectGroup: selectGroup
            )
            AccountSetupActiveGroupMembers(
                activeGroup: activeGroup,
                oshiCharacters: oshiCharacters,
                selectedOshiDrafts: $selectedOshiDrafts,
                onClearInputError: clearInputError
            )
            AccountSetupSelectedOshiSummary(
                selectedOshiDrafts: $selectedOshiDrafts,
                onClearInputError: clearInputError
            )
        }
        .padding(18)
        .background(Color.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(Color.white.opacity(0.84), lineWidth: 1)
        )
    }

    private func selectGroup(_ group: OshiGroup) {
        clearInputError()
        activeGroup = group
        onSelectGroup(group)
    }

    private func clearInputError() {
        setupInputErrorMessage = nil
    }
}

private struct AccountSetupOshiSearchField: View {
    @Binding var groupSearchText: String
    @FocusState.Binding var focusedField: AccountSetupFocusedField?
    var onSearchSubmit: (String) -> Void

    var body: some View {
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
}

private struct AccountSetupOshiGroupScroller: View {
    var oshiGroups: [OshiGroup]
    var activeGroup: OshiGroup?
    var selectedOshiDrafts: [OnboardingOshiDraft]
    var onSelectGroup: (OshiGroup) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(oshiGroups) { group in
                    let hasSelection = OnboardingOshiSelectionLogic.groupHasSelection(group, in: selectedOshiDrafts)
                    AccountSetupOshiChip(
                        title: group.name,
                        systemImage: hasSelection ? "checkmark.circle.fill" : "sparkle",
                        isSelected: activeGroup?.id == group.id || hasSelection,
                        accessibilityHint: "タップするとこのグループのメンバー選択を表示します"
                    ) {
                        onSelectGroup(group)
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }
}

private struct AccountSetupActiveGroupMembers: View {
    var activeGroup: OshiGroup?
    var oshiCharacters: [OshiCharacter]
    @Binding var selectedOshiDrafts: [OnboardingOshiDraft]
    var onClearInputError: () -> Void

    @ViewBuilder
    var body: some View {
        if let activeGroup {
            VStack(alignment: .leading, spacing: 10) {
                Text("\(activeGroup.name) のメンバー")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)

                AccountSetupWholeGroupButton(
                    activeGroup: activeGroup,
                    isSelected: isWholeGroupSelected(activeGroup),
                    onToggle: { toggleWholeGroup(activeGroup) }
                )
                AccountSetupOshiCharacterScroller(
                    activeGroup: activeGroup,
                    oshiCharacters: oshiCharacters,
                    selectedOshiDrafts: selectedOshiDrafts,
                    onToggleCharacter: toggleCharacter
                )
            }
        }
    }

    private func toggleWholeGroup(_ activeGroup: OshiGroup) {
        onClearInputError()
        selectedOshiDrafts = OnboardingOshiSelectionLogic.toggleWholeGroup(
            activeGroup,
            in: selectedOshiDrafts
        )
    }

    private func toggleCharacter(_ character: OshiCharacter, activeGroup: OshiGroup) {
        onClearInputError()
        selectedOshiDrafts = OnboardingOshiSelectionLogic.toggleCharacter(
            character,
            group: activeGroup,
            in: selectedOshiDrafts
        )
    }

    private func isWholeGroupSelected(_ group: OshiGroup) -> Bool {
        OnboardingOshiSelectionLogic.isWholeGroupSelected(group, in: selectedOshiDrafts)
    }
}

private struct AccountSetupWholeGroupButton: View {
    var activeGroup: OshiGroup
    var isSelected: Bool
    var onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
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
}

private struct AccountSetupOshiCharacterScroller: View {
    var activeGroup: OshiGroup
    var oshiCharacters: [OshiCharacter]
    var selectedOshiDrafts: [OnboardingOshiDraft]
    var onToggleCharacter: (OshiCharacter, OshiGroup) -> Void
    var onRequestMember: (() -> Void)? = nil

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(oshiCharacters) { character in
                    let isSelected = OnboardingOshiSelectionLogic.isCharacterSelected(character, in: selectedOshiDrafts)
                    AccountSetupOshiChip(
                        title: character.name,
                        systemImage: isSelected ? "checkmark.circle.fill" : "person.crop.circle",
                        isSelected: isSelected,
                        accessibilityHint: isSelected ? "タップするとこのメンバーを選択から外します" : "タップするとこのメンバーを推しに追加します"
                    ) {
                        onToggleCharacter(character, activeGroup)
                    }
                }

                if let onRequestMember {
                    OshiMemberRequestTag(action: onRequestMember)
                }
            }
            .padding(.vertical, 2)
        }
    }
}
