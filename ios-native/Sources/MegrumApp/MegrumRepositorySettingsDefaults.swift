import Foundation
import MegrumCore

public extension MegrumRepository {
    func loadMailingAddress() async throws -> MailingAddress? {
        nil
    }

    func saveMailingAddress(_ address: MailingAddress) async throws -> MailingAddress {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func loadPaymentSettings() async throws -> UserPaymentSettings? {
        nil
    }

    func savePaymentSettings(_ settings: UserPaymentSettings) async throws -> (profile: UserProfile, settings: UserPaymentSettings) {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func lookupAddress(postalCode: String) async throws -> PostalCodeAddress? {
        nil
    }

    func loadBlockedUsers() async throws -> [BlockedUser] {
        []
    }

    func unblockUser(_ userID: UUID) async throws {}

    func loadNotifications(limit: Int) async throws -> [MegrumNotification] {
        []
    }

    func markNotificationRead(_ notificationID: UUID) async throws -> MegrumNotification? {
        nil
    }

    func markAllNotificationsRead() async throws -> [MegrumNotification] {
        []
    }

    func loadPushNotificationsEnabled() async throws -> Bool {
        true
    }

    func setPushNotificationsEnabled(_ enabled: Bool) async throws -> Bool {
        enabled
    }

    func registerNativePushDeviceToken(_ token: String, appVersion: String?) async throws {}

    func revokeNativePushDeviceToken(_ token: String, revokedAt: Date) async throws {}

    func updateOwnProfile(_ input: OwnProfileUpdateInput) async throws -> UserProfile {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func completeAccountSetup(_ input: AccountSetupInput) async throws -> UserProfile {
        throw MegrumRepositoryError.unsupportedMutation
    }
}
