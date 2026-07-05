import MegrumDesign
import SwiftUI

struct ProfileVisualStatCluster: View {
    var tradeCount: String
    var ratingText: String
    var density: ProfileVisualHeroDensity
    var onRatingTap: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: max(6, density.statRowSpacing * 0.55)) {
            ProfileVisualStat(title: "取引", value: tradeCount, accent: false, density: density)
            Divider()
                .frame(height: density.statDividerHeight)
            if let onRatingTap {
                Button(action: onRatingTap) {
                    ProfileVisualStat(title: "評価", value: ratingText, accent: true, density: density)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("評価一覧を表示")
            } else {
                ProfileVisualStat(title: "評価", value: ratingText, accent: true, density: density)
            }
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

/// 推しタグ専用チップ。L1（group）＝ホーム「指名あり」のグラデ塗り、
/// L2（member）＝「wish一致」の白地＋グラデ枠線トーン。
struct ProfileVisualOshiTagChip: View {
    var title: String
    var kind: ProfileVisualTagKind
    var size: ProfileVisualTagSize

    var body: some View {
        switch kind {
        case .group:
            baseText
                .foregroundStyle(.white)
                .background(megrumGradient, in: Capsule())
                .overlay {
                    Capsule().strokeBorder(.white.opacity(0.42), lineWidth: 0.8)
                }
                .shadow(color: MegrumTheme.lavender.opacity(0.18), radius: 8, y: 4)
        case .member, .plain:
            baseText
                .foregroundStyle(megrumGradient)
                .background(.white.opacity(0.96), in: Capsule())
                .overlay {
                    Capsule().strokeBorder(megrumGradient, lineWidth: 1.15)
                }
        }
    }

    private var baseText: some View {
        Text(title)
            .font(.system(size: fontSize, weight: .black, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .padding(.horizontal, horizontalPadding)
            .frame(height: height)
    }

    private var megrumGradient: LinearGradient {
        LinearGradient(
            colors: [MegrumTheme.sky, MegrumTheme.lavender, MegrumTheme.pink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var fontSize: CGFloat {
        switch size {
        case .regular: 14.5
        case .compact: 12.5
        }
    }

    private var horizontalPadding: CGFloat {
        switch size {
        case .regular: 16
        case .compact: 10
        }
    }

    private var height: CGFloat {
        switch size {
        case .regular: 34
        case .compact: 27
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
