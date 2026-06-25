import Foundation
import MegrumCore

extension PublicUserProfileScreen {
    func selectProfileGridItem(_ item: ProfileVisualGridItem) {
        guard presentationContext.allowsProposalActions else {
            return
        }
        switch selectedVisualTab {
        case .goods:
            guard let goods = tradeGoods.first(where: { $0.id == item.id }) else {
                return
            }
            proposalTargetItem = goods
        case .listings:
            selectProfileListing(item.id)
        case .wish:
            break
        }
    }

    func selectProfileListing(_ listingID: UUID) {
        guard presentationContext.allowsProposalActions else {
            return
        }
        guard let listing = listings.first(where: { $0.id == listingID }),
              let target = ListingProposalTarget(listing: listing, goodsByID: goodsByID) else {
            return
        }
        listingProposalTarget = target
    }

    func startPrimaryProposal() {
        guard presentationContext.allowsProposalActions else {
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

    func openSchedule() {
        isSchedulePresented = true
    }
}
