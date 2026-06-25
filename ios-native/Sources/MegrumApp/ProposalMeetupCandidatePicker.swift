import MegrumDesign
import SwiftUI

struct ProposalMeetupCandidatePicker: View {
    var drafts: [ProposalMeetupCandidateDraft]
    var selectedIndex: Int
    var canAdd: Bool
    var onSelect: (Int) -> Void
    var onAdd: () -> Void
    var onRemove: (Int) -> Void

    var body: some View {
        ProposalCardSection(title: "候補選択") {
            VStack(alignment: .leading, spacing: 12) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(drafts.enumerated()), id: \.offset) { index, draft in
                            ProposalMeetupCandidateButton(
                                index: index,
                                draft: draft,
                                isSelected: selectedIndex == index,
                                canRemove: drafts.count > 1,
                                onSelect: {
                                    onSelect(index)
                                },
                                onRemove: {
                                    onRemove(index)
                                }
                            )
                        }

                        Button(action: onAdd) {
                            VStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24, weight: .bold))
                                Text("候補を追加")
                                    .font(.system(size: 13, weight: .black, design: .rounded))
                            }
                            .foregroundStyle(canAdd ? MegrumTheme.lavender : MegrumTheme.muted)
                            .frame(width: 128)
                            .frame(minHeight: 108)
                            .background(.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                                    .foregroundStyle(MegrumTheme.lavender.opacity(canAdd ? 0.42 : 0.18))
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(!canAdd)
                        .accessibilityLabel("待ち合わせ候補を追加")
                    }
                    .padding(.vertical, 2)
                }

                Text("候補は最大3件まで保存できます。今選んでいる候補が送信内容に反映されます。")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct ProposalMeetupCandidateButton: View {
    var index: Int
    var draft: ProposalMeetupCandidateDraft
    var isSelected: Bool
    var canRemove: Bool
    var onSelect: () -> Void
    var onRemove: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: iconName)
                        .font(.system(size: 15, weight: .heavy))
                    Text("候補\(index + 1)")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                }
                .foregroundStyle(titleColor)

                Text(draft.summary(index: index))
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(2)

                Text(draft.isValid ? "送信可" : "未入力")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(draft.isValid ? MegrumTheme.ok : MegrumTheme.muted)
            }
            .padding(12)
            .frame(width: 178, alignment: .topLeading)
            .frame(minHeight: 108, alignment: .topLeading)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            if canRemove {
                Button(role: .destructive, action: onRemove) {
                    Label("候補を削除", systemImage: "trash")
                }
            }
        }
    }

    private var iconName: String {
        isSelected ? "checkmark.circle.fill" : "circle"
    }

    private var titleColor: Color {
        isSelected ? MegrumTheme.lavender : MegrumTheme.muted
    }

    private var backgroundColor: Color {
        isSelected ? MegrumTheme.lavender.opacity(0.12) : Color.white.opacity(0.7)
    }

    private var borderColor: Color {
        isSelected ? MegrumTheme.lavender.opacity(0.52) : Color.white.opacity(0.68)
    }
}
