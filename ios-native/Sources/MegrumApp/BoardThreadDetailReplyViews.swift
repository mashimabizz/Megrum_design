import MegrumCore
import MegrumDesign
import SwiftUI

struct BoardThreadChatTimeline: View {
    var messages: [BoardThreadChatMessageDisplay]
    var isLoadingReplies: Bool
    var missingReplyContextMessage: String?
    var onReact: (BoardThreadChatMessageTarget, BoardMessageReaction?) -> Void
    var onOpenImage: (URL) -> Void = { _ in }
    var onReply: (BoardThreadChatMessageDisplay) -> Void = { _ in }
    var onReport: (BoardThreadChatMessageDisplay) -> Void = { _ in }
    var onJumpToMessage: (UUID) -> Void = { _ in }

    var body: some View {
        LazyVStack(spacing: 8) {
            if let missingReplyContextMessage {
                MeguriNoticeBanner(message: missingReplyContextMessage)
                    .padding(.horizontal, 16)
            }

            ForEach(messages) { message in
                if let daySeparatorText = message.daySeparatorText {
                    BoardChatDaySeparatorLabel(text: daySeparatorText)
                }
                BoardThreadChatMessageRow(
                    message: message,
                    onReact: { reaction in
                        onReact(message.target, reaction)
                    },
                    onOpenImage: onOpenImage,
                    onJumpToMessage: onJumpToMessage
                )
                .chatMessageInteraction(
                    copyText: message.isDeleted ? nil : ChatReplyQuoteFormatter.copyText(of: message.body),
                    onReply: message.isDeleted ? nil : { onReply(message) },
                    onReport: message.isMine || message.isDeleted ? nil : { onReport(message) }
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
    var onOpenImage: (URL) -> Void
    var onJumpToMessage: (UUID) -> Void = { _ in }

    var body: some View {
        // .top 揃えにして「吹き出しがアイコンの真横、グッド/バッドはその下」になるようにする
        // （.bottom だとリアクションバーがアイコンの真横に来てしまう）。
        HStack(alignment: .top, spacing: 8) {
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

            VStack(alignment: message.isMine ? .trailing : .leading, spacing: 2) {
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
        if message.isDeleted || message.imageURLs.isEmpty {
            textOnlyMessageBubble
        } else {
            VStack(alignment: message.isMine ? .trailing : .leading, spacing: 6) {
                ForEach(Array(message.imageURLs.prefix(4).enumerated()), id: \.offset) { _, imageURL in
                    MeguriPhotoMessageBubble(photoURL: imageURL) { openedURL in
                        onOpenImage(openedURL)
                    }
                }

                if !message.body.isBlank {
                    textOnlyMessageBubble
                }
            }
        }
    }

    @ViewBuilder
    private var textOnlyMessageBubble: some View {
        if let replyQuote {
            VStack(alignment: .leading, spacing: 0) {
                ChatReplyQuoteLine(
                    quote: replyQuote,
                    isMine: message.isMine,
                    avatarID: nil,
                    avatarURL: nil,
                    onTap: replyQuote.messageID.map { messageID in
                        { onJumpToMessage(messageID) }
                    }
                )
                ViewThatFits(in: .horizontal) {
                    Text(messageText)
                        .fixedSize(horizontal: true, vertical: true)
                    Text(messageText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .multilineTextAlignment(.leading)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                message.isMine ? MegrumChatBubbleStyle.mineBackground : MegrumChatBubbleStyle.otherBackground,
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
        } else if messageText.contains("\n") {
            // 改行入りは「最長行の幅」にフィットさせる（収まらない長文だけ折返し）。
            ViewThatFits(in: .horizontal) {
                multilineHuggingTextBubble
                wrappedTextBubble
            }
        } else {
            ViewThatFits(in: .horizontal) {
                compactTextBubble
                wrappedTextBubble
            }
        }
    }

    private var compactTextBubble: some View {
        Text(messageText)
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)
            .multilineTextAlignment(message.isMine ? .trailing : .leading)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                message.isMine ? MegrumChatBubbleStyle.mineBackground : MegrumChatBubbleStyle.otherBackground,
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
    }

    /// 改行入りテキストを最長行の幅で抱えるバブル（ViewThatFits の第一候補）。
    private var multilineHuggingTextBubble: some View {
        Text(messageText)
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)
            .multilineTextAlignment(message.isMine ? .trailing : .leading)
            .fixedSize(horizontal: true, vertical: true)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                message.isMine ? MegrumChatBubbleStyle.mineBackground : MegrumChatBubbleStyle.otherBackground,
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
    }

    private var wrappedTextBubble: some View {
        Text(messageText)
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)
            .multilineTextAlignment(message.isMine ? .trailing : .leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                message.isMine ? MegrumChatBubbleStyle.mineBackground : MegrumChatBubbleStyle.otherBackground,
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
    }

    private var messageText: String {
        message.isDeleted ? "削除済みです" : ChatReplyQuoteFormatter.parse(message.body).text
    }

    private var replyQuote: ChatReplyQuote? {
        message.isDeleted ? nil : ChatReplyQuoteFormatter.parse(message.body).quote
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
            MegrumHaptics.performButtonTap {
                onSelect(isSelected ? nil : reaction)
            }
        } label: {
            HStack(spacing: 3) {
                // 背景を塗らず、選択時はアイコンの中を塗る
                Image(systemName: isSelected ? selectedSystemImage : systemImage)
                    .font(.system(size: 10.5, weight: .black, design: .rounded))
                    .foregroundStyle(isSelected ? MegrumTheme.lavender : MegrumTheme.muted)
                Text("\(max(0, count))")
                    .font(.system(size: 9.5, weight: .black, design: .rounded))
                    .foregroundStyle(isSelected ? MegrumTheme.lavender : MegrumTheme.muted)
            }
            .padding(.horizontal, 5)
            .frame(minWidth: 28, minHeight: 18)
            .contentShape(Capsule())
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

/// チャットルームの日付セパレータ（presentation 側で文言決定済み）。
private struct BoardChatDaySeparatorLabel: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .foregroundStyle(MegrumTheme.muted)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(MegrumTheme.ink.opacity(0.05), in: Capsule())
            .frame(maxWidth: .infinity)
            .padding(.vertical, 2)
    }
}
