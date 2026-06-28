import Foundation
import MegrumCore

public struct MeguriMessageThread: Identifiable, Hashable, Sendable {
    public var peerID: UUID
    public var displayName: String
    public var handle: String?
    public var avatarURL: URL?
    public var avatarID: String?
    public var lastMessage: MeguriMessage
    public var unreadCount: Int

    public var id: UUID { peerID }

    public var lastMessagePreview: String {
        if lastMessage.locked {
            return "このメッセージは現在表示できません"
        }
        if let body = lastMessage.body?.trimmingCharacters(in: .whitespacesAndNewlines), !body.isEmpty {
            return body
        }
        return lastMessage.messageType == .image ? "画像が届きました" : "メッセージ"
    }

    public init(
        peerID: UUID,
        displayName: String,
        handle: String? = nil,
        avatarURL: URL? = nil,
        avatarID: String? = nil,
        lastMessage: MeguriMessage,
        unreadCount: Int = 0
    ) {
        self.peerID = peerID
        self.displayName = displayName
        self.handle = handle
        self.avatarURL = avatarURL
        self.avatarID = avatarID
        self.lastMessage = lastMessage
        self.unreadCount = unreadCount
    }
}

public enum MeguriMessageReadStateReducer {
    public static func conversationThreads(
        from messages: [MeguriMessage],
        viewerID: UUID,
        publicProfilesByUserID: [UUID: PublicUserProfile] = [:],
        meguriProfilesByUserID: [UUID: MeguriProfile] = [:]
    ) -> [MeguriMessageThread] {
        let grouped = Dictionary(grouping: messages) { message in
            message.senderID == viewerID ? message.recipientID : message.senderID
        }

        return grouped.compactMap { peerID, messages in
            guard let lastMessage = messages.max(by: { $0.createdAt < $1.createdAt }) else {
                return nil
            }
            let unreadCount = messages.filter { message in
                isUnreadIncoming(message, peerID: peerID, viewerID: viewerID)
            }.count
            return MeguriMessageThread(
                peerID: peerID,
                displayName: displayName(
                    for: peerID,
                    in: messages,
                    publicProfilesByUserID: publicProfilesByUserID,
                    meguriProfilesByUserID: meguriProfilesByUserID
                ),
                handle: handle(
                    for: peerID,
                    in: messages,
                    publicProfilesByUserID: publicProfilesByUserID
                ),
                avatarURL: publicProfilesByUserID[peerID]?.profile.avatarURL,
                avatarID: meguriProfilesByUserID[peerID]?.avatarID,
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

    public static func unreadIncomingCount(_ messages: [MeguriMessage], viewerID: UUID) -> Int {
        messages.filter { message in
            message.recipientID == viewerID
                && message.senderID != viewerID
                && message.readAt == nil
        }.count
    }

    public static func pendingReplyThreadCount(_ messages: [MeguriMessage], viewerID: UUID) -> Int {
        let grouped = Dictionary(grouping: messages) { message in
            message.senderID == viewerID ? message.recipientID : message.senderID
        }

        return grouped.values.reduce(0) { count, messages in
            guard let lastMessage = messages.max(by: { $0.createdAt < $1.createdAt }) else {
                return count
            }
            let needsReply = lastMessage.recipientID == viewerID && lastMessage.senderID != viewerID
            return needsReply ? count + 1 : count
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
        peerID: UUID,
        viewerID: UUID
    ) -> Bool {
        messages.contains { message in
            isUnreadIncoming(message, peerID: peerID, viewerID: viewerID)
        }
    }

    public static func markIncomingMessagesRead(
        _ messages: [MeguriMessage],
        peerID: UUID,
        viewerID: UUID,
        readAt: Date
    ) -> [MeguriMessage] {
        messages.map { message in
            guard isUnreadIncoming(message, peerID: peerID, viewerID: viewerID) else {
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
        peerID: UUID,
        viewerID: UUID
    ) -> Bool {
        message.senderID == peerID
            && message.recipientID == viewerID
            && message.readAt == nil
    }

    private static func displayName(
        for peerID: UUID,
        in messages: [MeguriMessage],
        publicProfilesByUserID: [UUID: PublicUserProfile],
        meguriProfilesByUserID: [UUID: MeguriProfile]
    ) -> String {
        if let name = meguriProfilesByUserID[peerID]?.displayName.nilIfBlank {
            return name
        }
        if let name = publicProfilesByUserID[peerID]?.profile.displayName.nilIfBlank {
            return name
        }
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
        in messages: [MeguriMessage],
        publicProfilesByUserID: [UUID: PublicUserProfile]
    ) -> String? {
        if let handle = publicProfilesByUserID[peerID]?.profile.handle.nilIfBlank {
            return handle
        }
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
