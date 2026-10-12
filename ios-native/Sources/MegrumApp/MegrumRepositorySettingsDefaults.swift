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

    func loadBlockedUserIDs() async throws -> Set<UUID> {
        []
    }

    func blockUser(_ userID: UUID) async throws -> BlockedUser {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func unblockUser(_ userID: UUID) async throws {}

    func loadNotifications(limit: Int) async throws -> [MegrumNotification] {
        []
    }

    func resolveNotificationThumbnailURL(bucket: String, path: String) async -> URL? {
        nil
    }

    func markNotificationRead(_ notificationID: UUID) async throws -> MegrumNotification? {
        nil
    }

    func markAllNotificationsRead() async throws -> [MegrumNotification] {
        []
    }

    func loadNotificationSettings() async throws -> UserNotificationSettings {
        UserNotificationSettings()
    }

    func loadPushNotificationsEnabled() async throws -> Bool {
        true
    }

    func setPushNotificationsEnabled(_ enabled: Bool) async throws -> Bool {
        enabled
    }

    func setGroomActivityPushNotificationsEnabled(_ enabled: Bool) async throws -> UserNotificationSettings {
        UserNotificationSettings(groomActivityPushEnabled: enabled)
    }

    func setChatroomActivityPushNotificationsEnabled(_ enabled: Bool) async throws -> UserNotificationSettings {
        UserNotificationSettings(chatroomActivityPushEnabled: enabled)
    }

    func setMeguriSubscriptionPushSettings(_ input: MeguriSubscriptionPushSettingsInput) async throws -> UserNotificationSettings {
        UserNotificationSettings(
            groomOshiPushEnabled: input.groomOshiPushEnabled,
            groomNearbyPushEnabled: input.groomNearbyPushEnabled,
            chatroomOshiPushEnabled: input.chatroomOshiPushEnabled,
            chatroomNearbyPushEnabled: input.chatroomNearbyPushEnabled
        )
    }

    func loadGroomNotifyPrefs() async throws -> [GroomNotifyPref] {
        []
    }

    func setGroomNotifyPref(
        groupID: UUID,
        enabled: Bool,
        notifyAllMembers: Bool,
        memberCharacterIDs: [UUID]
    ) async throws -> GroomNotifyPref {
        GroomNotifyPref(
            groupID: groupID,
            enabled: enabled,
            notifyAllMembers: notifyAllMembers,
            memberCharacterIDs: memberCharacterIDs
        )
    }

    func recordGroomEncounters(groomPostIDs _: [UUID]) async throws {}

    func loadGroomPost(id _: UUID) async throws -> GroomPost? {
        nil
    }

    func loadEncounteredGrooms(latitude _: Double?, longitude _: Double?) async throws -> [GroomPost] {
        []
    }

    func updatePushNotificationLocation(latitude: Double, longitude: Double) async throws {}

    func registerNativePushDeviceToken(_ token: String, appVersion: String?) async throws {}

    func revokeNativePushDeviceToken(_ token: String, revokedAt: Date) async throws {}

    func updateOwnProfile(_ input: OwnProfileUpdateInput) async throws -> UserProfile {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func completeAccountSetup(_ input: AccountSetupInput) async throws -> UserProfile {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func takenAccountHandles(among handles: [String]) async throws -> Set<String> {
        []
    }

    func requestAccountDeletion(_ input: AccountDeletionRequestInput) async throws -> AccountDeletionRequestResult {
        throw MegrumRepositoryError.unsupportedMutation
    }
}
