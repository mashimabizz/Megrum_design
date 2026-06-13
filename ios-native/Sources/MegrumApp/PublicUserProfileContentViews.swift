import MegrumCore
import MegrumDesign
import SwiftUI

struct PublicUserProfileContent: View {
    var publicProfile: PublicUserProfile?
    @Binding var selectedVisualTab: ProfileVisualTab
    var bio: String
    var ratingText: String
    var chips: [String]
    var gridItems: [ProfileVisualGridItem]
    var onPrimaryAction: () -> Void
    var onSelectGridItem: (ProfileVisualGridItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let publicProfile {
                ProfileVisualHero(
                    displayName: publicProfile.profile.displayName,
                    handle: publicProfile.profile.handle,
                    bio: bio,
                    avatarURL: publicProfile.profile.avatarURL,
                    tradeCount: "\(publicProfile.completedTradeCount)",
                    ratingText: ratingText,
                    chips: chips,
                    actionTitle: "打診する",
                    isPrimaryAction: true,
                    onAction: onPrimaryAction
                )

                ProfileVisualTabs(selection: $selectedVisualTab)

                ProfileVisualGrid(
                    items: gridItems,
                    onSelect: onSelectGridItem
                )
            } else {
                PublicProfileSkeleton()
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 18)
        .padding(.bottom, 42)
    }
}

private struct PublicProfileSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Circle()
                .fill(.white.opacity(0.74))
                .frame(width: 92, height: 92)
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.74))
                .frame(width: 190, height: 34)
            RoundedRectangle(cornerRadius: 10)
                .fill(.white.opacity(0.64))
                .frame(width: 124, height: 20)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .redacted(reason: .placeholder)
    }
}
