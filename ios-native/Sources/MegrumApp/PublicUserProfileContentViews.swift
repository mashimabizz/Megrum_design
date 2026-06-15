import MegrumCore
import MegrumDesign
import SwiftUI

struct PublicUserProfileContent: View {
    var publicProfile: PublicUserProfile?
    @Binding var selectedVisualTab: ProfileVisualTab
    var bio: String
    var ratingText: String
    var chips: [String]
    var oshiTags: [ProfileVisualTagItem]
    var gridItems: [ProfileVisualGridItem]
    var listings: [IndividualListing]
    var listingGoodsByID: [UUID: GoodsItem]
    var listingWishByID: [UUID: WishItem]
    var groups: [OshiGroup]
    var characters: [OshiCharacter]
    var goodsTypes: [GoodsType]
    var onPrimaryAction: () -> Void
    var onSelectGridItem: (ProfileVisualGridItem) -> Void
    var onSelectListing: (UUID) -> Void

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
                    tagItems: oshiTags,
                    tagSize: .compact,
                    avatarSize: 64,
                    actionTitle: "打診する",
                    isPrimaryAction: true,
                    onAction: onPrimaryAction
                )

                ProfileVisualTabs(selection: $selectedVisualTab)

                switch selectedVisualTab {
                case .listings:
                    PublicProfileListingsList(
                        listings: listings,
                        inventoryByID: listingGoodsByID,
                        wishByID: listingWishByID,
                        groups: groups,
                        characters: characters,
                        goodsTypes: goodsTypes,
                        onSelect: onSelectListing
                    )
                case .goods, .wish:
                    ProfileVisualGrid(
                        items: gridItems,
                        onSelect: onSelectGridItem
                    )
                }
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

private struct PublicProfileListingsList: View {
    var listings: [IndividualListing]
    var inventoryByID: [UUID: GoodsItem]
    var wishByID: [UUID: WishItem]
    var groups: [OshiGroup]
    var characters: [OshiCharacter]
    var goodsTypes: [GoodsType]
    var onSelect: (UUID) -> Void

    var body: some View {
        if listings.isEmpty {
            ContentUnavailableView(
                "個別募集はまだありません",
                systemImage: "rectangle.stack.badge.plus",
                description: Text("登録された個別募集がここに表示されます")
            )
            .frame(maxWidth: .infinity)
            .padding(.top, 42)
        } else {
            VStack(spacing: 18) {
                ForEach(Array(listings.enumerated()), id: \.element.id) { index, listing in
                    Button {
                        onSelect(listing.id)
                    } label: {
                        IndividualListingDesignCard(
                            listing: listing,
                            listingIndex: index,
                            listingCount: listings.count,
                            inventoryByID: inventoryByID,
                            wishByID: wishByID,
                            groups: groups,
                            characters: characters,
                            goodsTypes: goodsTypes,
                            canEdit: false,
                            onEdit: {},
                            onAddCondition: {},
                            onDelete: {}
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("個別募集 交換条件 \(index + 1)を開く")
                }
            }
        }
    }
}
