import MegrumDesign
import SwiftUI

struct ProfileVisualStatCluster: View {
    var tradeCount: String
    var ratingText: String
    var density: ProfileVisualHeroDensity

    var body: some View {
        HStack(spacing: max(6, density.statRowSpacing * 0.55)) {
            ProfileVisualStat(title: "取引", value: tradeCount, accent: false, density: density)
            Divider()
                .frame(height: density.statDividerHeight)
            ProfileVisualStat(title: "評価", value: ratingText, accent: true, density: density)
        }
        .padding(.horizontal, statPadding)
        .padding(.vertical, verticalPadding)
        .background(.white.opacity(0.66), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.72), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }

    private var statPadding: CGFloat {
        switch density {
        case .regular:
            12
        case .compact:
            7
        }
    }

    private var verticalPadding: CGFloat {
        switch density {
        case .regular:
            8
        case .compact:
            6
        }
    }
}

struct ProfileVisualScheduleButton: View {
    var title: String
    var density: ProfileVisualHeroDensity
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: "calendar")
                .font(.system(size: density.actionFontSize, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(maxWidth: .infinity)
                .frame(height: density.scheduleActionHeight)
                .background(MegrumTheme.lavender.opacity(0.10), in: RoundedRectangle(cornerRadius: density.actionCornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: density.actionCornerRadius, style: .continuous)
                        .stroke(MegrumTheme.lavender.opacity(0.32), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

struct ProfileVisualConditionButton: View {
    var title: String
    var systemImage: String
    var density: ProfileVisualHeroDensity
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: fontSize, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .padding(.horizontal, horizontalPadding)
                .frame(height: height)
                .background(MegrumTheme.lavender.opacity(0.10), in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(MegrumTheme.lavender.opacity(0.24), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private var fontSize: CGFloat {
        switch density {
        case .regular:
            13.5
        case .compact:
            11.5
        }
    }

    private var horizontalPadding: CGFloat {
        switch density {
        case .regular:
            14
        case .compact:
            10
        }
    }

    private var height: CGFloat {
        switch density {
        case .regular:
            34
        case .compact:
            28
        }
    }
}

struct ProfileVisualTagChip: View {
    var title: String
    var color: Color
    var size: ProfileVisualTagSize

    var body: some View {
        Text(title)
            .font(.system(size: fontSize, weight: .bold, design: .rounded))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .padding(.horizontal, horizontalPadding)
            .frame(height: height)
            .background(color.opacity(0.13), in: Capsule())
            .overlay {
                Capsule().stroke(color.opacity(0.19), lineWidth: 1)
            }
    }

    private var fontSize: CGFloat {
        switch size {
        case .regular:
            15
        case .compact:
            12.5
        }
    }

    private var horizontalPadding: CGFloat {
        switch size {
        case .regular:
            18
        case .compact:
            10
        }
    }

    private var height: CGFloat {
        switch size {
        case .regular:
            44
        case .compact:
            30
        }
    }
}

struct ProfileVisualStat: View {
    var title: String
    var value: String
    var accent: Bool
    var density: ProfileVisualHeroDensity

    var body: some View {
        VStack(spacing: density.statSpacing) {
            Text(title)
                .font(.system(size: density.statTitleFontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink.opacity(0.62))
            HStack(spacing: 4) {
                if accent {
                    Image(systemName: "star.fill")
                        .font(.system(size: density.statIconFontSize, weight: .black))
                        .foregroundStyle(Color.orange)
                }
                Text(value)
                    .font(.system(size: density.statValueFontSize, weight: .regular, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
            }
        }
        .frame(minWidth: density.statMinWidth)
    }
}
