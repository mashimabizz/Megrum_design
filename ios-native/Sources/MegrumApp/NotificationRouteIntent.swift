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
        case .meguriBoardThread, .meguriMessages:
            .meguri
        case .userProfile, .userEvaluations:
            .home
        }
    }

    private static func intent(
        from link: NotificationLinkComponents,
        kind: MegrumNotificationKind?
    ) -> NotificationRouteIntent {
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
        case "meguri", "grooms", "groom":
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
        let peerID = link.queryValue("userid", "user_id", "peerid", "peer_id").nilIfBlank
            ?? link.firstUUIDLikeSegment
        if peerID == nil,
           link.lowercaseSegments.first != "meguri-letters",
           link.lowercaseSegments.first != "meguri-messages" {
            return nil
        }
        return .meguriMessages(peerID: peerID, open: link.queryValue("open"))
    }
}

private struct NotificationLinkComponents {
    let rawPath: String
    let segments: [String]
    let lowercaseSegments: [String]
    private let queryItems: [String: String]

    init?(_ linkPath: String?) {
        let rawPath = linkPath?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !rawPath.isEmpty else {
            return nil
        }

        self.rawPath = rawPath
        let components = URLComponents(string: rawPath)
        let path = Self.normalizedPath(from: rawPath, components: components)
        segments = path
            .split(separator: "/")
            .map { String($0).removingPercentEncoding ?? String($0) }
            .filter { !$0.isEmpty }
        lowercaseSegments = segments.map { $0.lowercased() }

        var queryItems: [String: String] = [:]
        for item in components?.queryItems ?? [] {
            queryItems[item.name.lowercased()] = item.value ?? ""
        }
        self.queryItems = queryItems
    }

    func queryValue(_ keys: String...) -> String? {
        for key in keys {
            if let value = queryItems[key.lowercased()] {
                return value
            }
        }
        return nil
    }

    func segment(at index: Int) -> String? {
        guard segments.indices.contains(index) else {
            return nil
        }
        return segments[index].nilIfBlank
    }

    func segment(after lowercaseHead: String) -> String? {
        guard let index = lowercaseSegments.firstIndex(of: lowercaseHead) else {
            return nil
        }
        return segment(at: index + 1)
    }

    var firstUUIDLikeSegment: String? {
        segments.first { UUID(uuidString: $0) != nil }
    }

    var assistanceKind: NotificationTradeAssistanceKind {
        queryValue("kind")?.lowercased() == NotificationTradeAssistanceKind.late.rawValue ? .late : .cancel
    }

    var fallbackTab: MegrumTab {
        let lowercasedPath = rawPath.lowercased()
        if lowercasedPath.contains("meguri")
            || lowercasedPath.contains("groom")
            || lowercasedPath.contains("board") {
            return .meguri
        }
        if lowercasedPath.contains("proposal")
            || lowercasedPath.contains("trade")
            || lowercasedPath.contains("transaction")
            || lowercasedPath.contains("deal")
            || lowercasedPath.contains("dispute") {
            return .trades
        }
        if lowercasedPath.contains("inventory") || lowercasedPath.contains("goods") {
            return .inventory
        }
        if lowercasedPath.contains("wish") {
            return .wish
        }
        return .home
    }

    private static func normalizedPath(
        from rawPath: String,
        components: URLComponents?
    ) -> String {
        guard let components else {
            return rawPath.components(separatedBy: "?").first ?? rawPath
        }

        var pathParts: [String] = []
        if components.scheme != nil, let host = components.host, !host.isEmpty {
            pathParts.append(host)
        }
        pathParts.append(contentsOf: components.path.split(separator: "/").map(String.init))

        let path = pathParts.joined(separator: "/")
        if path.isEmpty {
            return rawPath.components(separatedBy: "?").first ?? rawPath
        }
        return "/" + path
    }
}
