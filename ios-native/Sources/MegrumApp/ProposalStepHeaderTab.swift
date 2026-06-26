import MegrumDesign
import SwiftUI

struct ProposalStepHeaderTab: View {
    var title: String
    var badge: String?
    var badgeColor: Color
    var isSelected: Bool
    var isEnabled: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ProposalStepHeaderTabLabel(
                title: title,
                badge: badge,
                badgeColor: badgeColor,
                isSelected: isSelected
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.62)
    }
}

private struct ProposalStepHeaderTabLabel: View {
    var title: String
    var badge: String?
    var badgeColor: Color
    var isSelected: Bool

    var body: some View {
        HStack(spacing: ProposalSectionTabsMetrics.tabGap) {
            Text(title)
                .font(.system(size: ProposalSectionTabsMetrics.labelFontSize, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            if let badge {
                Text(badge)
                    .font(.system(size: ProposalSectionTabsMetrics.countFontSize, weight: .black, design: .rounded))
                    .foregroundStyle(badgeColor)
                    .lineLimit(1)
            }
        }
        .foregroundStyle(isSelected ? MegrumTheme.ink : MegrumTheme.ink.opacity(0.55))
        .frame(maxWidth: .infinity)
        .frame(minHeight: ProposalSectionTabsMetrics.minTabHeight)
        .padding(.horizontal, ProposalSectionTabsMetrics.tabHorizontalPadding)
        .padding(.vertical, ProposalSectionTabsMetrics.tabVerticalPadding)
        .background(
            isSelected ? AnyShapeStyle(Color.white.opacity(0.92)) : AnyShapeStyle(Color.clear),
            in: Capsule()
        )
        .overlay {
            if isSelected {
                Capsule()
                    .stroke(Color.white.opacity(0.92), lineWidth: 1)
            }
        }
        .shadow(
            color: isSelected ? MegrumTheme.ink.opacity(0.13) : .clear,
            radius: 12,
            x: 0,
            y: 5
        )
    }
}
