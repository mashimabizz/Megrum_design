import MegrumCore
import MegrumDesign
import SwiftUI

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
