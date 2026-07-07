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

    private static let selectFields = "user_id,payment_methods,bank_accounts,bank_name,bank_branch_name,bank_account_type,bank_account_number,bank_account_holder,other_note,created_at,updated_at"

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
    var bankAccounts: [BankReceivingAccount]
    // 先頭口座はレガシー単一カラムにも書いておく（既存レポート・移行前後の互換のため）。
    var bankName: String?
    var bankBranchName: String?
    var bankAccountType: String?
    var bankAccountNumber: String?
    var bankAccountHolder: String?
    var otherNote: String?

    init(settings: UserPaymentSettings) {
        self.userId = settings.userID
        self.paymentMethods = settings.methods
        self.bankAccounts = settings.bankAccounts
        let primary = settings.bankAccounts.first
        self.bankName = primary?.bankName.nilIfBlank
        self.bankBranchName = primary?.branchName.nilIfBlank
        self.bankAccountType = primary?.accountType.nilIfBlank
        self.bankAccountNumber = primary?.accountNumber.nilIfBlank
        self.bankAccountHolder = primary?.holder.nilIfBlank
        self.otherNote = settings.otherNote?.nilIfBlank
    }
}

private struct UserPaymentSettingsRow: Decodable, Sendable {
    var userId: UUID
    var paymentMethods: [UserPaymentMethod]?
    var bankAccounts: [BankReceivingAccount]?
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
            bankAccounts: resolvedAccounts,
            otherNote: otherNote,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    /// bank_accounts(JSONB) を優先。未設定の旧行はレガシー単一カラムから1件復元する。
    private var resolvedAccounts: [BankReceivingAccount] {
        if let bankAccounts, !bankAccounts.isEmpty {
            return bankAccounts
        }
        let legacy = BankReceivingAccount(
            bankName: bankName ?? "",
            branchName: bankBranchName ?? "",
            accountType: bankAccountType ?? "",
            accountNumber: bankAccountNumber ?? "",
            holder: bankAccountHolder ?? ""
        )
        return legacy.isBlank ? [] : [legacy]
    }
}
