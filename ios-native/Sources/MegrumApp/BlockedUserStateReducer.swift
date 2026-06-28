import Foundation
import MegrumCore

public enum BlockedUserStateReducer {
    public static func upserting(
        _ user: BlockedUser,
        into blockedUsers: [BlockedUser]
    ) -> [BlockedUser] {
        var next = blockedUsers.filter { $0.userID != user.userID }
        next.insert(user, at: 0)
        return next
    }

    public static func removing(
        userID: UUID,
        from blockedUsers: [BlockedUser]
    ) -> [BlockedUser] {
        blockedUsers.filter { $0.userID != userID }
    }
}
