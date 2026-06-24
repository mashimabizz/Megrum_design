import MegrumDesign
import SwiftUI

enum OwnProfileLayoutMetrics {
    static let contentSpacing = ProfileVisualCompactHeroMetrics.contentSpacing
    static let horizontalPadding = ProfileVisualCompactHeroMetrics.horizontalPadding
    static let topPadding = ProfileVisualCompactHeroMetrics.topPadding
    static let bottomPadding = ProfileVisualCompactHeroMetrics.bottomPadding
    static let compactHeroAvatarSize = ProfileVisualCompactHeroMetrics.avatarSize
}

struct OwnProfileContent: View {
    var summary: OwnProfileSummary?
    @Binding var selectedProfileTab: ProfileVisualTab
    var profileBio: String
    var profileTagItems: [ProfileVisualTagItem]
    var profileGridItems: [ProfileVisualGridItem]
    var onClose: () -> Void
    var onEdit: () -> Void
    var onOpenSchedule: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: OwnProfileLayoutMetrics.contentSpacing) {
            OwnProfilePageHeader(onClose: onClose)

            if let summary {
                ProfileVisualHero(
                    displayName: summary.displayName,
                    handle: summary.handle,
                    bio: profileBio,
                    avatarURL: summary.avatarURL,
                    tradeCount: summary.completedTradeText,
                    ratingText: "—",
                    chips: [],
                    tagItems: profileTagItems,
                    tagSize: .compact,
                    avatarSize: OwnProfileLayoutMetrics.compactHeroAvatarSize,
                    density: .compact,
                    actionTitle: "プロフィールを編集",
                    showsScheduleAction: true,
                    onAction: onEdit,
                    onScheduleAction: onOpenSchedule
                )

                ProfileVisualTabs(selection: $selectedProfileTab)

                ProfileVisualGrid(items: profileGridItems)
            } else {
                OwnProfileUnavailableView()
            }
        }
        .padding(.horizontal, OwnProfileLayoutMetrics.horizontalPadding)
        .padding(.top, OwnProfileLayoutMetrics.topPadding)
        .padding(.bottom, OwnProfileLayoutMetrics.bottomPadding)
    }
}

private struct OwnProfileUnavailableView: View {
    var body: some View {
        ContentUnavailableView(
            "プロフィールを読み込めません",
            systemImage: "person.crop.circle",
            description: Text("ログイン状態を確認してからもう一度開いてください。")
        )
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
}
