import MegrumCore
import SwiftUI

enum ProfileVisualListingsPolicy {
    static let canEditFromProfile = false
}

struct ProfileVisualTabContent: View {
    var selectedTab: ProfileVisualTab
    var goodsItems: [ProfileVisualGridItem]
    var wishItems: [ProfileVisualGridItem]
    var listings: [IndividualListing]
    var listingGoodsByID: [UUID: GoodsItem]
    var listingWishByID: [UUID: WishItem]
    var groups: [OshiGroup]
    var characters: [OshiCharacter]
    var goodsTypes: [GoodsType]
    var onSelectGridItem: ((ProfileVisualGridItem) -> Void)?
    var onSelectListing: ((UUID) -> Void)?

    var body: some View {
        switch selectedTab {
        case .goods:
            ProfileVisualGrid(items: goodsItems, onSelect: onSelectGridItem)
        case .listings:
            ProfileVisualListingsSection(
                listings: listings,
                inventoryByID: listingGoodsByID,
                wishByID: listingWishByID,
                groups: groups,
                characters: characters,
                goodsTypes: goodsTypes,
                onSelectListing: onSelectListing
            )
        case .wish:
            ProfileVisualGrid(items: wishItems, onSelect: onSelectGridItem)
        }
    }
}

struct ProfileVisualListingsSection: View {
    var listings: [IndividualListing]
    var inventoryByID: [UUID: GoodsItem]
    var wishByID: [UUID: WishItem]
    var groups: [OshiGroup]
    var characters: [OshiCharacter]
    var goodsTypes: [GoodsType]
    var onSelectListing: ((UUID) -> Void)?
    @State private var selectionState = IndividualListingActiveSelectionState()

    var body: some View {
        if listings.isEmpty {
            EmptyListingView()
        } else if let activeListing {
            VStack(spacing: 14) {
                IndividualListingConditionStrip(
                    listings: listings,
                    activeListingID: $selectionState.activeListingID
                )

                listingCard(activeListing)
            }
            .onChange(of: listings.map(\.id), initial: true) { _, ids in
                selectionState.reconcile(with: ids)
            }
        }
    }

    private var activeListing: IndividualListing? {
        selectionState.activeListing(in: listings)
    }

    private var activeListingIndex: Int {
        selectionState.activeListingIndex(in: listings)
    }

    @ViewBuilder
    private func listingCard(_ listing: IndividualListing) -> some View {
        let card = IndividualListingDesignCard(
            listing: listing,
            listingIndex: activeListingIndex,
            listingCount: listings.count,
            inventoryByID: inventoryByID,
            wishByID: wishByID,
            groups: groups,
            characters: characters,
            goodsTypes: goodsTypes,
            canEdit: ProfileVisualListingsPolicy.canEditFromProfile,
            onEditOffer: {},
            onAddCondition: {},
            onEditExchangeCondition: {},
            onShare: {},
            onDelete: {}
        )

        if let onSelectListing {
            Button {
                onSelectListing(listing.id)
            } label: {
                card
            }
            .buttonStyle(.plain)
            .accessibilityHint("ダブルタップでこの個別募集から打診します")
        } else {
            card
        }
    }
}
