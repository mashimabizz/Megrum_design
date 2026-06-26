import Foundation
import MegrumCore
import MegrumData

final class SupabasePaymentSettingsPersistence: @unchecked Sendable {
    private let client: SupabaseRESTClient
    private let settingsClient: SupabasePaymentSettingsClient

    init(client: SupabaseRESTClient, settingsClient: SupabasePaymentSettingsClient? = nil) {
        self.client = client
        self.settingsClient = settingsClient ?? SupabasePaymentSettingsClient(client: client)
    }

    func loadSettings(userID: UUID) async throws -> UserPaymentSettings? {
        try await settingsClient.loadSettings(userID: userID)
    }

    func saveSettings(
        _ settings: UserPaymentSettings,
        userID: UUID
    ) async throws -> (profile: UserProfile, settings: UserPaymentSettings) {
        let normalized = settings.normalized(for: userID)
        let rows: [UserRow] = try await client.updateRows(
            in: "users",
            values: UserPaymentSummaryUpdatePayload(
                paymentMethods: normalized.methods,
                paymentNote: normalized.otherNote
            ),
            select: UserRow.paymentSummarySelect,
            queryItems: Self.userQueryItems(userID: userID)
        )
        let storedSettings = try? await settingsClient.upsertSettings(normalized)
        return (
            rows.first?.profile ?? Self.fallbackProfile(userID: userID, normalizedSettings: normalized),
            Self.returnedSettings(storedSettings: storedSettings, normalizedSettings: normalized)
        )
    }

    static func returnedSettings(
        storedSettings: UserPaymentSettings?,
        normalizedSettings: UserPaymentSettings
    ) -> UserPaymentSettings {
        guard let storedSettings else {
            return normalizedSettings
        }

        return UserPaymentSettings(
            userID: storedSettings.userID,
            methods: normalizedSettings.methods,
            bankName: storedSettings.bankName,
            bankBranchName: storedSettings.bankBranchName,
            bankAccountType: storedSettings.bankAccountType,
            bankAccountNumber: storedSettings.bankAccountNumber,
            bankAccountHolder: storedSettings.bankAccountHolder,
            otherNote: storedSettings.otherNote,
            createdAt: storedSettings.createdAt,
            updatedAt: storedSettings.updatedAt
        )
    }

    static func fallbackProfile(
        userID: UUID,
        normalizedSettings: UserPaymentSettings
    ) -> UserProfile {
        UserProfile(
            id: userID,
            handle: "unknown",
            displayName: "Megrum",
            paymentMethods: normalizedSettings.methods,
            paymentNote: normalizedSettings.otherNote,
            accountStatus: .active
        )
    }

    private static func userQueryItems(userID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "id", value: "eq.\(userID.uuidString.lowercased())"),
            URLQueryItem(name: "limit", value: "1")
        ]
    }
}
