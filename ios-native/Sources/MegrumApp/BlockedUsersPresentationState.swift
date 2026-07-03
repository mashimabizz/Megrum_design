import Foundation
import MegrumCore

struct BlockedUsersPresentationState: Equatable {
    var userPendingUnblock: BlockedUser?
    var isShowingUnblockDialog = false

    var pendingUnblockUserID: UUID? {
        userPendingUnblock?.userID
    }

    mutating func requestUnblock(_ user: BlockedUser) {
        userPendingUnblock = user
        isShowingUnblockDialog = true
    }

    mutating func clearPendingUnblock() {
        userPendingUnblock = nil
    }
}
