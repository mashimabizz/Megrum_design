import MegrumCore
import MegrumDesign
import SwiftUI

/// 推し設定のメインコンテンツ（iter1226.405 刷新）：
/// 巨大フローティングピルを廃止し、ヘッダー右上の「＋」とリスト末尾の破線カードの2導線に。
/// タイポは17pt基準へ縮小し、`.black` ウェイト多用をやめる。
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
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                OshiSettingsHeader(
                    onBack: onBack,
                    onAdd: onShowMasterSheet,
                    isAddDisabled: isSaving
                )

                if isLoading {
                    OshiInlineLoading(text: "推し設定を読み込み中…")
                        .padding(.horizontal, 20)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.conditionExact)
                        .padding(.horizontal, 20)
                }

                VStack(spacing: 14) {
                    if groups.isEmpty, !isLoading {
                        OshiEmptyState()
                    } else {
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

                    if !isLoading {
                        OshiAddGroupCard(action: onShowMasterSheet)
                            .disabled(isSaving)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                if let noticeMessage {
                    Text(noticeMessage)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .padding(.horizontal, 20)
                        .padding(.top, 2)
                }
            }
            .padding(.bottom, 48)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

private struct OshiSettingsHeader: View {
    var onBack: () -> Void
    var onAdd: () -> Void
    var isAddDisabled: Bool

    var body: some View {
        ZStack {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(MegrumTheme.ink)
                        .frame(width: 40, height: 40)
                        .background(MegrumTheme.ink.opacity(0.045), in: Circle())
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("戻る")

                Spacer()

                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(MegrumTheme.primaryGradient, in: Circle())
                        .shadow(color: MegrumTheme.primaryShadow, radius: 8, x: 0, y: 3)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(isAddDisabled)
                .accessibilityLabel("推しを追加")
            }
            Text("推し設定")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.black.opacity(0.06))
                .frame(height: 0.5)
        }
    }
}

/// リスト末尾の「推しを追加」カード。空状態でも常設し、追加導線を画面内に残す。
private struct OshiAddGroupCard: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                Text("推しを追加")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(MegrumTheme.muted)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.4, dash: [6, 6]))
                    .foregroundStyle(MegrumTheme.muted.opacity(0.4))
            }
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("推しを追加")
    }
}

private struct OshiEmptyState: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("推しが未設定です")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
            Text("「推しを追加」からグループ・作品を追加できます。")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.black.opacity(0.06), lineWidth: 1)
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
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
    }
}
