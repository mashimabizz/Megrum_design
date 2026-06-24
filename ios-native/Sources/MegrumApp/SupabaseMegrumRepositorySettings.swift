import Foundation
import MegrumCore
import MegrumData

public extension SupabaseMegrumRepository {
    func loadSchedules(for proposal: TradeProposal, startAt: Date, endAt: Date) async throws -> [PersonalSchedule] {
        try await tradeSchedulePersistence.loadSchedules(for: proposal, startAt: startAt, endAt: endAt)
    }

    func loadPersonalSchedules(startAt: Date, endAt: Date) async throws -> [PersonalSchedule] {
        try await tradeSchedulePersistence.loadPersonalSchedules(startAt: startAt, endAt: endAt)
    }

    func loadProfileSchedules(userID: UUID, startAt: Date, endAt: Date) async throws -> [PersonalSchedule] {
        try await tradeSchedulePersistence.loadProfileSchedules(userID: userID, startAt: startAt, endAt: endAt)
    }

    func createSchedule(_ input: PersonalScheduleCreateInput) async throws -> PersonalSchedule {
        try await tradeSchedulePersistence.createSchedule(input)
    }

    func loadHomeLocalModeSettings(now: Date) async throws -> HomeLocalActivitySettings? {
        try await homeLocalModePersistence.loadSettings(now: now)
    }

    func saveHomeLocalModeSettings(
        _ settings: HomeLocalActivitySettings,
        now: Date
    ) async throws -> HomeLocalActivitySettings {
        try await homeLocalModePersistence.saveSettings(settings, now: now)
    }

    func loadMailingAddress() async throws -> MailingAddress? {
        try await mailingAddressClient.loadAddress(userID: viewerID)
    }

    func saveMailingAddress(_ address: MailingAddress) async throws -> MailingAddress {
        try await mailingAddressClient.upsertAddress(address)
    }

    func loadPaymentSettings() async throws -> UserPaymentSettings? {
        try await paymentSettingsPersistence.loadSettings(userID: viewerID)
    }

    func savePaymentSettings(_ settings: UserPaymentSettings) async throws -> (profile: UserProfile, settings: UserPaymentSettings) {
        try await paymentSettingsPersistence.saveSettings(settings, userID: viewerID)
    }

    func lookupAddress(postalCode: String) async throws -> PostalCodeAddress? {
        try await postalCodeAddressClient.lookup(postalCode: postalCode)
    }

    func loadBlockedUsers() async throws -> [BlockedUser] {
        try await blockClient.loadBlockedUsers(blockerID: viewerID)
    }

    func unblockUser(_ userID: UUID) async throws {
        try await blockClient.unblockUser(blockerID: viewerID, blockedID: userID)
    }

    func loadNotifications(limit: Int) async throws -> [MegrumNotification] {
        try await notificationClient.loadNotifications(userID: viewerID, limit: limit)
    }

    func markNotificationRead(_ notificationID: UUID) async throws -> MegrumNotification? {
        try await notificationClient.markNotificationRead(userID: viewerID, notificationID: notificationID)
    }

    func markAllNotificationsRead() async throws -> [MegrumNotification] {
        try await notificationClient.markAllNotificationsRead(userID: viewerID)
    }

    func loadPushNotificationsEnabled() async throws -> Bool {
        try await notificationClient.loadPushNotificationsEnabled(userID: viewerID)
    }

    func setPushNotificationsEnabled(_ enabled: Bool) async throws -> Bool {
        try await notificationClient.setPushNotificationsEnabled(userID: viewerID, enabled: enabled)
    }

    func registerNativePushDeviceToken(_ token: String, appVersion: String?) async throws {
        _ = try await notificationClient.registerNativePushDevice(
            userID: viewerID,
            deviceToken: token,
            appVersion: appVersion
        )
    }

    func revokeNativePushDeviceToken(_ token: String, revokedAt: Date) async throws {
        _ = try await notificationClient.revokeNativePushDevice(
            userID: viewerID,
            deviceToken: token,
            revokedAt: revokedAt
        )
    }

    func updateOwnProfile(_ input: OwnProfileUpdateInput) async throws -> UserProfile {
        try await accountProfilePersistence.updateOwnProfile(input)
    }

    func completeAccountSetup(_ input: AccountSetupInput) async throws -> UserProfile {
        try await accountProfilePersistence.completeAccountSetup(input)
    }
}
