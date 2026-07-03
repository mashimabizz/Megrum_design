import Foundation
import MegrumCore

struct PublicUserProfilePresentationState {
    var selectedVisualTab: ProfileVisualTab = .goods
    var proposalTargetItem: GoodsItem?
    var listingProposalTarget: ListingProposalTarget?
    var isSchedulePresented = false
    var isExchangeConditionsPresented = false
    var reportTarget: PublicProfileModerationTarget?
    var blockTarget: PublicProfileModerationTarget?

    mutating func selectGridItem(
        _ item: ProfileVisualGridItem,
        allowsProposalActions: Bool,
        tradeGoods: [GoodsItem],
        listings: [IndividualListing],
        goodsByID: [UUID: GoodsItem]
    ) {
        guard allowsProposalActions else {
            return
        }
        switch selectedVisualTab {
        case .goods:
            proposalTargetItem = tradeGoods.first { $0.id == item.id }
        case .listings:
            selectListing(
                item.id,
                allowsProposalActions: allowsProposalActions,
                listings: listings,
                goodsByID: goodsByID
            )
        case .wish:
            break
        }
    }

    mutating func selectListing(
        _ listingID: UUID,
        allowsProposalActions: Bool,
        listings: [IndividualListing],
        goodsByID: [UUID: GoodsItem]
    ) {
        guard allowsProposalActions,
              let listing = listings.first(where: { $0.id == listingID }),
              let target = ListingProposalTarget(listing: listing, goodsByID: goodsByID)
        else {
            return
        }
        listingProposalTarget = target
    }

    mutating func startPrimaryProposal(
        allowsProposalActions: Bool,
        tradeGoods: [GoodsItem],
        listings: [IndividualListing],
        goodsByID: [UUID: GoodsItem]
    ) {
        guard allowsProposalActions else {
            return
        }
        if let goods = tradeGoods.first {
            proposalTargetItem = goods
            return
        }
        if let target = listings.compactMap({ ListingProposalTarget(listing: $0, goodsByID: goodsByID) }).first {
            listingProposalTarget = target
        }
    }

    mutating func openSchedule() {
        isSchedulePresented = true
    }

    mutating func closeSchedule() {
        isSchedulePresented = false
    }

    mutating func openExchangeConditions() {
        isExchangeConditionsPresented = true
    }

    mutating func updateBlockConfirmationPresentation(_ isPresented: Bool) {
        if !isPresented {
            blockTarget = nil
        }
    }
}
