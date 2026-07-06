import MegrumCore
import MegrumDesign
import SwiftUI

struct BoardReplyDisplay: Identifiable {
    var id: UUID { reply.id }
    var reply: BoardReply
    var displayName: String
    var avatarID: String?
    var avatarURL: URL?
    var initial: String
    var isMine: Bool
    var relativeTime: String
    var goodReactionCount: Int
    var badReactionCount: Int
    var viewerReaction: BoardMessageReaction?
}

enum BoardThreadChatMessageTarget: Hashable {
    case thread(UUID)
    case reply(UUID)
}

struct BoardThreadChatMessageDisplay: Identifiable {
    var target: BoardThreadChatMessageTarget
    var authorID: UUID
    var displayName: String
    var avatarID: String?
    var avatarURL: URL?
    var initial: String
    var isMine: Bool
    var body: String
    var imageURLs: [URL] = []
    var isDeleted: Bool
    var relativeTime: String
    var goodReactionCount: Int
    var badReactionCount: Int
    var viewerReaction: BoardMessageReaction?
    /// 日を跨いだ直前に挟むセパレータ（今日/昨日/M/d(曜)）。
    var daySeparatorText: String?

    var id: String {
        switch target {
        case .thread(let id):
            "thread-\(id.uuidString)"
        case .reply(let id):
            "reply-\(id.uuidString)"
        }
    }
}

struct BoardParticipantAvatar: Identifiable {
    var id: UUID
    var avatarID: String?
    var avatarURL: URL?
    var initial: String
}

struct BoardThreadDetailHeader: View {
    var title: String
    var onClose: () -> Void
    var onReport: () -> Void

    var body: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 23, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .frame(width: 44, height: 44, alignment: .leading)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(title)
                .font(.system(size: 23, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.76)

            Spacer()

            Button(action: onReport) {
                Image(systemName: "exclamationmark.bubble.fill")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .frame(width: 44, height: 44, alignment: .trailing)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("チャットルームを通報")
        }
    }
}

struct BoardThreadDetailCard: View {
    var thread: BoardThread
    var authorName: String
    var authorAvatarURL: URL?
    var authorAvatarID: String?
    var authorInitial: String
    var authorRelativeTime: String
    var replyCount: Int
    var participantAvatars: [BoardParticipantAvatar]
    var replies: [BoardReplyDisplay]
    var isLoadingReplies: Bool
    var missingReplyContextMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            BoardThreadDetailPostHeader(
                detailTagTitle: thread.detailTagTitle,
                title: thread.title,
                threadBody: thread.body,
                authorName: authorName,
                authorAvatarURL: authorAvatarURL,
                authorAvatarID: authorAvatarID,
                authorInitial: authorInitial,
                authorRelativeTime: authorRelativeTime,
                remainingTimeText: thread.remainingTimeText
            )

            BoardThreadDetailReplySummary(
                replyCount: replyCount,
                participantAvatars: participantAvatars
            )

            Divider()
                .background(MegrumTheme.ink.opacity(0.09))

            if let missingReplyContextMessage {
                MeguriNoticeBanner(message: missingReplyContextMessage)
            }

            BoardThreadDetailParticipantsHeader()

            BoardThreadDetailRepliesSection(
                replies: replies,
                isLoadingReplies: isLoadingReplies
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(MegrumTheme.ink.opacity(0.09), lineWidth: 1)
        }
    }
}

private extension BoardThread {
    var detailTagTitle: String {
        if title.contains("物販") {
            return "LE SSERAFIM"
        }
        if audience == .samePrefecture, let prefecture {
            return prefecture
        }
        return "同じ現場"
    }
}
