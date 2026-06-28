import Foundation
import MegrumCore
import MegrumData

final class SupabasePaymentSettingsClient: @unchecked Sendable {
    private let client: SupabaseRESTClient

    init(client: SupabaseRESTClient) {
        self.client = client
    }

    func loadSettings(userID: UUID) async throws -> UserPaymentSettings? {
        let rows: [UserPaymentSettingsRow] = try await client.fetchRows(
            from: "user_payment_settings",
            select: Self.selectFields,
            queryItems: settingsQueryItems(userID: userID)
        )
        return rows.first?.settings
    }

    func upsertSettings(_ settings: UserPaymentSettings) async throws -> UserPaymentSettings {
        let normalized = settings.normalized()
        let rows: [UserPaymentSettingsRow] = try await client.upsertRows(
            into: "user_payment_settings",
            values: [UserPaymentSettingsPayload(settings: normalized)],
            select: Self.selectFields,
            onConflict: "user_id"
        )
        return rows.first?.settings ?? normalized
    }

    private static let selectFields = "user_id,payment_methods,bank_name,bank_branch_name,bank_account_type,bank_account_number,bank_account_holder,other_note,created_at,updated_at"

    private func settingsQueryItems(userID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString.lowercased())"),
            URLQueryItem(name: "limit", value: "1")
        ]
    }
}

private struct UserPaymentSettingsPayload: Encodable, Sendable {
    var userId: UUID
    var paymentMethods: [UserPaymentMethod]
    var bankName: String?
    var bankBranchName: String?
    var bankAccountType: String?
    var bankAccountNumber: String?
    var bankAccountHolder: String?
    var otherNote: String?

    init(settings: UserPaymentSettings) {
        self.userId = settings.userID
        self.paymentMethods = settings.methods
        self.bankName = settings.bankName.nilIfBlank
        self.bankBranchName = settings.bankBranchName.nilIfBlank
        self.bankAccountType = settings.bankAccountType.nilIfBlank
        self.bankAccountNumber = settings.bankAccountNumber.nilIfBlank
        self.bankAccountHolder = settings.bankAccountHolder.nilIfBlank
        self.otherNote = settings.otherNote?.nilIfBlank
    }
}

private struct UserPaymentSettingsRow: Decodable, Sendable {
    var userId: UUID
    var paymentMethods: [UserPaymentMethod]?
    var bankName: String?
    var bankBranchName: String?
    var bankAccountType: String?
    var bankAccountNumber: String?
    var bankAccountHolder: String?
    var otherNote: String?
    var createdAt: Date?
    var updatedAt: Date?

    var settings: UserPaymentSettings {
        UserPaymentSettings(
            userID: userId,
            methods: paymentMethods ?? [],
            bankName: bankName ?? "",
            bankBranchName: bankBranchName ?? "",
            bankAccountType: bankAccountType ?? "",
            bankAccountNumber: bankAccountNumber ?? "",
            bankAccountHolder: bankAccountHolder ?? "",
            otherNote: otherNote,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
