import Foundation
import MegrumCore

enum GroomReplyMeguriMessageMapper {
    static func sentMessage(from reply: GroomReply, viewer: UserProfile) -> MeguriMessage {
        MeguriMessage(
            id: UUID(),
            senderID: viewer.id,
            recipientID: reply.recipientID,
            sourceGroomReplyID: reply.id,
            body: reply.body,
            createdAt: reply.createdAt,
            senderDisplayName: viewer.displayName,
            senderHandle: viewer.handle
        )
    }
}
