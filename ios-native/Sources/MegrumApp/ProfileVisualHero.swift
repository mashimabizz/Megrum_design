import MegrumDesign
import SwiftUI

struct ProfileVisualHero: View {
    var displayName: String
    var handle: String
    var bio: String
    var avatarURL: URL?
    var tradeCount: String
    var ratingText: String
    var chips: [String]
    var tagItems: [ProfileVisualTagItem] = []
    var tagSize: ProfileVisualTagSize = .regular
    var avatarSize: CGFloat = 116
    var density: ProfileVisualHeroDensity = .regular
    var actionTitle: String
    var showsAction: Bool = true
    var isPrimaryAction: Bool = false
    var scheduleActionTitle: String = "スケジュール"
    var showsScheduleAction: Bool = false
    var onAction: () -> Void
    var onScheduleAction: (() -> Void)?

    var body: some View {
        VStack(spacing: density.verticalSpacing) {
            HStack(alignment: .top, spacing: density.avatarInfoSpacing) {
                ProfileVisualAvatar(url: avatarURL, fallback: displayName, size: avatarSize)

                VStack(alignment: .leading, spacing: density.infoSpacing) {
                    HStack(alignment: .top, spacing: 10) {
                        VStack(alignment: .leading, spacing: density.infoSpacing) {
                            Text(displayName)
                                .font(.system(size: density.displayNameFontSize, weight: .black, design: .rounded))
                                .foregroundStyle(MegrumTheme.ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.80)
                            Text("@\(handle)")
                                .font(.system(size: density.handleFontSize, weight: .semibold, design: .rounded))
                                .foregroundStyle(MegrumTheme.lavender.opacity(0.86))
                                .lineLimit(1)
                                .minimumScaleFactor(0.76)

                            Text(bio)
                                .font(.system(size: density.bioFontSize, weight: .semibold, design: .rounded))
                                .foregroundStyle(MegrumTheme.ink.opacity(0.78))
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .layoutPriority(1)

                        ProfileVisualStatCluster(
                            tradeCount: tradeCount,
                            ratingText: ratingText,
                            density: density
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if showsScheduleAction, let onScheduleAction {
                ProfileVisualScheduleButton(
                    title: scheduleActionTitle,
                    density: density,
                    action: onScheduleAction
                )
            }

            if !resolvedTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: tagSpacing) {
                        ForEach(Array(resolvedTags.prefix(8).enumerated()), id: \.offset) { index, tag in
                            ProfileVisualTagChip(
                                title: tag.title,
                                color: chipColor(for: tag, index: index),
                                size: tagSize
                            )
                        }
                    }
                }
            }

            if showsAction {
                Button(action: onAction) {
                    Text(actionTitle)
                        .font(.system(size: density.actionFontSize, weight: .heavy, design: .rounded))
                        .foregroundStyle(isPrimaryAction ? .white : MegrumTheme.lavender)
                        .frame(maxWidth: .infinity)
                        .frame(height: density.actionHeight)
                        .background(
                            isPrimaryAction ? AnyShapeStyle(MegrumTheme.lavender) : AnyShapeStyle(.white.opacity(0.74)),
                            in: RoundedRectangle(cornerRadius: density.actionCornerRadius, style: .continuous)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: density.actionCornerRadius, style: .continuous)
                                .stroke(MegrumTheme.lavender.opacity(0.78), lineWidth: isPrimaryAction ? 0 : 1.2)
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var resolvedTags: [ProfileVisualTagItem] {
        if !tagItems.isEmpty {
            return tagItems
        }
        return chips.map { ProfileVisualTagItem(title: $0, colorKey: $0) }
    }

    private var tagSpacing: CGFloat {
        switch tagSize {
        case .regular:
            12
        case .compact:
            7
        }
    }

    private func chipColor(for tag: ProfileVisualTagItem, index: Int) -> Color {
        let palette = [
            MegrumTheme.lavender,
            MegrumTheme.sky,
            MegrumTheme.pink,
            Color(red: 0.95, green: 0.55, blue: 0.28),
            Color(red: 0.35, green: 0.70, blue: 0.48)
        ]
        let colorIndex = tag.colorKey.unicodeScalars.reduce(index) { partial, scalar in
            partial + Int(scalar.value)
        }
        return palette[colorIndex % palette.count]
    }
}

private struct ProfileVisualStatCluster: View {
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

private struct ProfileVisualScheduleButton: View {
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

private struct ProfileVisualTagChip: View {
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

private struct ProfileVisualStat: View {
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
