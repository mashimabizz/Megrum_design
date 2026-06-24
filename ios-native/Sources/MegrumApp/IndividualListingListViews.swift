import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct IndividualListingsContent: View {
    var headerTitle: String
    var headerAccessory: AnyView?
    var showsHeader = true
    var isLoading: Bool
    var listings: [IndividualListing]
    var inventoryByID: [UUID: GoodsItem]
    var wishByID: [UUID: WishItem]
    var groups: [OshiGroup]
    var characters: [OshiCharacter]
    var goodsTypes: [GoodsType]
    var viewerID: UUID?
    var onEditOffer: (IndividualListing) -> Void
    var onAddCondition: (IndividualListing) -> Void
    var onEditExchangeCondition: (IndividualListing) -> Void
    var onDelete: (IndividualListing) -> Void
    @State private var activeListingID: UUID?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if showsHeader {
                    IndividualListingTopBar(title: headerTitle, accessory: headerAccessory)
                }

                if isLoading {
                    IndividualListingSkeletons()
                } else if listings.isEmpty {
                    EmptyListingView()
                } else if let activeListing = activeListing(in: listings) {
                    IndividualListingConditionStrip(
                        listings: listings,
                        activeListingID: $activeListingID
                    )

                    IndividualListingDesignCard(
                        listing: activeListing,
                        listingIndex: activeListingIndex(in: listings),
                        listingCount: listings.count,
                        inventoryByID: inventoryByID,
                        wishByID: wishByID,
                        groups: groups,
                        characters: characters,
                        goodsTypes: goodsTypes,
                        canEdit: activeListing.ownerID == viewerID,
                        onEditOffer: {
                            onEditOffer(activeListing)
                        },
                        onAddCondition: {
                            onAddCondition(activeListing)
                        },
                        onEditExchangeCondition: {
                            onEditExchangeCondition(activeListing)
                        },
                        onDelete: {
                            onDelete(activeListing)
                        }
                    )
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 118)
        }
        .onChange(of: listings.map(\.id), initial: true) { _, ids in
            if let activeListingID, ids.contains(activeListingID) {
                return
            }
            activeListingID = ids.first
        }
    }

    private func activeListing(in listings: [IndividualListing]) -> IndividualListing? {
        if let activeListingID,
           let listing = listings.first(where: { $0.id == activeListingID }) {
            return listing
        }
        return listings.first
    }

    private func activeListingIndex(in listings: [IndividualListing]) -> Int {
        guard let activeListingID,
              let index = listings.firstIndex(where: { $0.id == activeListingID })
        else {
            return 0
        }
        return index
    }
}

struct IndividualListingDesignCard: View {
    var listing: IndividualListing
    var listingIndex: Int
    var listingCount: Int
    var inventoryByID: [UUID: GoodsItem]
    var wishByID: [UUID: WishItem]
    var groups: [OshiGroup]
    var characters: [OshiCharacter]
    var goodsTypes: [GoodsType]
    var canEdit: Bool
    var onEditOffer: () -> Void
    var onAddCondition: () -> Void
    var onEditExchangeCondition: () -> Void
    var onDelete: () -> Void

    private var haveItems: [GoodsItem] {
        listing.haves.compactMap { inventoryByID[$0.itemID] }
    }

    private var sortedOptions: [IndividualListingWishOption] {
        listing.options.sorted { $0.position < $1.position }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                IndividualListingReceivePanel(
                    options: sortedOptions,
                    wishByID: wishByID,
                    groups: groups,
                    characters: characters,
                    goodsTypes: goodsTypes,
                    canEdit: canEdit,
                    onAddCondition: onAddCondition
                )
                .frame(maxWidth: .infinity)

                IndividualListingOfferPanel(
                    listing: listing,
                    haveItems: haveItems,
                    goodsTypes: goodsTypes,
                    fallbackCashAmount: IndividualListingHaveCashSummary.extract(from: listing.note).summary?.amount
                        ?? sortedOptions.first(where: \.isCashOffer)?.cashAmount,
                    canEdit: canEdit,
                    onEdit: onEditOffer
                )
                .frame(maxWidth: .infinity)
            }

            IndividualListingExchangeConditionPanel(
                listing: listing,
                canEdit: canEdit,
                onEdit: onEditExchangeCondition,
                onDelete: onDelete
            )
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("個別募集 交換条件 \(listingIndex + 1)")
    }
}
