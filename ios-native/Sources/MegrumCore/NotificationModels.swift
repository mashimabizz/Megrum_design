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
    case groomPosted = "groom_posted"
    case meguriMessage = "meguri_message"
    case meguriBoardReply = "meguri_board_reply"
    case meguriBoardMention = "meguri_board_mention"
    case meguriBoardPosted = "meguri_board_posted"
    case adminAnnouncement = "admin_announcement"
    case unknown

    public var id: String { rawValue }
}

public struct UserNotificationSettings: Codable, Equatable, Sendable {
    public var pushEnabled: Bool
    public var groomActivityPushEnabled: Bool
    public var chatroomActivityPushEnabled: Bool
    /// 推し（グループ/メンバー）一致のグルーム新着投稿を通知するか。
    public var groomOshiPushEnabled: Bool
    /// 圏内（約3km）のグルーム新着投稿を通知するか。
    public var groomNearbyPushEnabled: Bool
    /// 推し一致のチャットルーム新規スレッドを通知するか。
    public var chatroomOshiPushEnabled: Bool
    /// 圏内のチャットルーム新規スレッドを通知するか。
    public var chatroomNearbyPushEnabled: Bool

    public init(
        pushEnabled: Bool = true,
        groomActivityPushEnabled: Bool = true,
        chatroomActivityPushEnabled: Bool = true,
        groomOshiPushEnabled: Bool = false,
        groomNearbyPushEnabled: Bool = false,
        chatroomOshiPushEnabled: Bool = false,
        chatroomNearbyPushEnabled: Bool = false
    ) {
        self.pushEnabled = pushEnabled
        self.groomActivityPushEnabled = groomActivityPushEnabled
        self.chatroomActivityPushEnabled = chatroomActivityPushEnabled
        self.groomOshiPushEnabled = groomOshiPushEnabled
        self.groomNearbyPushEnabled = groomNearbyPushEnabled
        self.chatroomOshiPushEnabled = chatroomOshiPushEnabled
        self.chatroomNearbyPushEnabled = chatroomNearbyPushEnabled
    }
}

/// グルーム/チャットルームの新着投稿の購読通知設定（めぐり地図の通知アイコンから変更）。
public struct MeguriSubscriptionPushSettingsInput: Equatable, Sendable {
    public var groomOshiPushEnabled: Bool
    public var groomNearbyPushEnabled: Bool
    public var chatroomOshiPushEnabled: Bool
    public var chatroomNearbyPushEnabled: Bool

    public init(
        groomOshiPushEnabled: Bool,
        groomNearbyPushEnabled: Bool,
        chatroomOshiPushEnabled: Bool,
        chatroomNearbyPushEnabled: Bool
    ) {
        self.groomOshiPushEnabled = groomOshiPushEnabled
        self.groomNearbyPushEnabled = groomNearbyPushEnabled
        self.chatroomOshiPushEnabled = chatroomOshiPushEnabled
        self.chatroomNearbyPushEnabled = chatroomNearbyPushEnabled
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
    /// 通知を発生させたユーザー（いいねした人・打診した人など）。運営通知等は nil。iter1226.413。
    public var actorUserID: UUID?
    /// 挿入時点の行為者表示名スナップショット。
    public var actorDisplayName: String?
    /// 挿入時点の行為者アバターURLスナップショット。
    public var actorAvatarURL: URL?

    public init(
        id: UUID,
        kind: MegrumNotificationKind,
        title: String,
        body: String? = nil,
        linkPath: String? = nil,
        readAt: Date? = nil,
        createdAt: Date = .now,
        actorUserID: UUID? = nil,
        actorDisplayName: String? = nil,
        actorAvatarURL: URL? = nil
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.body = body
        self.linkPath = linkPath
        self.readAt = readAt
        self.createdAt = createdAt
        self.actorUserID = actorUserID
        self.actorDisplayName = actorDisplayName
        self.actorAvatarURL = actorAvatarURL
    }

    public var isUnread: Bool {
        readAt == nil
    }
}
