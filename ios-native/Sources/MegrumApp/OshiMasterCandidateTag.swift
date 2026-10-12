import MegrumDesign
import SwiftUI

struct OshiMasterCandidateTag: View {
    var title: String
    var isSelected: Bool
    var isLocked: Bool = false
    var action: () -> Void

    var body: some View {
        Button {
            MegrumHaptics.performSelectionChanged(action)
        } label: {
            Text(title)
                .font(.system(size: 14.5, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.76)
                .foregroundStyle(foregroundStyle)
                .padding(.horizontal, OshiMasterSelectLayoutMetrics.candidateTagHorizontalPadding)
                .frame(
                    minWidth: OshiMasterSelectLayoutMetrics.candidateTagMinimumWidth,
                    minHeight: OshiMasterSelectLayoutMetrics.candidateTagMinHeight
                )
                .background(
                    backgroundStyle,
                    in: Capsule()
                )
                .overlay {
                    Capsule()
                        .strokeBorder(borderStyle, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
        .accessibilityLabel(isSelected ? "\(title)、選択済み" : title)
    }

    private var foregroundStyle: AnyShapeStyle {
        if isSelected, !isLocked {
            return AnyShapeStyle(.white)
        }
        if isSelected {
            return AnyShapeStyle(MegrumTheme.lavender.opacity(0.82))
        }
        return AnyShapeStyle(MegrumTheme.ink)
    }

    // 選択＝共通グラデ塗り（iter1226.416）。登録済みロックは淡いラベンダーのまま。
    private var backgroundStyle: AnyShapeStyle {
        if isSelected, !isLocked {
            return AnyShapeStyle(MegrumTheme.primaryGradient)
        }
        if isSelected {
            return AnyShapeStyle(MegrumTheme.lavender.opacity(0.10))
        }
        return AnyShapeStyle(.white.opacity(0.94))
    }

    private var borderStyle: Color {
        if isSelected {
            return isLocked ? MegrumTheme.lavender.opacity(0.34) : .clear
        }
        return .black.opacity(0.08)
    }
}
