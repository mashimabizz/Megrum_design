import MegrumCore
import MegrumDesign
import SwiftUI

struct NotificationCenterContent: View {
    @Binding var filter: NotificationCenterFilter
    var isLoading: Bool
    var notifications: [MegrumNotification]
    var onSelectNotification: (MegrumNotification) -> Void

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
                if isLoading {
                    loadingRow
                } else if visibleNotifications.isEmpty {
                    emptyRow
                } else {
                    ForEach(visibleNotifications) { notification in
                        NotificationCenterRow(notification: notification) {
                            onSelectNotification(notification)
                        }
                    }
                }
            } header: {
                Text("\(visibleNotifications.count)件")
            }
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
            notifications
        case .unread:
            notifications.filter(\.isUnread)
        case .trades:
            notifications.filter { $0.kind.isTradeRelatedForCenter }
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
