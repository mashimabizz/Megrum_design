import MegrumCore
import MegrumDesign
import Foundation
import SwiftUI

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

private extension Optional where Wrapped == String {
    var nilIfBlank: String? {
        guard let value = self?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }
        return value
    }
}

private extension String {
    var nilIfBlank: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}

@MainActor
struct NotificationCenterScreen: View {
    @ObservedObject var appState: MegrumAppState
    var onOpenDestination: (MegrumTab) -> Void
    var onOpenRouteIntent: (NotificationRouteIntent) -> Bool = { _ in false }
    @State private var filter: NotificationCenterFilter = .all

    init(
        appState: MegrumAppState,
        onOpenDestination: @escaping (MegrumTab) -> Void,
        onOpenRouteIntent: @escaping (NotificationRouteIntent) -> Bool = { _ in false }
    ) {
        self.appState = appState
        self.onOpenDestination = onOpenDestination
        self.onOpenRouteIntent = onOpenRouteIntent
    }

    var body: some View {
        List {
            Section {
                Picker("表示", selection: $filter) {
                    ForEach(NotificationCenterFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
            }

            Section {
                if appState.isLoadingNotifications {
                    loadingRow
                } else if visibleNotifications.isEmpty {
                    emptyRow
                } else {
                    ForEach(visibleNotifications) { notification in
                        NotificationCenterRow(notification: notification) {
                            Task {
                                await appState.markNotificationRead(notification.id)
                                guard let intent = NotificationRouteIntent(notification: notification) else {
                                    return
                                }
                                if !onOpenRouteIntent(intent) {
                                    onOpenDestination(intent.fallbackTab)
                                }
                            }
                        }
                    }
                }
            } header: {
                Text("\(visibleNotifications.count)件")
            }
        }
        .navigationTitle("通知")
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if appState.unreadNotificationCount > 0 {
                    Button("すべて既読") {
                        Task {
                            await appState.markAllNotificationsRead()
                        }
                    }
                    .disabled(appState.isMarkingNotificationsRead)
                }
            }
        }
        .task {
            await appState.loadNotifications()
        }
        .refreshable {
            await appState.loadNotifications()
        }
    }

    private var loadingRow: some View {
        HStack(spacing: 10) {
            ProgressView()
                .controlSize(.small)
            Text("通知を読み込んでいます")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MegrumTheme.muted)
        }
    }

    private var emptyRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(emptyTitle)
                .font(.headline.weight(.bold))
            Text("打診、取引チャット、掲示板の更新がここにまとまります。")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MegrumTheme.muted)
        }
        .padding(.vertical, 8)
    }

    private var visibleNotifications: [MegrumNotification] {
        switch filter {
        case .all:
            appState.notifications
        case .unread:
            appState.notifications.filter(\.isUnread)
        case .trades:
            appState.notifications.filter { $0.kind.isTradeRelatedForCenter }
        }
    }

    private var emptyTitle: String {
        switch filter {
        case .all:
            "まだ通知はありません"
        case .unread:
            "未読の通知はありません"
        case .trades:
            "取引の通知はありません"
        }
    }
}

private enum NotificationCenterFilter: String, CaseIterable, Identifiable {
    case all
    case unread
    case trades

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            "すべて"
        case .unread:
            "未読"
        case .trades:
            "取引"
        }
    }
}

private struct NotificationCenterRow: View {
    var notification: MegrumNotification
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: notification.kind.centerSymbolName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(notification.kind.centerTint)
                    .frame(width: 42, height: 42)
                    .background(notification.kind.centerTint.opacity(0.14), in: Circle())

                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(notification.title)
                            .font(.headline.weight(notification.isUnread ? .black : .bold))
                            .foregroundStyle(MegrumTheme.ink)
                            .lineLimit(2)

                        Spacer(minLength: 8)

                        Text(relativeTimeText)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(MegrumTheme.muted)
                    }

                    if let body = notification.body, !body.isEmpty {
                        Text(body)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(MegrumTheme.muted)
                            .lineLimit(3)
                    }
                }

                if notification.isUnread {
                    Text("未読")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(MegrumTheme.pink, in: Capsule())
                        .padding(.top, 2)
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(notification.title)
    }

    private var relativeTimeText: String {
        let seconds = max(0, Int(Date().timeIntervalSince(notification.createdAt)))
        let minutes = seconds / 60
        if minutes < 1 {
            return "今"
        }
        if minutes < 60 {
            return "\(minutes)分前"
        }
        let hours = minutes / 60
        if hours < 24 {
            return "\(hours)時間前"
        }
        let days = hours / 24
        if days < 7 {
            return "\(days)日前"
        }
        return notification.createdAt.formatted(.dateTime.month().day())
    }
}

private extension MegrumNotificationKind {
    var centerSymbolName: String {
        switch self {
        case .proposalReceived:
            "envelope.badge"
        case .proposalAccepted, .tradeCompleted:
            "checkmark.circle"
        case .proposalRejected:
            "xmark.circle"
        case .proposalRevised:
            "pencil.circle"
        case .evidenceAdded:
            "camera"
        case .evaluationReceived:
            "star"
        case .disputeReceived, .disputeResponded, .disputeClosed, .cancelRequested:
            "exclamationmark.triangle"
        case .expiresSoon:
            "clock"
        case .groomReply, .meguriMessage:
            "message"
        case .meguriBoardReply, .meguriBoardMention:
            "text.bubble"
        case .unknown:
            "bell"
        }
    }

    var centerTint: Color {
        switch self {
        case .proposalAccepted, .tradeCompleted:
            Color.green
        case .proposalRejected, .disputeReceived, .disputeResponded, .disputeClosed, .cancelRequested:
            Color.orange
        case .evaluationReceived, .meguriBoardMention, .expiresSoon:
            MegrumTheme.pink
        default:
            MegrumTheme.lavender
        }
    }

    var isTradeRelatedForCenter: Bool {
        switch self {
        case .proposalReceived, .proposalAccepted, .proposalRejected, .proposalRevised,
             .evidenceAdded, .tradeCompleted, .evaluationReceived, .disputeReceived,
             .disputeResponded, .disputeClosed, .cancelRequested, .expiresSoon:
            true
        case .groomReply, .meguriMessage, .meguriBoardReply, .meguriBoardMention, .unknown:
            false
        }
    }
}
