import Foundation
import MegrumCore

public enum GroomInteractionStateReducer {
    public static func markingViewed(
        postID: UUID,
        in viewedIDs: Set<UUID>
    ) -> Set<UUID> {
        var next = viewedIDs
        next.insert(postID)
        return next
    }

    public static func settingLiked(
        postID: UUID,
        isLiked: Bool,
        in likedIDs: Set<UUID>
    ) -> Set<UUID> {
        var next = likedIDs
        if isLiked {
            next.insert(postID)
        } else {
            next.remove(postID)
        }
        return next
    }

    public static func visibleViewedIDs(
        _ viewedIDs: Set<UUID>,
        in posts: [GroomPost]
    ) -> Set<UUID> {
        viewedIDs.intersection(Set(posts.map(\.id)))
    }

    public static func likedIDs(from posts: [GroomPost]) -> Set<UUID> {
        Set(posts.filter(\.liked).map(\.id))
    }
}
