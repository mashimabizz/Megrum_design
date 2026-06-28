import Foundation

public enum MegrumNotificationKind: String, Codable, Sendable, CaseIterable, Identifiable {
    case proposalReceived = "proposal_received"
    case proposalAccepted = "proposal_accepted"
    case proposalRejected = "proposal_rejected"
    case proposalRevised = "proposal_revised"
    case messageReceived = "message_received"
    case evidenceAdded = "evidence_added"
    case tradeCompleted = "trade_completed"
    case evaluationReceived = "evaluation_received"
    case disputeReceived = "dispute_received"
    case disputeResponded = "dispute_responded"
    case disputeClosed = "dispute_closed"
    case cancelRequested = "cancel_requested"
    case expiresSoon = "expires_soon"
    case groomLiked = "groom_liked"
    case groomReply = "groom_reply"
    case meguriMessage = "meguri_message"
    case meguriBoardReply = "meguri_board_reply"
    case meguriBoardMention = "meguri_board_mention"
    case adminAnnouncement = "admin_announcement"
    case unknown

    public var id: String { rawValue }
}

public struct UserNotificationSettings: Codable, Equatable, Sendable {
    public var pushEnabled: Bool
    public var groomActivityPushEnabled: Bool
    public var chatroomActivityPushEnabled: Bool

    public init(
        pushEnabled: Bool = true,
        groomActivityPushEnabled: Bool = true,
        chatroomActivityPushEnabled: Bool = true
    ) {
        self.pushEnabled = pushEnabled
        self.groomActivityPushEnabled = groomActivityPushEnabled
        self.chatroomActivityPushEnabled = chatroomActivityPushEnabled
    }
}

public struct MegrumNotification: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var kind: MegrumNotificationKind
    public var title: String
    public var body: String?
    public var linkPath: String?
    public var readAt: Date?
    public var createdAt: Date

    public init(
        id: UUID,
        kind: MegrumNotificationKind,
        title: String,
        body: String? = nil,
        linkPath: String? = nil,
        readAt: Date? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.body = body
        self.linkPath = linkPath
        self.readAt = readAt
        self.createdAt = createdAt
    }

    public var isUnread: Bool {
        readAt == nil
    }
}
