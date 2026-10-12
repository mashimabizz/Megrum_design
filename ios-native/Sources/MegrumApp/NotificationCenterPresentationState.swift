import Foundation
import MegrumCore

/// 通知の時系列セクション（今日/今週/それ以前）。Instagram型のグルーピング。iter1226.408。
struct NotificationCenterSection: Identifiable, Equatable {
    var title: String
    var notifications: [MegrumNotification]

    var id: String { title }

    /// いいね（groom_liked）を対象グルーム単位で束ねた表示アイテム列。iter1226.413。
    var displayItems: [NotificationCenterDisplayItem] {
        NotificationCenterDisplayItem.items(from: notifications)
    }
}

/// 通知一覧の1行に対応する表示アイテム。groom_liked は同じ対象への連続いいねを
/// 「◯◯さん、他N人がいいねしました」に集約する（Instagram方式）。iter1226.413。
enum NotificationCenterDisplayItem: Identifiable, Equatable {
    case single(MegrumNotification)
    case groomLikeGroup(GroomLikeGroup)

    struct GroomLikeGroup: Identifiable, Equatable {
        /// 新しい順。2件以上・同じ linkPath（同じグルーム）のいいね通知。
        var notifications: [MegrumNotification]

        var id: UUID { notifications.first?.id ?? UUID() }
        var newest: MegrumNotification? { notifications.first }
        var isUnread: Bool { notifications.contains(where: \.isUnread) }

        /// 集約行の本文。「ハナさん、他3人がいいねしました」。
        var summaryText: String {
            let othersCount = notifications.count - 1
            if let name = newest?.actorDisplayName?.nilIfBlank {
                return "\(name)さん、他\(othersCount)人がいいねしました"
            }
            return "\(notifications.count)人がいいねしました"
        }

        /// 重ねて出すアバターURL（新しい順・重複行為者は除く・最大3）。
        var stackedAvatarURLs: [URL?] {
            var seen = Set<UUID>()
            var urls: [URL?] = []
            for notification in notifications {
                if let actorID = notification.actorUserID {
                    guard seen.insert(actorID).inserted else {
                        continue
                    }
                }
                urls.append(notification.actorAvatarURL)
                if urls.count >= 3 {
                    break
                }
            }
            return urls
        }
    }

    var id: UUID {
        switch self {
        case .single(let notification):
            notification.id
        case .groomLikeGroup(let group):
            group.id
        }
    }

    var isUnread: Bool {
        switch self {
        case .single(let notification):
            notification.isUnread
        case .groomLikeGroup(let group):
            group.isUnread
        }
    }

    /// 並び順を保ったまま、同じ対象（linkPath）への groom_liked を束ねる。
    /// 1件だけのいいねは通常行のまま。
    static func items(from notifications: [MegrumNotification]) -> [NotificationCenterDisplayItem] {
        var likeGroups: [String: [MegrumNotification]] = [:]
        for notification in notifications where notification.kind == .groomLiked {
            guard let key = notification.linkPath?.nilIfBlank else {
                continue
            }
            likeGroups[key, default: []].append(notification)
        }

        var consumedLikeKeys = Set<String>()
        var items: [NotificationCenterDisplayItem] = []
        for notification in notifications {
            if notification.kind == .groomLiked,
               let key = notification.linkPath?.nilIfBlank,
               let grouped = likeGroups[key],
               grouped.count >= 2 {
                if consumedLikeKeys.insert(key).inserted {
                    items.append(.groomLikeGroup(GroomLikeGroup(notifications: grouped)))
                }
                continue
            }
            items.append(.single(notification))
        }
        return items
    }
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
