import MegrumCore
import MegrumDesign
import SwiftUI

enum ChoiceChipStyle {
    case regular
    case compact
}

struct ChoiceChip: View {
    var title: String
    var isSelected: Bool
    var style: ChoiceChipStyle = .regular
    var action: () -> Void

    var body: some View {
        Button {
            MegrumHaptics.performSelectionChanged(action)
        } label: {
            label
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var label: some View {
        baseLabel
    }

    private var baseLabel: some View {
        Text(title)
            .font(.system(size: fontSize, weight: .heavy, design: .rounded))
            .lineLimit(1)
            .foregroundStyle(isSelected ? .white : MegrumTheme.ink)
            .padding(.horizontal, horizontalPadding)
            .frame(height: height)
            .background(backgroundStyle, in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(.white.opacity(isSelected ? 0.7 : 0.45), lineWidth: 1)
            }
    }

    private var backgroundStyle: some ShapeStyle {
        isSelected
            ? AnyShapeStyle(MegrumTheme.lavender)
            : AnyShapeStyle(.regularMaterial)
    }

    private var fontSize: CGFloat {
        switch style {
        case .regular:
            15
        case .compact:
            CollectionScreenLayoutMetrics.filterChipFontSize
        }
    }

    private var horizontalPadding: CGFloat {
        switch style {
        case .regular:
            16
        case .compact:
            CollectionScreenLayoutMetrics.filterChipHorizontalPadding
        }
    }

    private var height: CGFloat {
        switch style {
        case .regular:
            42
        case .compact:
            CollectionScreenLayoutMetrics.filterChipHeight
        }
    }
}
