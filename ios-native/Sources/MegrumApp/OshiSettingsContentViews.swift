import MegrumCore
import MegrumDesign
import SwiftUI

struct OshiSettingsMainContent: View {
    var groups: [OshiSettingsGroupDraft]
    var isLoading: Bool
    var isSaving: Bool
    var errorMessage: String?
    var noticeMessage: String?
    var expandedGroupKey: String?
    var availableCharacters: (OshiSettingsGroupDraft) -> [OshiCharacter]
    var onBack: () -> Void
    var onShowMasterSheet: () -> Void
    var onToggleExpanded: (OshiSettingsGroupDraft) -> Void
    var onRemoveGroup: (OshiSettingsGroupDraft) -> Void
    var onRemoveMember: (OshiSettingsMemberDraft, OshiSettingsGroupDraft) -> Void
    var onAddMember: (OshiCharacter, OshiSettingsGroupDraft) -> Void
    var onRequestMember: (OshiSettingsGroupDraft) -> Void

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    OshiSettingsHeader(onBack: onBack)

                    if isLoading {
                        OshiInlineLoading(text: "推し設定を読み込み中…")
                            .padding(.horizontal, 20)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(OshiPalette.warn)
                            .padding(.horizontal, 20)
                    }

                    if groups.isEmpty, !isLoading {
                        OshiEmptyState()
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                    } else {
                        VStack(spacing: 14) {
                            ForEach(groups) { group in
                                OshiSettingsGroupCard(
                                    group: group,
                                    availableCharacters: availableCharacters(group),
                                    isExpanded: expandedGroupKey == group.key,
                                    isSaving: isSaving,
                                    onToggleExpanded: { onToggleExpanded(group) },
                                    onRemoveGroup: { onRemoveGroup(group) },
                                    onRemoveMember: { onRemoveMember($0, group) },
                                    onAddMember: { onAddMember($0, group) },
                                    onRequestMember: { onRequestMember(group) }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }

                    if let noticeMessage {
                        Text(noticeMessage)
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                            .padding(.horizontal, 20)
                            .padding(.top, 2)
                    }
                }
                .padding(.bottom, 116)
            }
            .scrollDismissesKeyboard(.interactively)

            Button(action: onShowMasterSheet) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(MegrumTheme.lavender)
                            .frame(width: 48, height: 48)
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    Text("推しを追加")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                }
                .padding(.leading, 16)
                .padding(.trailing, 22)
                .frame(height: 64)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(.white.opacity(0.64), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.07), radius: 22, x: 0, y: 12)
            }
            .buttonStyle(.plain)
            .padding(.leading, 20)
            .padding(.bottom, 24)
            .disabled(isSaving)
        }
    }
}

private struct OshiSettingsHeader: View {
    var onBack: () -> Void

    var body: some View {
        ZStack {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .frame(width: 56, height: 56)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay {
                            Circle()
                                .strokeBorder(.white.opacity(0.55), lineWidth: 1)
                        }
                        .shadow(color: .black.opacity(0.06), radius: 18, x: 0, y: 10)
                }
                .buttonStyle(.plain)
                Spacer()
            }
            Text("推し設定")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 18)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.black.opacity(0.08))
                .frame(height: 0.5)
        }
    }
}

private struct OshiSettingsGroupCard: View {
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
                            Text(group.pending ? "仮登録中の推しです。承認前でもメンバー追加リクエストを送れます。" : "追加できるメンバーがマスタにありません。")
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

private struct OshiSelectedMemberTag: View {
    var member: OshiSettingsMemberDraft
    var isSaving: Bool
    var onRemove: () -> Void

    var body: some View {
        Button(action: onRemove) {
            HStack(spacing: 6) {
                Text(OshiSettingsPresentationText.selectedMemberTitle(member))
                    .lineLimit(1)
                Text("×")
                    .foregroundStyle(OshiPalette.warn)
            }
            .font(.system(size: 13, weight: .black, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)
            .padding(.horizontal, 10)
            .frame(height: 32)
            .background(backgroundStyle, in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(
                        MegrumTheme.lavender.opacity(member.pending ? 0.58 : 0.24),
                        style: StrokeStyle(lineWidth: member.pending ? 1.4 : 1, dash: member.pending ? [5, 4] : [])
                    )
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .buttonStyle(.plain)
        .disabled(isSaving)
        .accessibilityLabel("\(OshiSettingsPresentationText.selectedMemberTitle(member))を外す")
    }

    private var backgroundStyle: Color {
        member.pending ? .white.opacity(0.72) : MegrumTheme.lavender.opacity(0.12)
    }
}

private struct OshiMemberRequestTag: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(OshiSettingsPresentationText.memberRequestTagTitle)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .padding(.horizontal, 11)
                .frame(height: 30)
                .background(MegrumTheme.lavender.opacity(0.10), in: Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(
                            MegrumTheme.lavender.opacity(0.55),
                            style: StrokeStyle(lineWidth: 1.4, dash: [5, 4])
                        )
                }
                .fixedSize(horizontal: true, vertical: false)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("メンバーの追加リクエスト")
    }
}

private struct OshiEmptyState: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("推しが未設定です")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
            Text("左下の「推しを追加」からグループ・作品を追加できます。")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.2, dash: [6, 6]))
                .foregroundStyle(.black.opacity(0.12))
        }
    }
}

private struct OshiInlineLoading: View {
    var text: String

    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
                .controlSize(.small)
                .tint(MegrumTheme.lavender)
            Text(text)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
    }
}

private enum OshiPalette {
    static let warn = Color(red: 0.84, green: 0.46, blue: 0.36)
}
