import MegrumCore
import MegrumDesign
import SwiftUI

struct OshiSelectedMemberTag: View {
    var member: OshiSettingsMemberDraft
    var isSaving: Bool
    var onRemove: () -> Void

    var body: some View {
        Button(action: onRemove) {
            HStack(spacing: 6) {
                Text(OshiSettingsPresentationText.selectedMemberTitle(member))
                    .lineLimit(1)
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(MegrumTheme.muted.opacity(0.7))
            }
            .font(.system(size: 13, weight: .semibold, design: .rounded))
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

struct OshiMemberRequestTag: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(OshiSettingsPresentationText.memberRequestTagTitle)
                .font(.system(size: 12, weight: .bold, design: .rounded))
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
