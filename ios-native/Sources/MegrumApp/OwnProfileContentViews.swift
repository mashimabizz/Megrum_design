import MegrumDesign
import SwiftUI

struct OwnProfileContent: View {
    var summary: OwnProfileSummary?
    @Binding var selectedProfileTab: ProfileVisualTab
    var profileBio: String
    var profileChips: [String]
    var profileGridItems: [ProfileVisualGridItem]
    var onClose: () -> Void
    var onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            OwnProfilePageHeader(
                canEdit: summary != nil,
                onClose: onClose,
                onEdit: onEdit
            )

            if let summary {
                ProfileVisualHero(
                    displayName: summary.displayName,
                    handle: summary.handle,
                    bio: profileBio,
                    avatarURL: summary.avatarURL,
                    tradeCount: summary.completedTradeText,
                    ratingText: "—",
                    chips: profileChips,
                    actionTitle: "プロフィールを編集",
                    onAction: onEdit
                )

                ProfileVisualTabs(selection: $selectedProfileTab)

                ProfileVisualGrid(items: profileGridItems)
            } else {
                OwnProfileUnavailableView()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 34)
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
