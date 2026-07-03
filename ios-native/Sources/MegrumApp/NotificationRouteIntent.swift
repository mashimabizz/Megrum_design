import Foundation
import MegrumCore

enum NotificationTradeAssistanceKind: String, Equatable, Sendable {
    case late
    case cancel
}

enum NotificationRouteIntent: Equatable, Sendable {
    case tab(MegrumTab)
    case tradeDetail(id: String)
    case tradeEvidenceCapture(id: String)
    case tradeEvidenceApproval(id: String)
    case tradeEvaluation(id: String)
    case tradeAssistance(id: String, kind: NotificationTradeAssistanceKind)
    case disputeDetail(id: String)
    case meguriBoardThread(id: String, viewMode: String?)
    case meguriMessages(peerID: String?, open: String?)
    case ownGroom(postID: String?)
    case userProfile(id: String)
    case userEvaluations(userID: String)
    case unknown(rawPath: String, fallbackTab: MegrumTab)

    init?(notification: MegrumNotification) {
        self.init(linkPath: notification.linkPath, kind: notification.kind)
    }

    init?(linkPath: String?, kind: MegrumNotificationKind? = nil) {
        guard let link = NotificationLinkComponents(linkPath) else {
            return nil
        }
        self = Self.intent(from: link, kind: kind)
    }

    var fallbackTab: MegrumTab {
        switch self {
        case .tab(let tab), .unknown(_, let tab):
            tab
        case .tradeDetail, .tradeEvidenceCapture, .tradeEvidenceApproval,
             .tradeEvaluation, .tradeAssistance, .disputeDetail:
            .trades
        case .meguriBoardThread, .meguriMessages, .ownGroom:
            .meguri
        case .userProfile, .userEvaluations:
            .home
        }
    }

    private static func intent(
        from link: NotificationLinkComponents,
        kind: MegrumNotificationKind?
    ) -> NotificationRouteIntent {
        if kind == .groomLiked {
            return ownGroomIntent(from: link)
        }

        if (kind == .groomReply || kind == .meguriMessage),
           let intent = meguriMessageIntent(from: link) {
            return intent
        }

        guard let head = link.lowercaseSegments.first else {
            return .tab(.home)
        }

        switch head {
        case "meguri-board-thread":
            guard let id = link.queryValue("id").nilIfBlank ?? link.segment(after: head) else {
                return .tab(.meguri)
            }
            return .meguriBoardThread(id: id, viewMode: link.queryValue("viewmode", "view_mode"))
        case "meguri-letters", "meguri-messages":
            return meguriMessageIntent(from: link) ?? .meguriMessages(peerID: nil, open: link.queryValue("open"))
        case "disputes":
            guard let id = link.segment(after: head) else {
                return .tab(.trades)
            }
            return .disputeDetail(id: id)
        case "dispute-detail":
            guard let id = link.queryValue("id").nilIfBlank ?? link.segment(after: head) else {
                return .tab(.trades)
            }
            return .disputeDetail(id: id)
        case "proposals":
            guard let id = link.segment(after: head) else {
                return .tab(.trades)
            }
            return .tradeDetail(id: id)
        case "transactions", "trades", "deals":
            guard let id = link.segment(after: head) else {
                return .tab(.trades)
            }
            return transactionIntent(id: id, action: link.segment(at: 2), link: link)
        case "transaction-detail":
            guard let id = link.queryValue("id").nilIfBlank ?? link.segment(after: head) else {
                return .tab(.trades)
            }
            return .tradeDetail(id: id)
        case "transaction-capture":
            guard let id = link.queryValue("id").nilIfBlank ?? link.segment(after: head) else {
                return .tab(.trades)
            }
            return .tradeEvidenceCapture(id: id)
        case "transaction-approve":
            guard let id = link.queryValue("id").nilIfBlank ?? link.segment(after: head) else {
                return .tab(.trades)
            }
            return .tradeEvidenceApproval(id: id)
        case "transaction-rate":
            guard let id = link.queryValue("id").nilIfBlank ?? link.segment(after: head) else {
                return .tab(.trades)
            }
            return .tradeEvaluation(id: id)
        case "transaction-cancel-or-late":
            guard let id = link.queryValue("id").nilIfBlank ?? link.segment(after: head) else {
                return .tab(.trades)
            }
            return .tradeAssistance(id: id, kind: link.assistanceKind)
        case "users":
            guard let id = link.segment(after: head) else {
                return .tab(.home)
            }
            if link.lowercaseSegments.dropFirst(2).contains("evaluations") {
                return .userEvaluations(userID: id)
            }
            return .userProfile(id: id)
        case "user-profile":
            guard let id = link.queryValue("id", "user_id", "userid").nilIfBlank ?? link.segment(after: head) else {
                return .tab(.home)
            }
            return .userProfile(id: id)
        case "user-evaluations", "evaluations":
            guard let id = link.queryValue("id", "user_id", "userid").nilIfBlank ?? link.segment(after: head) else {
                return .tab(.home)
            }
            return .userEvaluations(userID: id)
        case "home", "profile", "search":
            return .tab(.home)
        case "inventory", "goods":
            return .tab(.inventory)
        case "wish", "wishes":
            return .tab(.wish)
        case "grooms", "groom":
            if let intent = meguriMessageIntent(from: link) {
                return intent
            }
            return ownGroomIntent(from: link)
        case "meguri":
            return .tab(.meguri)
        default:
            return .unknown(rawPath: link.rawPath, fallbackTab: link.fallbackTab)
        }
    }

    private static func transactionIntent(
        id: String,
        action: String?,
        link: NotificationLinkComponents
    ) -> NotificationRouteIntent {
        switch action?.lowercased() {
        case "capture":
            .tradeEvidenceCapture(id: id)
        case "approve":
            .tradeEvidenceApproval(id: id)
        case "rate":
            .tradeEvaluation(id: id)
        case "cancel-or-late":
            .tradeAssistance(id: id, kind: link.assistanceKind)
        default:
            .tradeDetail(id: id)
        }
    }

    private static func meguriMessageIntent(from link: NotificationLinkComponents) -> NotificationRouteIntent? {
        let messagePathUsesPeerSegment = link.lowercaseSegments.first == "meguri-letters"
            || link.lowercaseSegments.first == "meguri-messages"
        let peerID = link.queryValue("userid", "user_id", "peerid", "peer_id").nilIfBlank
            ?? (messagePathUsesPeerSegment ? link.firstUUIDLikeSegment : nil)
        if peerID == nil,
           link.lowercaseSegments.first != "meguri-letters",
           link.lowercaseSegments.first != "meguri-messages" {
            return nil
        }
        return .meguriMessages(peerID: peerID, open: link.queryValue("open"))
    }

    private static func ownGroomIntent(from link: NotificationLinkComponents) -> NotificationRouteIntent {
        let postID = link.queryValue("groompostid", "groom_post_id", "postid", "post_id", "id").nilIfBlank
            ?? link.firstUUIDLikeSegment
        return .ownGroom(postID: postID)
    }
}
