import Foundation
import MegrumCore

extension PublicUserProfileScreen {
    func selectProfileGridItem(_ item: ProfileVisualGridItem) {
        presentationState.selectGridItem(
            item,
            allowsProposalActions: presentationContext.allowsProposalActions,
            tradeGoods: tradeGoods,
            listings: listings,
            goodsByID: goodsByID
        )
    }

    func selectProfileListing(_ listingID: UUID) {
        presentationState.selectListing(
            listingID,
            allowsProposalActions: presentationContext.allowsProposalActions,
            listings: listings,
            goodsByID: goodsByID
        )
    }

    func startPrimaryProposal() {
        presentationState.startPrimaryProposal(
            allowsProposalActions: presentationContext.allowsProposalActions,
            tradeGoods: tradeGoods,
            listings: listings,
            goodsByID: goodsByID
        )
    }

    func openSchedule() {
        presentationState.openSchedule()
    }
}
