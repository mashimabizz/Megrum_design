import Foundation
import MegrumCore

public struct MeguriMessageConversationKey: Hashable, Sendable {
    public var peerID: UUID
    public var sourceGroomPostID: UUID?

    public init(peerID: UUID, sourceGroomPostID: UUID? = nil) {
        self.peerID = peerID
        self.sourceGroomPostID = sourceGroomPostID
    }
}

public struct MeguriMessageThread: Identifiable, Hashable, Sendable {
    public var conversationKey: MeguriMessageConversationKey
    public var peerID: UUID
    public var sourceGroomPostID: UUID?
    public var sourceGroomOwnerID: UUID?
    public var sourceGroomImageURL: URL?
    public var displayName: String
    public var handle: String?
    public var avatarURL: URL?
    public var avatarID: String?
    public var usesPublicProfile: Bool
    public var lastMessage: MeguriMessage
    public var unreadCount: Int

    public var id: String {
        MeguriMessageReadStateReducer.threadID(for: conversationKey)
    }

    public var lastMessagePreview: String {
        if lastMessage.locked {
            return "\(SubscriptionCatalog.currentPremiumDisplayName)で表示できます"
        }
        if let body = lastMessage.body?.trimmingCharacters(in: .whitespacesAndNewlines), !body.isEmpty {
            // リプライ付きは引用メタ（不可視文字＋ID列）が本文に埋まっているため、
            // 返信本文だけを取り出してプレビューする。
            let replyBody = ChatReplyQuoteFormatter.parse(body).text
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return replyBody.isEmpty ? "メッセージ" : replyBody
        }
        return lastMessage.messageType == .image ? "画像が届きました" : "メッセージ"
    }

    public init(
        conversationKey: MeguriMessageConversationKey,
        peerID: UUID,
        sourceGroomPostID: UUID? = nil,
        sourceGroomOwnerID: UUID? = nil,
        sourceGroomImageURL: URL? = nil,
        displayName: String,
        handle: String? = nil,
        avatarURL: URL? = nil,
        avatarID: String? = nil,
        usesPublicProfile: Bool = false,
        lastMessage: MeguriMessage,
        unreadCount: Int = 0
    ) {
        self.conversationKey = conversationKey
        self.peerID = peerID
        self.sourceGroomPostID = sourceGroomPostID
        self.sourceGroomOwnerID = sourceGroomOwnerID
        self.sourceGroomImageURL = sourceGroomImageURL
        self.displayName = displayName
        self.handle = handle
        self.avatarURL = avatarURL
        self.avatarID = avatarID
        self.usesPublicProfile = usesPublicProfile
        self.lastMessage = lastMessage
        self.unreadCount = unreadCount
    }
}

public enum MeguriMessageReadStateReducer {
    public static func visibleMessages(
        _ messages: [MeguriMessage],
        viewerID: UUID,
        blockedUserIDs: Set<UUID>
    ) -> [MeguriMessage] {
        messages.filter { message in
            let peerID = message.senderID == viewerID ? message.recipientID : message.senderID
            return !blockedUserIDs.contains(peerID)
        }
    }

    public static func conversationThreads(
        from messages: [MeguriMessage],
        viewerID: UUID,
        publicProfilesByUserID: [UUID: PublicUserProfile] = [:],
        meguriProfilesByUserID: [UUID: MeguriProfile] = [:]
    ) -> [MeguriMessageThread] {
        let grouped = Dictionary(grouping: messages) { conversationKey(for: $0, viewerID: viewerID) }

        return grouped.compactMap { conversationKey, messages in
            let peerID = conversationKey.peerID
            guard let lastMessage = messages.max(by: { $0.createdAt < $1.createdAt }) else {
                return nil
            }
            let unreadCount = messages.filter { message in
                isUnreadIncoming(
                    message,
                    conversationKey: conversationKey,
                    viewerID: viewerID
                )
            }.count
            let identity = MeguriProfileIdentityResolver.identity(
                for: peerID,
                meguriProfile: meguriProfilesByUserID[peerID],
                publicProfile: publicProfilesByUserID[peerID],
                fallbackName: displayName(for: peerID, in: messages),
                fallbackHandle: handle(for: peerID, in: messages),
                fallbackAvatarURL: publicProfilesByUserID[peerID]?.profile.avatarURL
            )
            return MeguriMessageThread(
                conversationKey: conversationKey,
                peerID: peerID,
                sourceGroomPostID: conversationKey.sourceGroomPostID,
                sourceGroomOwnerID: lastMessage.sourceGroomOwnerID,
                sourceGroomImageURL: lastMessage.sourceGroomImageURL,
                displayName: identity.displayName,
                handle: identity.handle,
                avatarURL: identity.avatarURL,
                avatarID: identity.avatarID,
                usesPublicProfile: identity.usesPublicProfile,
                lastMessage: lastMessage,
                unreadCount: unreadCount
            )
        }
        .sorted { lhs, rhs in
            if lhs.unreadCount > 0, rhs.unreadCount == 0 {
                return true
            }
            if lhs.unreadCount == 0, rhs.unreadCount > 0 {
                return false
            }
            return lhs.lastMessage.createdAt > rhs.lastMessage.createdAt
        }
    }

    public static func threadID(for key: MeguriMessageConversationKey) -> String {
        let sourceID = key.sourceGroomPostID?.uuidString.lowercased() ?? "direct"
        return "\(key.peerID.uuidString.lowercased()):\(sourceID)"
    }

    /// バッジ用の未読数。一覧でローカル非表示（削除）にしたスレッドは、
    /// 一覧の表示と同じ基準（非表示後の新着があれば復活）で除外する。
    public static func unreadIncomingCount(
        _ messages: [MeguriMessage],
        viewerID: UUID,
        hiddenThreadEntries: [String: Date] = [:]
    ) -> Int {
        countableThreadMessages(
            messages,
            viewerID: viewerID,
            hiddenThreadEntries: hiddenThreadEntries
        ).reduce(0) { count, group in
            count + group.messages.filter { message in
                message.recipientID == viewerID
                    && message.senderID != viewerID
                    && message.readAt == nil
            }.count
        }
    }

    public static func pendingReplyThreadCount(
        _ messages: [MeguriMessage],
        viewerID: UUID,
        hiddenThreadEntries: [String: Date] = [:]
    ) -> Int {
        countableThreadMessages(
            messages,
            viewerID: viewerID,
            hiddenThreadEntries: hiddenThreadEntries
        ).reduce(0) { count, group in
            let needsReply = group.lastMessage.recipientID == viewerID
                && group.lastMessage.senderID != viewerID
            return needsReply ? count + 1 : count
        }
    }

    private static func countableThreadMessages(
        _ messages: [MeguriMessage],
        viewerID: UUID,
        hiddenThreadEntries: [String: Date]
    ) -> [(lastMessage: MeguriMessage, messages: [MeguriMessage])] {
        let grouped = Dictionary(grouping: messages) { conversationKey(for: $0, viewerID: viewerID) }
        return grouped.compactMap { key, messages in
            guard let lastMessage = messages.max(by: { $0.createdAt < $1.createdAt }) else {
                return nil
            }
            guard !MeguriHiddenThreadStore.isHidden(
                lastMessageAt: lastMessage.createdAt,
                hiddenAt: hiddenThreadEntries[threadID(for: key)]
            ) else {
                return nil
            }
            return (lastMessage, messages)
        }
    }

    public static func appendingSentMessage(
        _ message: MeguriMessage,
        to messages: [MeguriMessage]
    ) -> [MeguriMessage] {
        messages + [message]
    }

    public static func hasUnreadIncomingMessages(
        _ messages: [MeguriMessage],
        conversationKey: MeguriMessageConversationKey,
        viewerID: UUID
    ) -> Bool {
        messages.contains { message in
            isUnreadIncoming(
                message,
                conversationKey: conversationKey,
                viewerID: viewerID
            )
        }
    }

    public static func markIncomingMessagesRead(
        _ messages: [MeguriMessage],
        conversationKey: MeguriMessageConversationKey,
        viewerID: UUID,
        readAt: Date
    ) -> [MeguriMessage] {
        messages.map { message in
            guard isUnreadIncoming(
                message,
                conversationKey: conversationKey,
                viewerID: viewerID
            ) else {
                return message
            }

            var next = message
            next.readAt = readAt
            return next
        }
    }

    public static func mergingUpdated(
        _ messages: [MeguriMessage],
        updated: [MeguriMessage]
    ) -> [MeguriMessage] {
        guard !updated.isEmpty else {
            return messages
        }

        let updatedByID = Dictionary(uniqueKeysWithValues: updated.map { ($0.id, $0) })
        return messages.map { updatedByID[$0.id] ?? $0 }
    }

    private static func isUnreadIncoming(
        _ message: MeguriMessage,
        conversationKey: MeguriMessageConversationKey,
        viewerID: UUID
    ) -> Bool {
        message.senderID == conversationKey.peerID
            && message.recipientID == viewerID
            && message.sourceGroomPostID == conversationKey.sourceGroomPostID
            && message.readAt == nil
    }

    private static func conversationKey(
        for message: MeguriMessage,
        viewerID: UUID
    ) -> MeguriMessageConversationKey {
        MeguriMessageConversationKey(
            peerID: message.senderID == viewerID ? message.recipientID : message.senderID,
            sourceGroomPostID: message.sourceGroomPostID
        )
    }

    private static func displayName(
        for peerID: UUID,
        in messages: [MeguriMessage]
    ) -> String {
        for message in messages {
            if message.senderID == peerID, let name = message.senderDisplayName?.nilIfBlank {
                return name
            }
            if message.recipientID == peerID, let name = message.recipientDisplayName?.nilIfBlank {
                return name
            }
        }
        return "めぐりユーザー"
    }

    private static func handle(
        for peerID: UUID,
        in messages: [MeguriMessage]
    ) -> String? {
        for message in messages {
            if message.senderID == peerID, let handle = message.senderHandle?.nilIfBlank {
                return handle
            }
            if message.recipientID == peerID, let handle = message.recipientHandle?.nilIfBlank {
                return handle
            }
        }
        return nil
    }
}
