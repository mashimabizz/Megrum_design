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
    var participantIDs: [UUID]
}

struct BoardThreadDetailPresentationBuilder {
    var thread: BoardThread
    var replies: [BoardReply]
    var viewer: UserProfile?
    var profilesByUserID: [UUID: PublicUserProfile]
    var meguriProfilesByUserID: [UUID: MeguriProfile]
    var grooms: [GroomPost]

    func makePresentation(now: Date = Date()) -> BoardThreadDetailPresentation {
        BoardThreadDetailPresentation(
            authorName: authorDisplayName,
            authorAvatarURL: authorAvatarURL,
            authorAvatarID: authorAvatarID,
            authorInitial: authorInitial,
            authorRelativeTime: relativeTime(from: thread.createdAt, now: now),
            participantAvatars: participantAvatars,
            replies: replyRows(now: now),
            participantIDs: participantIDs
        )
    }

    private var authorDisplayName: String {
        if let anonymousName = thread.anonymousDisplayName, !anonymousName.isBlank {
            return anonymousName
        }
        if let name = meguriProfilesByUserID[thread.authorID]?.displayName.nilIfBlank {
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
        if isThreadAuthorAnonymous || meguriProfilesByUserID[thread.authorID] != nil {
            return nil
        }
        return profile(for: thread.authorID)?.avatarURL ?? fallbackGroomURL(index: 0)
    }

    private var authorAvatarID: String? {
        thread.anonymousAvatarID?.nilIfBlank ?? meguriProfilesByUserID[thread.authorID]?.avatarID
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
                avatarID: isAuthor ? authorAvatarID : meguriProfilesByUserID[id]?.avatarID,
                avatarURL: isAuthor && !isThreadAuthorAnonymous && meguriProfilesByUserID[id] == nil
                    ? profile(for: id)?.avatarURL ?? fallbackGroomURL(index: index)
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
            let showsPublicAuthorAvatar = reply.authorID == thread.authorID
                && !isThreadAuthorAnonymous
                && meguriProfilesByUserID[reply.authorID] == nil
            return BoardReplyDisplay(
                reply: reply,
                displayName: displayName,
                avatarID: meguriProfilesByUserID[reply.authorID]?.avatarID,
                avatarURL: showsPublicAuthorAvatar ? profile(for: reply.authorID)?.avatarURL ?? fallbackGroomURL(index: index + 1) : nil,
                initial: displayName.first.map(String.init) ?? "話",
                isMine: isMine,
                relativeTime: relativeTime(from: reply.createdAt, now: now)
            )
        }
    }

    private func participantDisplayName(for userID: UUID, fallbackIndex: Int) -> String {
        if userID == thread.authorID {
            return authorDisplayName
        }
        if userID == viewer?.id {
            return "あなた"
        }
        if let name = meguriProfilesByUserID[userID]?.displayName.nilIfBlank {
            return name
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

    private func fallbackGroomURL(index: Int) -> URL? {
        guard !grooms.isEmpty else { return nil }
        return grooms[index % grooms.count].imageURL
    }

    private func fallbackParticipantName(index: Int) -> String {
        ["yuna", "haru", "saku", "miki"][index % 4]
    }

    private func relativeTime(from date: Date, now: Date) -> String {
        let elapsed = max(0, now.timeIntervalSince(date))
        if elapsed < 60 {
            return "たった今"
        }
        if elapsed < 3_600 {
            return "\(Int(elapsed / 60))分前"
        }
        if elapsed < 86_400 {
            return "\(Int(elapsed / 3_600))時間前"
        }
        return date.formatted(date: .numeric, time: .omitted)
    }
}
