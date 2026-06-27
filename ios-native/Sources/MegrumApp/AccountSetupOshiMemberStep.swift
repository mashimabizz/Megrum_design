import MegrumCore
import MegrumDesign
import SwiftUI

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
