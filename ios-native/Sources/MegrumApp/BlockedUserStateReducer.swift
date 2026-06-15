import Foundation
import MegrumCore

public enum BlockedUserStateReducer {
    public static func removing(
        userID: UUID,
        from blockedUsers: [BlockedUser]
    ) -> [BlockedUser] {
        blockedUsers.filter { $0.userID != userID }
    }
}
