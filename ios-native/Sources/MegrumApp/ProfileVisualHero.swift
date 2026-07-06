import MegrumDesign
import SwiftUI

struct ProfileVisualHero: View {
    var displayName: String
    var handle: String
    var bio: String
    var avatarURL: URL?
    /// グルームでもらった Like の数（旧: 取引件数）。
    var likeCount: String
    var ratingText: String
    var chips: [String]
    var tagItems: [ProfileVisualTagItem] = []
    var tagSize: ProfileVisualTagSize = .regular
    var avatarSize: CGFloat = 116
    var density: ProfileVisualHeroDensity = .regular
    var showsStats: Bool = true
    var actionTitle: String
    var showsAction: Bool = true
    var isPrimaryAction: Bool = false
    var scheduleActionTitle: String = "スケジュール"
    var showsScheduleAction: Bool = false
    var conditionActionTitle: String?
    var conditionActionSystemImage: String = "arrow.left.arrow.right.circle"
    var onAction: () -> Void
    var onScheduleAction: (() -> Void)?
    var onConditionAction: (() -> Void)?
    var onRatingTap: (() -> Void)? = nil

    @State private var isBioExpanded = false

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
                            if let profileHandle {
                                Text("@\(profileHandle)")
                                    .font(.system(size: density.handleFontSize, weight: .semibold, design: .rounded))
                                    .foregroundStyle(MegrumTheme.lavender.opacity(0.86))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.76)
                            }

                            if let profileBio {
                                Text(profileBio)
                                    .font(.system(size: density.bioFontSize, weight: .semibold, design: .rounded))
                                    .foregroundStyle(MegrumTheme.ink.opacity(0.78))
                                    .lineLimit(isBioExpanded ? nil : 3)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        withAnimation(.smooth(duration: 0.2)) {
                                            isBioExpanded.toggle()
                                        }
                                    }
                                    .accessibilityHint(isBioExpanded ? "タップで折りたたむ" : "タップで全文表示")
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .layoutPriority(1)

                        if showsStats {
                            VStack(alignment: .trailing, spacing: 7) {
                                ProfileVisualStatCluster(
                                    likeCount: likeCount,
                                    ratingText: ratingText,
                                    density: density,
                                    onRatingTap: onRatingTap
                                )

                                if let conditionActionTitle, let onConditionAction {
                                    ProfileVisualConditionButton(
                                        title: conditionActionTitle,
                                        systemImage: conditionActionSystemImage,
                                        density: density,
                                        action: onConditionAction
                                    )
                                }
                            }
                        }
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
                            if tag.kind == .plain {
                                ProfileVisualTagChip(
                                    title: tag.title,
                                    color: chipColor(for: tag, index: index),
                                    size: tagSize
                                )
                            } else {
                                ProfileVisualOshiTagChip(
                                    title: tag.title,
                                    kind: tag.kind,
                                    size: tagSize
                                )
                            }
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

    private var profileBio: String? {
        bio.nilIfBlank
    }

    private var profileHandle: String? {
        handle.nilIfBlank
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
