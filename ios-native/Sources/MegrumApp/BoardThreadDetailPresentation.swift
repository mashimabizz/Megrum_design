import Foundation
import MegrumCore

struct BoardThreadDetailPresentation {
    var authorName: String
    var authorAvatarURL: URL?
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
    var grooms: [GroomPost]

    func makePresentation(now: Date = Date()) -> BoardThreadDetailPresentation {
        BoardThreadDetailPresentation(
            authorName: authorDisplayName,
            authorAvatarURL: authorAvatarURL,
            authorInitial: authorInitial,
            authorRelativeTime: relativeTime(from: thread.createdAt, now: now),
            participantAvatars: participantAvatars,
            replies: replyRows(now: now),
            participantIDs: participantIDs
        )
    }

    private var authorDisplayName: String {
        if thread.authorID == viewer?.id {
            return viewer?.displayName ?? "あなた"
        }
        return profile(for: thread.authorID)?.displayName ?? "miki"
    }

    private var authorAvatarURL: URL? {
        profile(for: thread.authorID)?.avatarURL ?? fallbackGroomURL(index: 0)
    }

    private var authorInitial: String {
        authorDisplayName.first.map(String.init) ?? "話"
    }

    private var participantAvatars: [BoardParticipantAvatar] {
        participantIDs.enumerated().map { index, id in
            let profile = profile(for: id)
            let isMine = id == viewer?.id
            return BoardParticipantAvatar(
                id: id,
                avatarURL: profile?.avatarURL ?? fallbackGroomURL(index: index),
                initial: isMine ? "あ" : profile?.displayName.first.map(String.init) ?? fallbackParticipantName(index: index).first.map(String.init) ?? "話"
            )
        }
    }

    private var participantIDs: [UUID] {
        var seen = Set<UUID>()
        return ([thread.authorID] + replies.map(\.authorID)).filter { seen.insert($0).inserted }
    }

    private func replyRows(now: Date) -> [BoardReplyDisplay] {
        replies.enumerated().map { index, reply in
            let profile = profile(for: reply.authorID)
            let isMine = reply.authorID == viewer?.id
            return BoardReplyDisplay(
                reply: reply,
                displayName: isMine ? "あなた" : profile?.displayName ?? fallbackParticipantName(index: index),
                avatarURL: profile?.avatarURL ?? fallbackGroomURL(index: index + 1),
                initial: profile?.displayName.first.map(String.init) ?? fallbackParticipantName(index: index).first.map(String.init) ?? "話",
                isMine: isMine,
                relativeTime: relativeTime(from: reply.createdAt, now: now)
            )
        }
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
