import Foundation
import MegrumCore

public enum MeguriFeedStateReducer {
    public static func upsertingGroomPost(
        _ post: GroomPost,
        into posts: [GroomPost]
    ) -> [GroomPost] {
        var next = posts
        next.removeAll { $0.id == post.id }
        next.insert(post, at: 0)
        return next
    }

    public static func upsertingBoardThread(
        _ thread: BoardThread,
        into threads: [BoardThread]
    ) -> [BoardThread] {
        var next = threads
        next.removeAll { $0.id == thread.id }
        next.insert(thread, at: 0)
        return next
    }
}
