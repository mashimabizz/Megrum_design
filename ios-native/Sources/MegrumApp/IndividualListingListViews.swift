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
    var isSelectionMode: Bool
    var selectedListingIDs: Set<UUID>
    var onEditOffer: (IndividualListing) -> Void
    var onAddCondition: (IndividualListing) -> Void
    var onEditExchangeCondition: (IndividualListing) -> Void
    var onShare: (IndividualListing) -> Void
    var onDelete: (IndividualListing) -> Void
    var onBeginSelection: (IndividualListing) -> Void
    var onToggleSelection: (IndividualListing) -> Void
    var onScrollContentTopChange: ((CGFloat) -> Void)? = nil
    @State private var selectionState = IndividualListingActiveSelectionState()
    @Environment(\.megrumPinnedTopChromeInset) private var pinnedTopChromeInset

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
                } else if let activeListing = selectionState.activeListing(in: listings) {
                    IndividualListingConditionStrip(
                        listings: listings,
                        activeListingID: $selectionState.activeListingID,
                        isSelectionMode: isSelectionMode,
                        selectedListingIDs: selectedListingIDs,
                        onBeginSelection: onBeginSelection,
                        onToggleSelection: onToggleSelection
                    )

                    IndividualListingDesignCard(
                        listing: activeListing,
                        listingIndex: selectionState.activeListingIndex(in: listings),
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
                        onShare: {
                            onShare(activeListing)
                        },
                        onDelete: {
                            onDelete(activeListing)
                        }
                    )
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, pinnedTopChromeInset > 0 ? pinnedTopChromeInset : 16)
            .padding(.bottom, 118)
            .megrumReportsScrollContentTop()
            .megrumSuppressesEnclosingScrollEdgeEffects()
        }
        .coordinateSpace(name: MegrumScrollContentTopSpace.name)
        .onPreferenceChange(MegrumScrollContentTopPreferenceKey.self) { contentTop in
            MainActor.assumeIsolated {
                onScrollContentTopChange?(contentTop)
            }
        }
        .megrumHiddenBottomScrollEdgeEffect()
        .ignoresSafeArea(.container, edges: .bottom)
        .onChange(of: listings.map(\.id), initial: true) { _, ids in
            selectionState.reconcile(with: ids)
        }
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
    var onShare: () -> Void
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
                onShare: onShare,
                onDelete: onDelete
            )
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("個別募集 交換条件 \(listingIndex + 1)")
    }
}
