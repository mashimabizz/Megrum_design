import MegrumCore
import MegrumDesign
import SwiftUI

struct BoardThreadChatTimeline: View {
    var messages: [BoardThreadChatMessageDisplay]
    var isLoadingReplies: Bool
    var missingReplyContextMessage: String?
    var onReact: (BoardThreadChatMessageTarget, BoardMessageReaction?) -> Void

    var body: some View {
        LazyVStack(spacing: 12) {
            if let missingReplyContextMessage {
                MeguriNoticeBanner(message: missingReplyContextMessage)
                    .padding(.horizontal, 16)
            }

            ForEach(messages) { message in
                BoardThreadChatMessageRow(
                    message: message,
                    onReact: { reaction in
                        onReact(message.target, reaction)
                    }
                )
                .id(message.id)
            }

            if isLoadingReplies {
                BoardThreadDetailRepliesLoadingRow()
                    .padding(.top, 4)
            }
        }
    }
}

struct BoardThreadChatMessageRow: View {
    var message: BoardThreadChatMessageDisplay
    var onReact: (BoardMessageReaction?) -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if !message.isMine {
                BoardThreadDetailAvatar(
                    avatarID: message.avatarID,
                    imageURL: message.avatarURL,
                    initial: message.initial,
                    size: 30
                )
            }

            if message.isMine {
                Spacer(minLength: 0)
            }

            VStack(alignment: message.isMine ? .trailing : .leading, spacing: 4) {
                messageRow
                BoardMessageReactionBar(
                    goodCount: message.goodReactionCount,
                    badCount: message.badReactionCount,
                    selectedReaction: message.viewerReaction,
                    alignsTrailing: message.isMine,
                    onSelect: onReact
                )
            }

            if !message.isMine {
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 16)
    }

    private var messageRow: some View {
        HStack(alignment: .bottom, spacing: 6) {
            if message.isMine {
                messageTime
            }

            messageBubble

            if !message.isMine {
                messageTime
            }
        }
    }

    @ViewBuilder
    private var messageBubble: some View {
        if !message.imageURLs.isEmpty {
            richMessageBubble
        } else {
            textOnlyMessageBubble
        }
    }

    private var textOnlyMessageBubble: some View {
        ViewThatFits(in: .horizontal) {
            compactTextBubble
            wrappedTextBubble
        }
    }

    private var compactTextBubble: some View {
        Text(messageText)
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(message.isMine ? .white : MegrumTheme.ink)
            .multilineTextAlignment(message.isMine ? .trailing : .leading)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                message.isMine ? AnyShapeStyle(MegrumTheme.lavender) : AnyShapeStyle(.white.opacity(0.9)),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
    }

    private var wrappedTextBubble: some View {
        Text(messageText)
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(message.isMine ? .white : MegrumTheme.ink)
            .multilineTextAlignment(message.isMine ? .trailing : .leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(
                maxWidth: BoardThreadChatBubbleMetrics.maxWidth,
                alignment: message.isMine ? .trailing : .leading
            )
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                message.isMine ? AnyShapeStyle(MegrumTheme.lavender) : AnyShapeStyle(.white.opacity(0.9)),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
    }

    private var richMessageBubble: some View {
        VStack(alignment: message.isMine ? .trailing : .leading, spacing: 8) {
            Text(messageText)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(message.isMine ? .white : MegrumTheme.ink)
                .multilineTextAlignment(message.isMine ? .trailing : .leading)
                .fixedSize(horizontal: false, vertical: true)

            if !message.isDeleted, !message.imageURLs.isEmpty {
                BoardThreadChatImageGrid(imageURLs: message.imageURLs)
            }
        }
        .frame(maxWidth: BoardThreadChatBubbleMetrics.maxWidth, alignment: message.isMine ? .trailing : .leading)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            message.isMine ? AnyShapeStyle(MegrumTheme.lavender) : AnyShapeStyle(.white.opacity(0.9)),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
    }

    private var messageText: String {
        message.isDeleted ? "削除済みです" : message.body
    }

    private var messageTime: some View {
        Text(message.relativeTime)
            .font(.system(size: 10.5, weight: .bold, design: .rounded))
            .foregroundStyle(MegrumTheme.muted.opacity(0.82))
            .padding(.bottom, 3)
            .frame(minWidth: 28, alignment: message.isMine ? .trailing : .leading)
    }
}

private enum BoardThreadChatBubbleMetrics {
    static let maxWidth: CGFloat = 270
}

private struct BoardThreadChatImageGrid: View {
    var imageURLs: [URL]

    private var columns: [GridItem] {
        [
            GridItem(.flexible(minimum: 82), spacing: 6),
            GridItem(.flexible(minimum: 82), spacing: 6),
        ]
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(Array(imageURLs.prefix(4).enumerated()), id: \.offset) { _, url in
                AsyncImage(url: url, transaction: Transaction(animation: .smooth(duration: 0.18))) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        ZStack {
                            MegrumTheme.lavender.opacity(0.12)
                            Image(systemName: "photo")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(MegrumTheme.lavender.opacity(0.72))
                        }
                    }
                }
                .frame(width: imageURLs.count == 1 ? 180 : 86, height: imageURLs.count == 1 ? 180 : 86)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .frame(maxWidth: imageURLs.count == 1 ? 180 : 180, alignment: .leading)
    }
}

struct BoardMessageReactionBar: View {
    var goodCount: Int
    var badCount: Int
    var selectedReaction: BoardMessageReaction?
    var alignsTrailing: Bool
    var onSelect: (BoardMessageReaction?) -> Void

    var body: some View {
        HStack(spacing: 6) {
            reactionButton(
                reaction: .good,
                systemImage: "hand.thumbsup",
                selectedSystemImage: "hand.thumbsup.fill",
                count: goodCount
            )
            reactionButton(
                reaction: .bad,
                systemImage: "hand.thumbsdown",
                selectedSystemImage: "hand.thumbsdown.fill",
                count: badCount
            )
        }
        .frame(maxWidth: BoardThreadChatBubbleMetrics.maxWidth, alignment: alignsTrailing ? .trailing : .leading)
    }

    private func reactionButton(
        reaction: BoardMessageReaction,
        systemImage: String,
        selectedSystemImage: String,
        count: Int
    ) -> some View {
        let isSelected = selectedReaction == reaction
        return Button {
            onSelect(isSelected ? nil : reaction)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: isSelected ? selectedSystemImage : systemImage)
                    .font(.system(size: 12.5, weight: .black, design: .rounded))
                Text("\(max(0, count))")
                    .font(.system(size: 11.5, weight: .black, design: .rounded))
            }
            .foregroundStyle(isSelected ? .white : MegrumTheme.muted)
            .padding(.horizontal, 8)
            .frame(minWidth: 44, minHeight: 30)
            .background(
                isSelected ? AnyShapeStyle(MegrumTheme.lavender) : AnyShapeStyle(.white.opacity(0.82)),
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .strokeBorder(
                        isSelected ? .white.opacity(0.26) : MegrumTheme.ink.opacity(0.07),
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(reaction == .good ? "グッド" : "バッド")
        .accessibilityValue("\(max(0, count))件")
    }
}

struct BoardThreadReplyRow: View {
    var display: BoardReplyDisplay

    var body: some View {
        if display.isMine {
            BoardThreadMineReply(display: display)
        } else {
            HStack(alignment: .top, spacing: 10) {
                BoardThreadDetailAvatar(
                    avatarID: display.avatarID,
                    imageURL: display.avatarURL,
                    initial: display.initial,
                    size: 36
                )

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(display.displayName)
                            .font(.system(size: 13.5, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink)
                        Text(display.relativeTime)
                            .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                        Spacer()
                        Image(systemName: "ellipsis")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                    }

                    Text(display.reply.status == .deleted ? "削除済みです" : display.reply.body)
                        .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(MegrumTheme.ink.opacity(0.09), lineWidth: 1)
                        }

                    HStack(spacing: 5) {
                        Image(systemName: "clock")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                        Text(display.relativeTime)
                            .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                    }
                    .foregroundStyle(MegrumTheme.lavender)
                    .padding(.horizontal, 10)
                    .frame(height: 20)
                    .background(.white.opacity(0.92), in: Capsule())
                    .overlay(Capsule().strokeBorder(MegrumTheme.ink.opacity(0.09), lineWidth: 1))
                }
            }
        }
    }
}

private struct BoardThreadMineReply: View {
    var display: BoardReplyDisplay

    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text("あなた")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                    Text(display.relativeTime)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                    Spacer()
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }

                Text(display.reply.status == .deleted ? "削除済みです" : display.reply.body)
                    .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.86)
                    .padding(.horizontal, 14)
                    .frame(height: 34)
                    .background(.white.opacity(0.76), in: Capsule())
                    .overlay(Capsule().strokeBorder(MegrumTheme.lavender.opacity(0.20), lineWidth: 1))
            }
            .padding(9)
            .frame(width: 268)
            .background(MegrumTheme.lavender.opacity(0.09), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            HStack(spacing: 5) {
                Image(systemName: "checkmark.circle")
                Text(display.relativeTime)
            }
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(MegrumTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

struct BoardThreadDetailAvatarStack: View {
    var avatars: [BoardParticipantAvatar]

    var body: some View {
        HStack(spacing: -7) {
            ForEach(avatars.prefix(5)) { avatar in
                BoardThreadDetailAvatar(
                    avatarID: avatar.avatarID,
                    imageURL: avatar.avatarURL,
                    initial: avatar.initial,
                    size: 28
                )
                .overlay(Circle().stroke(.white, lineWidth: 1.5))
            }

            if avatars.count > 5 {
                Text("+\(avatars.count - 5)")
                    .font(.system(size: 13.5, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .frame(width: 38, height: 38)
                    .background(MegrumTheme.lavender.opacity(0.09), in: Circle())
            }
        }
    }
}

struct BoardThreadDetailAvatar: View {
    var avatarID: String?
    var imageURL: URL?
    var initial: String
    var size: CGFloat

    var body: some View {
        if let avatarID, !avatarID.isBlank {
            BoardAnonymousAvatar(
                option: BoardAnonymousAvatarOption.option(id: avatarID),
                size: size
            )
        } else {
        Circle()
            .fill(MegrumTheme.lavender.opacity(0.14))
            .frame(width: size, height: size)
            .overlay {
                if let imageURL {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case let .success(image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            fallbackInitial
                        default:
                            ProgressView()
                                .tint(MegrumTheme.lavender)
                        }
                    }
                    .clipShape(Circle())
                } else {
                    fallbackInitial
                }
            }
            .clipShape(Circle())
        }
    }

    private var fallbackInitial: some View {
        Text(initial)
            .font(.system(size: size * 0.38, weight: .black, design: .rounded))
            .foregroundStyle(MegrumTheme.lavender)
    }
}
