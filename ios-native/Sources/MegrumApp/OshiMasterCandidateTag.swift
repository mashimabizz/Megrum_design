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
                .font(.system(size: 14.5, weight: .black, design: .rounded))
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

    private var backgroundStyle: AnyShapeStyle {
        if isSelected, !isLocked {
            return AnyShapeStyle(MegrumTheme.lavender)
        }
        if isSelected {
            return AnyShapeStyle(MegrumTheme.lavender.opacity(0.10))
        }
        return AnyShapeStyle(.white.opacity(0.94))
    }

    private var borderStyle: Color {
        isSelected ? MegrumTheme.lavender.opacity(isLocked ? 0.34 : 0.8) : .black.opacity(0.08)
    }
}
