import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct MeguriMessageList: View {
    var messages: [MeguriMessage]
    var viewerID: UUID?
    var isLoading: Bool
    var canReadIncomingMessages: Bool
    var peerAvatarID: String?
    var peerAvatarURL: URL?
    var peerFallback: String
    var onOpenPremium: () -> Void = {}
    var onOpenPeerProfile: () -> Void = {}
    var onOpenImage: (URL) -> Void = { _ in }
    var onReply: (MeguriMessage) -> Void = { _ in }
    var onReport: (MeguriMessage) -> Void = { _ in }
    var onJumpToMessage: (UUID) -> Void = { _ in }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if isLoading {
                        MeguriMessageLoadingRow()
                    } else if messages.isEmpty {
                        MeguriMessageEmptyState()
                    } else {
                        ForEach(Array(messages.enumerated()), id: \.element.id) { index, message in
                            if ChatTimestampFormatter.startsNewDay(
                                message.createdAt,
                                after: index > 0 ? messages[index - 1].createdAt : nil
                            ) {
                                ChatDaySeparator(date: message.createdAt)
                            }
                            MeguriMessageBubble(
                                onJumpToMessage: onJumpToMessage,
                                message: message,
                                viewerID: viewerID,
                                isMine: message.senderID == viewerID,
                                canReadIncomingMessages: canReadIncomingMessages,
                                peerAvatarID: peerAvatarID,
                                peerAvatarURL: peerAvatarURL,
                                peerFallback: peerFallback,
                                onOpenPremium: onOpenPremium,
                                onOpenPeerProfile: onOpenPeerProfile,
                                onOpenImage: onOpenImage
                            )
                            .chatMessageInteraction(
                                copyText: (message.body?.nilIfBlank).map(ChatReplyQuoteFormatter.copyText(of:)),
                                onReply: message.body?.nilIfBlank != nil || message.imageURL != nil
                                    ? { onReply(message) }
                                    : nil,
                                onReport: message.senderID == viewerID ? nil : { onReport(message) }
                            )
                            .id(message.id)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity)
                // メッセージが少ないうちは1通目が一番上に来るよう常に上寄せ。
                // 画面を超える量になったら onChange の scrollTo で最新が見える。
                .frame(
                    minHeight: proxy.size.height,
                    alignment: .top
                )
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

private struct MeguriMessageLoadingRow: View {
    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
                .controlSize(.small)
            Text("読み込んでいます")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MegrumTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 12)
    }
}

private struct MeguriMessageEmptyState: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("まだメッセージはありません")
                .font(.headline.weight(.bold))
                .foregroundStyle(MegrumTheme.ink)
            Text("グルームへの返信から、そのまま会話を始められます。")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MegrumTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 12)
    }
}

struct MeguriMessageBubble: View {
    var onJumpToMessage: (UUID) -> Void = { _ in }
    var message: MeguriMessage
    var viewerID: UUID?
    var isMine: Bool
    var canReadIncomingMessages: Bool
    var peerAvatarID: String?
    var peerAvatarURL: URL?
    var peerFallback: String
    var onOpenPremium: () -> Void = {}
    var onOpenPeerProfile: () -> Void = {}
    var onOpenImage: (URL) -> Void = { _ in }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if !isMine {
                Button(action: onOpenPeerProfile) {
                    MeguriProfileAvatarView(
                        avatarID: peerAvatarID,
                        avatarURL: peerAvatarURL,
                        fallback: peerFallback,
                        size: 30
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(peerFallback)のプロフィールを開く")
            }

            if isMine {
                Spacer(minLength: 0)
            }

            messageRow

            if !isMine {
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: isMine ? .trailing : .leading)
    }

    private var messageRow: some View {
        HStack(alignment: .bottom, spacing: 6) {
            if isMine {
                MeguriMessageMeta(message: message, isMine: isMine)
            }

            messageContentStack

            if !isMine {
                MeguriMessageMeta(message: message, isMine: isMine)
            }
        }
    }

    private var messageContentStack: some View {
        VStack(alignment: isMine ? .trailing : .leading, spacing: 4) {
            if let sourceGroomImageURL = message.sourceGroomImageURL {
                MeguriGroomReplyContextCard(
                    imageURL: sourceGroomImageURL,
                    messageCreatedAt: message.createdAt,
                    title: groomContextTitle,
                    isMine: isMine
                )
            }
            if shouldMosaic {
                MeguriLockedMessageBubbleContent(
                    text: lockedMessageText,
                    onOpenPremium: onOpenPremium
                )
            } else {
                visibleMessageContent
            }
        }
    }

    private var shouldMosaic: Bool {
        !isMine && (message.locked || !canReadIncomingMessages)
    }

    private var groomContextTitle: String {
        if let viewerID, message.sourceGroomOwnerID == viewerID {
            return "あなたのグルームに返信しました"
        }
        return isMine ? "グルームに返信しました" : "グルームへの返信"
    }

    private var lockedMessageText: String {
        if let body = message.body?.nilIfBlank {
            return body
        }
        return message.messageType == .image ? "画像が届いています" : "メッセージが届いています"
    }

    private var messageText: String {
        if message.locked {
            return lockedMessageText
        }
        if let body = message.body, !body.isEmpty {
            return body
        }
        return message.messageType == .image ? "画像" : ""
    }

    @ViewBuilder
    private var visibleMessageContent: some View {
        if message.messageType == .image {
            MeguriPhotoMessageBubble(photoURL: message.imageURL, onOpenImage: onOpenImage)
            if let body = message.body?.nilIfBlank {
                textBubble(body)
            }
        } else {
            textBubble(messageText)
        }
    }

    @ViewBuilder
    private func textBubble(_ text: String) -> some View {
        let parsed = ChatReplyQuoteFormatter.parse(text)
        if let quote = parsed.quote, !message.locked {
            VStack(alignment: .leading, spacing: 0) {
                ChatReplyQuoteLine(
                    quote: quote,
                    isMine: isMine,
                    avatarID: quote.senderID == viewerID ? nil : peerAvatarID,
                    avatarURL: quote.senderID == viewerID ? nil : peerAvatarURL,
                    onTap: quote.messageID.map { messageID in
                        { onJumpToMessage(messageID) }
                    }
                )
                ViewThatFits(in: .horizontal) {
                    Text(parsed.text)
                        .fixedSize(horizontal: true, vertical: true)
                    Text(parsed.text)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .multilineTextAlignment(.leading)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                isMine ? MegrumChatBubbleStyle.mineBackground : MegrumChatBubbleStyle.otherBackground,
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
        } else if text.contains("\n") {
            // 改行入りは「最長行の幅」にフィットさせる（収まらない長文だけ折返し）。
            ViewThatFits(in: .horizontal) {
                multilineHuggingTextBubble(text)
                wrappedTextBubble(text)
            }
        } else {
            ViewThatFits(in: .horizontal) {
                compactTextBubble(text)
                wrappedTextBubble(text)
            }
        }
    }

    private func compactTextBubble(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)
            .multilineTextAlignment(isMine ? .trailing : .leading)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                isMine ? MegrumChatBubbleStyle.mineBackground : MegrumChatBubbleStyle.otherBackground,
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
    }

    /// 改行入りテキストを最長行の幅で抱えるバブル（ViewThatFits の第一候補）。
    private func multilineHuggingTextBubble(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)
            .multilineTextAlignment(isMine ? .trailing : .leading)
            .fixedSize(horizontal: true, vertical: true)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                isMine ? MegrumChatBubbleStyle.mineBackground : MegrumChatBubbleStyle.otherBackground,
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
    }

    private func wrappedTextBubble(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)
            .multilineTextAlignment(isMine ? .trailing : .leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                isMine ? MegrumChatBubbleStyle.mineBackground : MegrumChatBubbleStyle.otherBackground,
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
    }
}

private struct MeguriGroomReplyContextCard: View {
    var imageURL: URL
    var messageCreatedAt: Date
    var title: String
    var isMine: Bool

    @Environment(\.groomContextImageURLResolver) private var resolver
    @State private var resolvedURL: URL?
    @State private var isUnavailable = false

    var body: some View {
        // グルームが失効している（24時間超 or 再署名不可）場合は枠ごと出さない。
        if !isUnavailable {
            card
                .task(id: imageURL) {
                    await resolveImageURL()
                }
        }
    }

    private func resolveImageURL() async {
        if GroomContextCardPolicy.isCertainlyExpired(messageCreatedAt: messageCreatedAt) {
            isUnavailable = true
            return
        }
        if let fresh = await resolver(imageURL) {
            resolvedURL = fresh
        } else {
            isUnavailable = true
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(isMine ? .white.opacity(0.92) : MegrumTheme.ink.opacity(0.82))

            Group {
                if let resolvedURL {
                    AsyncImage(url: resolvedURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            GroomImageFailureView(
                                message: "画像を読み込めませんでした",
                                foregroundColor: isMine ? .white.opacity(0.84) : MegrumTheme.muted
                            )
                        default:
                            MegrumTheme.sky.opacity(isMine ? 0.20 : 0.12)
                                .overlay {
                                    ProgressView()
                                        .controlSize(.small)
                                }
                        }
                    }
                } else {
                    MegrumTheme.sky.opacity(isMine ? 0.20 : 0.12)
                        .overlay {
                            ProgressView()
                                .controlSize(.small)
                        }
                }
            }
            .frame(width: 156, height: 196)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(10)
        .background(
            isMine ? AnyShapeStyle(MegrumTheme.lavender.opacity(0.92)) : AnyShapeStyle(.white.opacity(0.92)),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isMine ? .white.opacity(0.24) : MegrumTheme.lavender.opacity(0.12), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

struct MeguriMessageMeta: View {
    var message: MeguriMessage
    var isMine: Bool

    var body: some View {
        Text(ChatTimestampFormatter.timeText(for: message.createdAt))
            .font(.system(size: 10.5, weight: .bold, design: .rounded))
            .foregroundStyle(MegrumTheme.muted.opacity(0.82))
            .padding(.bottom, 3)
            .frame(minWidth: 28, alignment: isMine ? .trailing : .leading)
    }
}

struct MeguriPhotoMessageBubble: View {
    var photoURL: URL?
    var onOpenImage: (URL) -> Void

    private let thumbnailSize = CGSize(width: 150, height: 150)

    var body: some View {
        Group {
            if let photoURL {
                // Button だと指が横へ動いても touch-up で発火してしまい、
                // 左スワイプリプライの離し際に画像が開いてしまう。
                // TapGesture は指の移動でキャンセルされるためスワイプと共存できる。
                thumbnailContent(photoURL: photoURL)
                    .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .onTapGesture {
                        onOpenImage(photoURL)
                    }
            } else {
                photoPlaceholderContent
            }
        }
        .frame(width: thumbnailSize.width, height: thumbnailSize.height)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(alignment: .topLeading) {
            Label("写真", systemImage: "photo.fill")
                .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(.black.opacity(0.46), in: Capsule())
                .padding(7)
        }
        .accessibilityLabel(photoURL == nil ? "写真を表示できません" : "写真を拡大表示")
    }

    private func thumbnailContent(photoURL: URL) -> some View {
        Group {
            if photoURL.isFileURL {
                LocalURLImage(url: photoURL, contentMode: .fill) {
                    photoPlaceholderContent
                }
            } else {
                AsyncImage(url: photoURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        photoPlaceholderContent
                    case .empty:
                        MegrumTheme.sky.opacity(0.12)
                            .overlay {
                                ProgressView()
                            }
                    @unknown default:
                        Color.clear
                    }
                }
            }
        }
    }

    private var photoPlaceholderContent: some View {
        MegrumTheme.sky.opacity(0.16)
            .overlay {
                VStack(spacing: 6) {
                    Image(systemName: "photo")
                        .font(.system(size: 22, weight: .bold))
                    Text("写真")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                }
                .foregroundStyle(MegrumTheme.muted)
            }
    }
}

struct MeguriMessageInput: View {
    @Binding var text: String
    var isSending: Bool
    var canUseCamera: Bool
    var onOpenCamera: () -> Void
    var onOpenPhotoLibrary: () -> Void
    var onSend: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Menu {
#if os(iOS)
                Button(action: onOpenCamera) {
                    Label("写真を撮る", systemImage: "camera.fill")
                }
                .disabled(!canUseCamera || isSending)
#endif

                Button(action: onOpenPhotoLibrary) {
                    Label("アルバムから選ぶ", systemImage: "photo.on.rectangle")
                }
                .disabled(isSending)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundStyle(MegrumTheme.ink)
                    .frame(width: 38, height: 38)
                    .background(.white.opacity(0.9), in: Circle())
            }
            .accessibilityLabel("メッセージ操作")

            TextField("メッセージ", text: $text, axis: .vertical)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .lineLimit(1...4)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            Button(action: onSend) {
                Group {
                    if isSending {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 17, weight: .heavy))
                    }
                }
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(MegrumTheme.lavender, in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(text.isBlank || isSending)
            .opacity(text.isBlank ? 0.45 : 1)
            .accessibilityLabel("送信")
        }
    }
}
