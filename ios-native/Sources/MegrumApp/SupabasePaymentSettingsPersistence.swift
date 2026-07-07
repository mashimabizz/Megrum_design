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
        let storedSettings = try await settingsClient.upsertSettings(normalized)
        let rows: [UserRow] = try await client.updateRows(
            in: "users",
            values: UserPaymentSummaryUpdatePayload(
                paymentMethods: normalized.methods,
                paymentNote: normalized.otherNote,
                paymentBankNames: normalized.methods.contains(.bankTransfer) ? normalized.bankAccountDisplayNames : []
            ),
            // birth_date / bio を含むフル項目で返す。縮小selectのプロフィールを
            // そのまま viewer に代入すると、生年月日などがセッション内で消える。
            select: UserRow.select,
            queryItems: Self.userQueryItems(userID: userID)
        )
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
            bankAccounts: storedSettings.bankAccounts,
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
            paymentBankNames: normalizedSettings.methods.contains(.bankTransfer) ? normalizedSettings.bankAccountDisplayNames : [],
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
