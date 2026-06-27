import MegrumCore
import MegrumDesign
import SwiftUI

struct OshiSettingsGroupCard: View {
    var group: OshiSettingsGroupDraft
    var availableCharacters: [OshiCharacter]
    var isExpanded: Bool
    var isSaving: Bool
    var onToggleExpanded: () -> Void
    var onRemoveGroup: () -> Void
    var onRemoveMember: (OshiSettingsMemberDraft) -> Void
    var onAddMember: (OshiCharacter) -> Void
    var onRequestMember: () -> Void

    @State private var showsRemoveConfirmation = false
    @State private var canConfirmRemoval = false

    private var summary: String? {
        OshiSettingsPresentationText.groupSummary(for: group)
    }

    private func showRemoveConfirmation() {
        canConfirmRemoval = false
        withAnimation(.snappy(duration: 0.18)) {
            showsRemoveConfirmation = true
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 250_000_000)
            if showsRemoveConfirmation {
                canConfirmRemoval = true
            }
        }
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 7) {
                            Text(group.name)
                                .font(.system(size: 22, weight: .black, design: .rounded))
                                .foregroundStyle(MegrumTheme.ink)
                                .lineLimit(1)
                            if group.pending {
                                Text("承認待ち")
                                    .font(.system(size: 10, weight: .black, design: .rounded))
                                    .foregroundStyle(MegrumTheme.lavender)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 4)
                                    .background(MegrumTheme.lavender.opacity(0.12), in: Capsule())
                            }
                        }
                        if let summary {
                            Text(summary)
                                .font(.system(size: 15, weight: .black, design: .rounded))
                                .foregroundStyle(MegrumTheme.muted)
                        }
                    }
                    Spacer()
                    Button {
                        showRemoveConfirmation()
                    } label: {
                        Text("削除")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(OshiPalette.warn)
                            .padding(.horizontal, 14)
                            .frame(height: 38)
                            .background(OshiPalette.warn.opacity(0.11), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(isSaving)
                }

                WrappingTagFlow(spacing: 8, rowSpacing: 9) {
                    ForEach(group.members) { member in
                        OshiSelectedMemberTag(
                            member: member,
                            isSaving: isSaving,
                            onRemove: { onRemoveMember(member) }
                        )
                    }

                    Button(action: onToggleExpanded) {
                        Text(OshiSettingsPresentationText.memberToggleTitle(isExpanded: isExpanded))
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                            .padding(.horizontal, 12)
                            .frame(height: 32)
                            .overlay {
                                Capsule()
                                    .strokeBorder(style: StrokeStyle(lineWidth: 1.4, dash: [5, 5]))
                                    .foregroundStyle(MegrumTheme.muted.opacity(0.35))
                            }
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .buttonStyle(.plain)
                }

                if isExpanded {
                    VStack(alignment: .leading, spacing: 10) {
                        if availableCharacters.isEmpty {
                            Text(group.pending ? "仮登録中の推しです。承認前でもメンバー追加リクエストを送れます。" : "追加できるメンバー・キャラクターが登録されていません。")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(MegrumTheme.muted)
                        } else {
                            Text("追加できるメンバー")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundStyle(MegrumTheme.muted)

                            WrappingTagFlow(spacing: 8, rowSpacing: 8) {
                                ForEach(availableCharacters) { character in
                                    Button {
                                        onAddMember(character)
                                    } label: {
                                        Text(OshiSettingsPresentationText.availableMemberTitle(character))
                                            .font(.system(size: 12, weight: .black, design: .rounded))
                                            .foregroundStyle(MegrumTheme.ink)
                                            .padding(.horizontal, 10)
                                            .frame(height: 30)
                                            .background(.white.opacity(0.9), in: Capsule())
                                            .overlay {
                                                Capsule()
                                                    .strokeBorder(.black.opacity(0.08), lineWidth: 1)
                                            }
                                            .fixedSize(horizontal: true, vertical: false)
                                    }
                                    .buttonStyle(.plain)
                                }

                                OshiMemberRequestTag(action: onRequestMember)
                            }
                        }

                        if availableCharacters.isEmpty {
                            WrappingTagFlow(spacing: 8, rowSpacing: 8) {
                                OshiMemberRequestTag(action: onRequestMember)
                            }
                        }
                    }
                    .padding(12)
                    .background(MegrumTheme.canvas, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(.black.opacity(0.06), lineWidth: 1)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(18)
            .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(
                        group.pending ? MegrumTheme.lavender.opacity(0.42) : .black.opacity(0.06),
                        style: StrokeStyle(lineWidth: group.pending ? 1.4 : 1, dash: group.pending ? [7, 5] : [])
                    )
            }
            .shadow(color: .black.opacity(0.025), radius: 12, x: 0, y: 6)

            if showsRemoveConfirmation {
                AnchoredDestructiveConfirmationPopover(
                    title: OshiSettingsPresentationText.removeGroupConfirmationTitle,
                    message: OshiSettingsPresentationText.removeGroupConfirmationMessage,
                    destructiveTitle: OshiSettingsPresentationText.removeGroupConfirmationAction,
                    onCancel: {
                        withAnimation(.snappy(duration: 0.18)) {
                            showsRemoveConfirmation = false
                            canConfirmRemoval = false
                        }
                    },
                    onConfirm: {
                        showsRemoveConfirmation = false
                        canConfirmRemoval = false
                        onRemoveGroup()
                    },
                    isConfirmEnabled: canConfirmRemoval
                )
                .offset(x: 0, y: 44)
                .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .topTrailing)))
                .zIndex(2)
            }
        }
    }
}
