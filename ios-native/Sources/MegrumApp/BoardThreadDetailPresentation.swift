import Foundation
import MegrumCore

struct BoardThreadDetailPresentation {
    var authorName: String
    var authorAvatarURL: URL?
    var authorAvatarID: String?
    var authorInitial: String
    var authorRelativeTime: String
    var participantAvatars: [BoardParticipantAvatar]
    var replies: [BoardReplyDisplay]
    var chatMessages: [BoardThreadChatMessageDisplay]
    var participantIDs: [UUID]
}

struct BoardThreadDetailPresentationBuilder {
    var thread: BoardThread
    var replies: [BoardReply]
    var viewer: UserProfile?
    var profilesByUserID: [UUID: PublicUserProfile]
    var grooms: [GroomPost]

    /// 部屋ごとの参加者アイデンティティ（返信の anonymous_* の最新値）。
    private var roomIdentityByUserID: [UUID: (name: String?, avatarID: String?)] {
        var result: [UUID: (name: String?, avatarID: String?)] = [:]
        for reply in replies.sorted(by: { $0.createdAt < $1.createdAt }) {
            let name = reply.anonymousDisplayName?.nilIfBlank
            let avatarID = reply.anonymousAvatarID?.nilIfBlank
            if name != nil || avatarID != nil {
                let existing = result[reply.authorID]
                result[reply.authorID] = (name ?? existing?.name, avatarID ?? existing?.avatarID)
            }
        }
        return result
    }

    private func roomIdentityName(for userID: UUID) -> String? {
        roomIdentityByUserID[userID]?.name
    }

    private func roomIdentityAvatarID(for userID: UUID) -> String? {
        roomIdentityByUserID[userID]?.avatarID
    }

    func makePresentation(now: Date = Date()) -> BoardThreadDetailPresentation {
        BoardThreadDetailPresentation(
            authorName: authorDisplayName,
            authorAvatarURL: authorAvatarURL,
            authorAvatarID: authorAvatarID,
            authorInitial: authorInitial,
            authorRelativeTime: relativeTime(from: thread.createdAt, now: now),
            participantAvatars: participantAvatars,
            replies: replyRows(now: now),
            chatMessages: chatMessages(now: now),
            participantIDs: participantIDs
        )
    }

    private var authorDisplayName: String {
        if let anonymousName = thread.anonymousDisplayName, !anonymousName.isBlank {
            return anonymousName
        }
        if let name = roomIdentityName(for: thread.authorID) {
            return name
        }
        if isThreadAuthorAnonymous {
            return "匿名さん"
        }
        if thread.authorID == viewer?.id {
            return viewer?.displayName ?? "あなた"
        }
        return profile(for: thread.authorID)?.displayName ?? "miki"
    }

    private var authorAvatarURL: URL? {
        if isThreadAuthorAnonymous {
            return nil
        }
        if roomIdentityAvatarID(for: thread.authorID) != nil {
            return nil
        }
        return profile(for: thread.authorID)?.avatarURL ?? fallbackGroomURL(index: 0)
    }

    private var authorAvatarID: String? {
        thread.anonymousAvatarID?.nilIfBlank ?? roomIdentityAvatarID(for: thread.authorID)
    }

    private var authorInitial: String {
        authorDisplayName.first.map(String.init) ?? "話"
    }

    private var isThreadAuthorAnonymous: Bool {
        thread.anonymousDisplayName?.isBlank == false || thread.anonymousAvatarID?.isBlank == false
    }

    private var participantAvatars: [BoardParticipantAvatar] {
        participantIDs.enumerated().map { index, id in
            let isMine = id == viewer?.id
            let isAuthor = id == thread.authorID
            let displayName = participantDisplayName(for: id, fallbackIndex: index)
            return BoardParticipantAvatar(
                id: id,
                avatarID: isAuthor ? authorAvatarID : roomIdentityAvatarID(for: id),
                avatarURL: isAuthor
                    ? avatarURL(
                        for: id,
                        fallbackIndex: index,
                        isThreadAuthorAnonymous: isThreadAuthorAnonymous
                    )
                    : nil,
                initial: isAuthor ? authorInitial : isMine ? "あ" : displayName.first.map(String.init) ?? "話"
            )
        }
    }

    private var participantIDs: [UUID] {
        var seen = Set<UUID>()
        return ([thread.authorID] + replies.map(\.authorID)).filter { seen.insert($0).inserted }
    }

    private func replyRows(now: Date) -> [BoardReplyDisplay] {
        replies.enumerated().map { index, reply in
            let isMine = reply.authorID == viewer?.id
            let displayName = participantDisplayName(for: reply.authorID, fallbackIndex: index + 1)
            let replyAvatarID = reply.anonymousAvatarID?.nilIfBlank ?? roomIdentityAvatarID(for: reply.authorID)
            let showsPublicAuthorAvatar = reply.authorID == thread.authorID
                && !isThreadAuthorAnonymous
                && replyAvatarID == nil
            return BoardReplyDisplay(
                reply: reply,
                displayName: displayName,
                avatarID: replyAvatarID,
                avatarURL: showsPublicAuthorAvatar
                    ? profile(for: reply.authorID)?.avatarURL ?? fallbackGroomURL(index: index + 1)
                    : nil,
                initial: displayName.first.map(String.init) ?? "話",
                isMine: isMine,
                relativeTime: relativeTime(from: reply.createdAt, now: now),
                goodReactionCount: max(0, reply.goodReactionCount ?? 0),
                badReactionCount: max(0, reply.badReactionCount ?? 0),
                viewerReaction: reply.viewerReaction
            )
        }
    }

    private func chatMessages(now: Date) -> [BoardThreadChatMessageDisplay] {
        let opening = BoardThreadChatMessageDisplay(
            target: .thread(thread.id),
            authorID: thread.authorID,
            displayName: authorDisplayName,
            avatarID: authorAvatarID,
            avatarURL: authorAvatarURL,
            initial: authorInitial,
            isMine: thread.authorID == viewer?.id,
            body: thread.body,
            imageURLs: [],
            isDeleted: thread.status != "visible",
            relativeTime: relativeTime(from: thread.createdAt, now: now),
            goodReactionCount: max(0, thread.goodReactionCount ?? 0),
            badReactionCount: max(0, thread.badReactionCount ?? 0),
            viewerReaction: thread.viewerReaction
        )
        var previousDate = thread.createdAt
        let replyMessages = replyRows(now: now).map { reply -> BoardThreadChatMessageDisplay in
            let separator = ChatTimestampFormatter.startsNewDay(reply.reply.createdAt, after: previousDate)
                ? ChatTimestampFormatter.daySeparatorText(for: reply.reply.createdAt, now: now)
                : nil
            previousDate = reply.reply.createdAt
            return BoardThreadChatMessageDisplay(
                target: .reply(reply.reply.id),
                authorID: reply.reply.authorID,
                displayName: reply.displayName,
                avatarID: reply.avatarID,
                avatarURL: reply.avatarURL,
                initial: reply.initial,
                isMine: reply.isMine,
                body: reply.reply.body,
                imageURLs: reply.reply.imageURLs ?? [],
                isDeleted: reply.reply.status == .deleted,
                relativeTime: reply.relativeTime,
                goodReactionCount: reply.goodReactionCount,
                badReactionCount: reply.badReactionCount,
                viewerReaction: reply.viewerReaction,
                daySeparatorText: separator
            )
        }
        var openingMessage = opening
        openingMessage.daySeparatorText = ChatTimestampFormatter.daySeparatorText(for: thread.createdAt, now: now)
        return [openingMessage] + replyMessages
    }

    private func participantDisplayName(for userID: UUID, fallbackIndex: Int) -> String {
        if userID == thread.authorID {
            return authorDisplayName
        }
        if let name = roomIdentityName(for: userID) {
            return name
        }
        if userID == viewer?.id {
            return "あなた"
        }
        return anonymousParticipantName(for: userID, fallbackIndex: fallbackIndex)
    }

    private func anonymousParticipantName(for userID: UUID, fallbackIndex: Int) -> String {
        let participantIndex = participantIDs.firstIndex(of: userID) ?? fallbackIndex
        return fallbackParticipantName(index: max(0, participantIndex - 1))
    }

    private func profile(for userID: UUID) -> UserProfile? {
        if userID == viewer?.id {
            return viewer
        }
        return profilesByUserID[userID]?.profile
    }

    private func avatarURL(
        for userID: UUID,
        fallbackIndex: Int,
        isThreadAuthorAnonymous: Bool
    ) -> URL? {
        if isThreadAuthorAnonymous {
            return nil
        }
        if roomIdentityAvatarID(for: userID) != nil {
            return nil
        }
        return profile(for: userID)?.avatarURL ?? fallbackGroomURL(index: fallbackIndex)
    }

    private func fallbackGroomURL(index: Int) -> URL? {
        guard !grooms.isEmpty else { return nil }
        return grooms[index % grooms.count].imageURL
    }

    private func fallbackParticipantName(index: Int) -> String {
        ["yuna", "haru", "saku", "miki"][index % 4]
    }

    private func relativeTime(from date: Date, now: Date) -> String {
        ChatTimestampFormatter.timeText(for: date, now: now)
    }
}
