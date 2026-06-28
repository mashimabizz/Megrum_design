import Foundation
import MegrumCore

struct MegrumAppInitialSnapshotState {
    var viewer: UserProfile
    var inventory: [GoodsItem]
    var wishes: [WishItem]
    var listings: [IndividualListing]
    var proposals: [TradeProposal]
    var grooms: [GroomPost]
    var groomMapPosts: [GroomPost]
    var viewedGroomIDs: Set<UUID>
    var likedGroomIDs: Set<UUID>
    var threads: [BoardThread]
    var subscriptionState: UserSubscriptionState

    init(snapshot: MegrumAppSnapshot, previousViewedGroomIDs: Set<UUID>) {
        self.viewer = snapshot.viewer
        self.inventory = snapshot.inventory
        self.wishes = snapshot.wishes
        self.listings = snapshot.listings
        self.proposals = snapshot.proposals
        self.grooms = snapshot.grooms
        self.groomMapPosts = snapshot.grooms
        self.viewedGroomIDs = GroomInteractionStateReducer.visibleViewedIDs(
            previousViewedGroomIDs,
            in: snapshot.grooms
        )
        self.likedGroomIDs = GroomInteractionStateReducer.likedIDs(from: snapshot.grooms)
        self.threads = snapshot.threads
        self.subscriptionState = snapshot.subscriptionState
    }
}
