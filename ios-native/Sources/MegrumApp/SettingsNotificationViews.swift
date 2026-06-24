import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

@MainActor
struct NotificationsScreen: View {
    @ObservedObject var appState: MegrumAppState
    var onOpenDestination: (MegrumTab) -> Void
    @State private var filter: NotificationFilter = .all
    @State private var selectedMeguriPeer: MeguriMessagePeerRoute?

    var body: some View {
        List {
            Section {
                Picker("表示", selection: $filter) {
                    ForEach(NotificationFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
            }

            Section {
                if appState.isLoadingNotifications {
                    HStack(spacing: 10) {
                        ProgressView()
                            .controlSize(.small)
                        Text("通知を読み込んでいます")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(MegrumTheme.muted)
                    }
                } else if visibleNotifications.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(emptyTitle)
                            .font(.headline.weight(.bold))
                        Text("打診、取引チャット、掲示板の更新がここにまとまります。")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(MegrumTheme.muted)
                    }
                    .padding(.vertical, 8)
                } else {
                    ForEach(visibleNotifications) { notification in
                        NotificationRow(notification: notification) {
                            Task {
                                await appState.markNotificationRead(notification.id)
                                if let peerID = notification.meguriMessagePeerID {
                                    selectedMeguriPeer = MeguriMessagePeerRoute(peerID: peerID)
                                } else if let destination = MegrumTab(notificationLinkPath: notification.linkPath) {
                                    onOpenDestination(destination)
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
        .navigationDestination(item: $selectedMeguriPeer) { route in
            MeguriMessagesScreen(appState: appState, peerID: route.peerID)
        }
    }

    private var visibleNotifications: [MegrumNotification] {
        switch filter {
        case .all:
            appState.notifications
        case .unread:
            appState.notifications.filter(\.isUnread)
        case .trades:
            appState.notifications.filter { $0.kind.isTradeRelated }
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

private enum NotificationFilter: String, CaseIterable, Identifiable {
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

private struct NotificationRow: View {
    var notification: MegrumNotification
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: notification.kind.symbolName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(notification.kind.tint)
                    .frame(width: 42, height: 42)
                    .background(notification.kind.tint.opacity(0.14), in: Circle())

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
                    Circle()
                        .fill(MegrumTheme.pink)
                        .frame(width: 9, height: 9)
                        .padding(.top, 7)
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
    var symbolName: String {
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

    var tint: Color {
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

    var isTradeRelated: Bool {
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

public extension MegrumTab {
    init?(notificationLinkPath: String?) {
        guard let linkPath = notificationLinkPath?.lowercased(), !linkPath.isEmpty else {
            return nil
        }
        if linkPath.contains("meguri") || linkPath.contains("groom") {
            self = .meguri
        } else if linkPath.contains("proposal")
            || linkPath.contains("trade")
            || linkPath.contains("deal")
            || linkPath.contains("dispute") {
            self = .trades
        } else if linkPath.contains("inventory") || linkPath.contains("goods") {
            self = .inventory
        } else if linkPath.contains("wish") {
            self = .wish
        } else {
            self = .home
        }
    }
}

private extension MegrumNotification {
    var meguriMessagePeerID: UUID? {
        guard kind == .groomReply || kind == .meguriMessage else {
            return nil
        }
        guard let linkPath, !linkPath.isEmpty else {
            return nil
        }

        if let components = URLComponents(string: linkPath) {
            for item in components.queryItems ?? [] {
                let key = item.name.lowercased()
                if (key == "userid" || key == "user_id" || key == "peerid" || key == "peer_id"),
                   let value = item.value,
                   let id = UUID(uuidString: value) {
                    return id
                }
            }
        }

        let separators = CharacterSet(charactersIn: "/?&=#")
        return linkPath
            .components(separatedBy: separators)
            .compactMap { UUID(uuidString: $0) }
            .first
    }
}
