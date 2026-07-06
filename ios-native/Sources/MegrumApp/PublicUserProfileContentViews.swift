import MegrumCore
import MegrumDesign
import SwiftUI

enum PublicProfileLayoutMetrics {
    static let contentSpacing = ProfileVisualCompactHeroMetrics.contentSpacing
    static let horizontalPadding = ProfileVisualCompactHeroMetrics.horizontalPadding
    static let topPadding = ProfileVisualCompactHeroMetrics.topPadding
    static let bottomPadding = ProfileVisualCompactHeroMetrics.bottomPadding
    static let compactHeroAvatarSize = ProfileVisualCompactHeroMetrics.avatarSize
}

struct PublicUserProfileContent: View {
    var publicProfile: PublicUserProfile?
    @Binding var selectedVisualTab: ProfileVisualTab
    var bio: String
    var ratingText: String
    var groomLikeCount: Int = 0
    var chips: [String]
    var oshiTags: [ProfileVisualTagItem]
    var goodsItems: [ProfileVisualGridItem]
    var wishItems: [ProfileVisualGridItem]
    var listings: [IndividualListing]
    var listingGoodsByID: [UUID: GoodsItem]
    var listingWishByID: [UUID: WishItem]
    var groups: [OshiGroup]
    var characters: [OshiCharacter]
    var goodsTypes: [GoodsType]
    var adDisplayContext: AdDisplayContext = AdDisplayContext()
    var adPlacement: AdPlacement?
    var showsProposalAction: Bool = true
    var onPrimaryAction: () -> Void
    var onOpenSchedule: () -> Void
    var onOpenExchangeConditions: () -> Void
    var onOpenEvaluations: (() -> Void)? = nil
    var onSelectGridItem: (ProfileVisualGridItem) -> Void
    var onSelectListing: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PublicProfileLayoutMetrics.contentSpacing) {
            if let publicProfile {
                ProfileVisualHero(
                    displayName: publicProfile.profile.displayName,
                    handle: publicProfile.profile.handle,
                    bio: bio,
                    avatarURL: publicProfile.profile.avatarURL,
                    likeCount: "\(groomLikeCount)",
                    ratingText: ratingText,
                    chips: chips,
                    tagItems: oshiTags,
                    tagSize: .compact,
                    avatarSize: PublicProfileLayoutMetrics.compactHeroAvatarSize,
                    density: .compact,
                    actionTitle: "打診する",
                    showsAction: showsProposalAction,
                    isPrimaryAction: true,
                    showsScheduleAction: false,
                    conditionActionTitle: "交換条件",
                    onAction: onPrimaryAction,
                    onScheduleAction: onOpenSchedule,
                    onConditionAction: onOpenExchangeConditions,
                    onRatingTap: onOpenEvaluations
                )

                ProfileVisualTabs(selection: $selectedVisualTab)

                ProfileVisualTabContent(
                    selectedTab: selectedVisualTab,
                    goodsItems: goodsItems,
                    wishItems: wishItems,
                    listings: listings,
                    listingGoodsByID: listingGoodsByID,
                    listingWishByID: listingWishByID,
                    groups: groups,
                    characters: characters,
                    goodsTypes: goodsTypes,
                    onSelectGridItem: onSelectGridItem,
                    onSelectListing: onSelectListing
                )

                if let adPlacement {
                    AdBannerSlot(
                        placement: adPlacement,
                        displayContext: adDisplayContext
                    )
                }
            } else {
                PublicProfileSkeleton()
            }
        }
        .padding(.horizontal, PublicProfileLayoutMetrics.horizontalPadding)
        .padding(.top, PublicProfileLayoutMetrics.topPadding)
        .padding(.bottom, PublicProfileLayoutMetrics.bottomPadding)
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
