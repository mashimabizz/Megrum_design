import Foundation
import MegrumCore
import MegrumData

public extension PreviewMegrumRepository {
    func loadMailingAddress() async throws -> MailingAddress? {
        NativePreviewData.mailingAddress
    }

    func saveMailingAddress(_ address: MailingAddress) async throws -> MailingAddress {
        address
    }

    func lookupAddress(postalCode: String) async throws -> PostalCodeAddress? {
        guard PostalCodeAddressClient.normalizedPostalCode(postalCode) == "1000001" else {
            return nil
        }
        return PostalCodeAddress(
            postalCode: "1000001",
            prefecture: "東京都",
            city: "千代田区",
            town: "千代田"
        )
    }

    func loadBlockedUsers() async throws -> [BlockedUser] {
        NativePreviewData.blockedUsers
    }

    func unblockUser(_ userID: UUID) async throws {}

    func loadNotifications(limit: Int) async throws -> [MegrumNotification] {
        Array(NativePreviewData.notifications.prefix(limit))
    }

    func markNotificationRead(_ notificationID: UUID) async throws -> MegrumNotification? {
        guard var notification = NativePreviewData.notifications.first(where: { $0.id == notificationID }) else {
            return nil
        }
        notification.readAt = notification.readAt ?? .now
        return notification
    }

    func markAllNotificationsRead() async throws -> [MegrumNotification] {
        NativePreviewData.notifications.map { notification in
            var next = notification
            next.readAt = next.readAt ?? .now
            return next
        }
    }

    func loadPushNotificationsEnabled() async throws -> Bool {
        true
    }

    func setPushNotificationsEnabled(_ enabled: Bool) async throws -> Bool {
        enabled
    }

    func registerNativePushDeviceToken(_ token: String, appVersion: String?) async throws {}

    func revokeNativePushDeviceToken(_ token: String, revokedAt: Date) async throws {}
}
