import Foundation
import MegrumCore

/// 通知の時系列セクション（今日/今週/それ以前）。Instagram型のグルーピング。iter1226.408。
struct NotificationCenterSection: Identifiable, Equatable {
    var title: String
    var notifications: [MegrumNotification]

    var id: String { title }
}

struct NotificationCenterPresentationState: Equatable {
    var filter: NotificationCenterFilter = .all

    var emptyTitle: String {
        switch filter {
        case .all:
            "まだ通知はありません"
        case .trades:
            "取引の通知はありません"
        case .meguri:
            "めぐりの通知はありません"
        }
    }

    func visibleNotifications(in notifications: [MegrumNotification]) -> [MegrumNotification] {
        switch filter {
        case .all:
            notifications
        case .trades:
            notifications.filter { $0.kind.isTradeRelatedForCenter }
        case .meguri:
            notifications.filter { $0.kind.isMeguriRelatedForCenter }
        }
    }

    /// フィルタ適用後の通知を「今日/今週/それ以前」に分ける（元の並び順は保持）。
    func sections(
        in notifications: [MegrumNotification],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [NotificationCenterSection] {
        let visible = visibleNotifications(in: notifications)
        guard !visible.isEmpty else {
            return []
        }

        let weekBoundary = now.addingTimeInterval(-7 * 24 * 60 * 60)
        var today: [MegrumNotification] = []
        var thisWeek: [MegrumNotification] = []
        var earlier: [MegrumNotification] = []

        for notification in visible {
            if calendar.isDate(notification.createdAt, inSameDayAs: now) {
                today.append(notification)
            } else if notification.createdAt > weekBoundary {
                thisWeek.append(notification)
            } else {
                earlier.append(notification)
            }
        }

        return [
            NotificationCenterSection(title: "今日", notifications: today),
            NotificationCenterSection(title: "今週", notifications: thisWeek),
            NotificationCenterSection(title: "それ以前", notifications: earlier),
        ]
        .filter { !$0.notifications.isEmpty }
    }
}
