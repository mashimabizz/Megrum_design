import Foundation
import MegrumCore

public enum NotificationReadStateReducer {
    public static func unreadCount(in notifications: [MegrumNotification]) -> Int {
        notifications.filter(\.isUnread).count
    }

    public static func containsUnread(_ notifications: [MegrumNotification], id: UUID) -> Bool {
        notifications.contains { $0.id == id && $0.isUnread }
    }

    public static func markRead(
        _ notifications: [MegrumNotification],
        id: UUID,
        readAt: Date
    ) -> [MegrumNotification] {
        notifications.map { notification in
            guard notification.id == id, notification.isUnread else {
                return notification
            }

            var next = notification
            next.readAt = readAt
            return next
        }
    }

    public static func markUnread(
        _ notifications: [MegrumNotification],
        id: UUID
    ) -> [MegrumNotification] {
        notifications.map { notification in
            guard notification.id == id else {
                return notification
            }

            var next = notification
            next.readAt = nil
            return next
        }
    }

    public static func markAllRead(
        _ notifications: [MegrumNotification],
        readAt: Date
    ) -> [MegrumNotification] {
        notifications.map { notification in
            var next = notification
            next.readAt = next.readAt ?? readAt
            return next
        }
    }

    public static func mergingUpdated(
        _ notifications: [MegrumNotification],
        updated: [MegrumNotification]
    ) -> [MegrumNotification] {
        guard !updated.isEmpty else {
            return notifications
        }

        let updatedByID = Dictionary(uniqueKeysWithValues: updated.map { ($0.id, $0) })
        return notifications.map { updatedByID[$0.id] ?? $0 }
    }
}
