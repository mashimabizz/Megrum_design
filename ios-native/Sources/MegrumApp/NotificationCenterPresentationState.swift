import MegrumCore

struct NotificationCenterPresentationState: Equatable {
    var filter: NotificationCenterFilter = .all

    var emptyTitle: String {
        switch filter {
        case .all:
            "まだ通知はありません"
        case .unread:
            "未読の通知はありません"
        case .trades:
            "取引の通知はありません"
        }
    }

    func visibleNotifications(in notifications: [MegrumNotification]) -> [MegrumNotification] {
        switch filter {
        case .all:
            notifications
        case .unread:
            notifications.filter(\.isUnread)
        case .trades:
            notifications.filter { $0.kind.isTradeRelatedForCenter }
        }
    }
}
