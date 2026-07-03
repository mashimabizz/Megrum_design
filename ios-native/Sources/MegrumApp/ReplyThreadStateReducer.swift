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

    public static func settingBoardThreadReaction(
        _ reaction: BoardMessageReaction?,
        threadID: UUID,
        in threads: [BoardThread]
    ) -> [BoardThread] {
        threads.map { thread in
            guard thread.id == threadID else {
                return thread
            }
            var next = thread
            next.applyBoardReaction(reaction)
            return next
        }
    }

    public static func settingBoardReplyReaction(
        _ reaction: BoardMessageReaction?,
        replyID: UUID,
        in repliesByThreadID: [UUID: [BoardReply]]
    ) -> [UUID: [BoardReply]] {
        var next = repliesByThreadID
        for (threadID, replies) in repliesByThreadID {
            next[threadID] = replies.map { reply in
                guard reply.id == replyID else {
                    return reply
                }
                var nextReply = reply
                nextReply.applyBoardReaction(reaction)
                return nextReply
            }
        }
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

private extension BoardThread {
    mutating func applyBoardReaction(_ reaction: BoardMessageReaction?) {
        let current = BoardReactionCounts(
            good: goodReactionCount ?? 0,
            bad: badReactionCount ?? 0,
            viewerReaction: viewerReaction
        )
        let updated = current.applying(reaction)
        goodReactionCount = updated.good
        badReactionCount = updated.bad
        viewerReaction = reaction
    }
}

private extension BoardReply {
    mutating func applyBoardReaction(_ reaction: BoardMessageReaction?) {
        let current = BoardReactionCounts(
            good: goodReactionCount ?? 0,
            bad: badReactionCount ?? 0,
            viewerReaction: viewerReaction
        )
        let updated = current.applying(reaction)
        goodReactionCount = updated.good
        badReactionCount = updated.bad
        viewerReaction = reaction
    }
}

private struct BoardReactionCounts {
    var good: Int
    var bad: Int
    var viewerReaction: BoardMessageReaction?

    func applying(_ nextReaction: BoardMessageReaction?) -> BoardReactionCounts {
        var next = self
        switch viewerReaction {
        case .good:
            next.good = max(0, next.good - 1)
        case .bad:
            next.bad = max(0, next.bad - 1)
        case nil:
            break
        }

        switch nextReaction {
        case .good:
            next.good += 1
        case .bad:
            next.bad += 1
        case nil:
            break
        }
        next.viewerReaction = nextReaction
        return next
    }
}
