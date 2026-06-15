import Foundation
import MegrumCore

public enum MeguriMessageReadStateReducer {
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
}
