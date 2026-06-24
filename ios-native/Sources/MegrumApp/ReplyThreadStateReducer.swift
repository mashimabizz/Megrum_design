import Foundation
import MegrumCore

public enum ReplyThreadStateReducer {
    public static func replacingBoardReplies(
        in repliesByThreadID: [UUID: [BoardReply]],
        threadID: UUID,
        replies: [BoardReply]
    ) -> [UUID: [BoardReply]] {
        var next = repliesByThreadID
        next[threadID] = replies
        return next
    }

    public static func appendingBoardReply(
        _ reply: BoardReply,
        to repliesByThreadID: [UUID: [BoardReply]],
        threadID: UUID
    ) -> [UUID: [BoardReply]] {
        var next = repliesByThreadID
        next[threadID] = (next[threadID] ?? []) + [reply]
        return next
    }

    public static func appendingGroomReply(
        _ reply: GroomReply,
        to repliesByPostID: [UUID: [GroomReply]],
        postID: UUID
    ) -> [UUID: [GroomReply]] {
        var next = repliesByPostID
        next[postID] = (next[postID] ?? []) + [reply]
        return next
    }

    public static func mergingGroomReplies(
        _ replies: [GroomReply],
        into repliesByPostID: [UUID: [GroomReply]]
    ) -> [UUID: [GroomReply]] {
        var next = repliesByPostID
        for (postID, postReplies) in Dictionary(grouping: replies, by: \.groomPostID) {
            next[postID] = postReplies.sorted { $0.createdAt > $1.createdAt }
        }
        return next
    }
}
