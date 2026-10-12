import Foundation

public enum UserPaymentMethod: String, Codable, Sendable, CaseIterable, Identifiable {
    case bankTransfer = "bank_transfer"
    case paypay
    case cashExchange = "cash_exchange"
    case other

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .bankTransfer:
            "銀行振込"
        case .paypay:
            "PayPay"
        case .cashExchange:
            "現金交換"
        case .other:
            "その他"
        }
    }

    public var isHomeConditionTarget: Bool {
        switch self {
        case .bankTransfer, .paypay, .cashExchange:
            true
        case .other:
            false
        }
    }

    public static func normalized(_ methods: [UserPaymentMethod]) -> [UserPaymentMethod] {
        UserPaymentMethod.allCases.filter { method in
            methods.contains(method)
        }
    }

    public static func displayText(
        for methods: [UserPaymentMethod],
        otherNote: String?,
        emptyText: String = "未設定"
    ) -> String {
        let normalizedMethods = normalized(methods)
        guard !normalizedMethods.isEmpty else {
            return emptyText
        }

        let trimmedOtherNote = otherNote?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let titles = normalizedMethods.map { method in
            if method == .other, !trimmedOtherNote.isEmpty {
                return trimmedOtherNote
            }
            return method.displayName
        }
        return titles.joined(separator: " / ")
    }
}

public struct BankReceivingAccount: Identifiable, Codable, Hashable, Sendable {
    /// 受け取り口座の最大登録数。
    public static let maxCount = 3

    public var id: UUID
    /// 銀行マスタの正規id。自由入力（その他）は nil。
    /// - Note: プロパティ名は `bankId`。Supabase の snake_case ラウンドトリップ
    ///   （convertToSnakeCase / convertFromSnakeCase）が `bank_id` ⇔ `bankId` で一致するため。
    public var bankId: String?
    public var bankName: String
    public var branchName: String
    public var accountType: String
    public var accountNumber: String
    public var holder: String

    public init(
        id: UUID = UUID(),
        bankId: String? = nil,
        bankName: String = "",
        branchName: String = "",
        accountType: String = "",
        accountNumber: String = "",
        holder: String = ""
    ) {
        self.id = id
        self.bankId = bankId
        self.bankName = bankName
        self.branchName = branchName
        self.accountType = accountType
        self.accountNumber = accountNumber
        self.holder = holder
    }

    enum CodingKeys: String, CodingKey {
        case id
        case bankId
        case bankName
        case branchName
        case accountType
        case accountNumber
        case holder
    }

    /// JSONB のキー欠落・null に寛容なデコード（バックフィルや将来のシェイプ変化で壊れないため）。
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.bankId = try container.decodeIfPresent(String.self, forKey: .bankId)
        self.bankName = try container.decodeIfPresent(String.self, forKey: .bankName) ?? ""
        self.branchName = try container.decodeIfPresent(String.self, forKey: .branchName) ?? ""
        self.accountType = try container.decodeIfPresent(String.self, forKey: .accountType) ?? ""
        self.accountNumber = try container.decodeIfPresent(String.self, forKey: .accountNumber) ?? ""
        self.holder = try container.decodeIfPresent(String.self, forKey: .holder) ?? ""
    }

    public var isBlank: Bool {
        fields.allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    public var isComplete: Bool {
        fields.allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    /// 相手可視・マッチング用の正規銀行名。
    public var canonicalBankName: String {
        if let entry = BankMaster.entry(id: bankId) {
            return entry.name
        }
        return BankMaster.canonicalDisplayName(bankName)
    }

    /// 同じ銀行かを判定するための安定キー。
    public var matchKey: String? {
        BankMaster.matchKey(displayName: bankName, bankID: bankId)
    }

    public func normalized() -> BankReceivingAccount {
        BankReceivingAccount(
            id: id,
            bankId: bankId?.nilIfBlank,
            bankName: Self.trimmed(bankName),
            branchName: Self.trimmed(branchName),
            accountType: Self.trimmed(accountType),
            accountNumber: String(accountNumber.filter(\.isNumber).prefix(32)),
            holder: Self.trimmed(holder)
        )
    }

    private var fields: [String] {
        [bankName, branchName, accountType, accountNumber, holder]
    }

    private static func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

public struct UserPaymentSettings: Identifiable, Codable, Hashable, Sendable {
    public var userID: UUID
    public var methods: [UserPaymentMethod]
    /// 受け取り口座（最大3件）。本人限定で保存する。
    public var bankAccounts: [BankReceivingAccount]
    public var otherNote: String?
    public var createdAt: Date?
    public var updatedAt: Date?

    public var id: UUID { userID }

    public init(
        userID: UUID,
        methods: [UserPaymentMethod] = [],
        bankAccounts: [BankReceivingAccount] = [],
        otherNote: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.userID = userID
        self.methods = UserPaymentMethod.normalized(methods)
        self.bankAccounts = Array(bankAccounts.prefix(BankReceivingAccount.maxCount))
        self.otherNote = otherNote
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// レガシー単一口座の互換init（既存の呼び出し箇所・プレビュー用）。
    public init(
        userID: UUID,
        methods: [UserPaymentMethod] = [],
        bankName: String,
        bankBranchName: String = "",
        bankAccountType: String = "",
        bankAccountNumber: String = "",
        bankAccountHolder: String = "",
        otherNote: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        let account = BankReceivingAccount(
            bankName: bankName,
            branchName: bankBranchName,
            accountType: bankAccountType,
            accountNumber: bankAccountNumber,
            holder: bankAccountHolder
        )
        self.init(
            userID: userID,
            methods: methods,
            bankAccounts: account.isBlank ? [] : [account],
            otherNote: otherNote,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    // MARK: - 先頭口座の互換アクセサ（単一口座を前提とする既存消費側のため）

    public var bankName: String { bankAccounts.first?.bankName ?? "" }
    public var bankBranchName: String { bankAccounts.first?.branchName ?? "" }
    public var bankAccountType: String { bankAccounts.first?.accountType ?? "" }
    public var bankAccountNumber: String { bankAccounts.first?.accountNumber ?? "" }
    public var bankAccountHolder: String { bankAccounts.first?.holder ?? "" }

    /// 相手可視面に出す銀行名（正規化・重複排除・最大3）。
    public var bankAccountDisplayNames: [String] {
        Self.dedupedBankNames(from: bankAccounts)
    }

    public var publicSummaryText: String {
        UserPaymentMethod.displayText(for: methods, otherNote: otherNote)
    }

    public var hasAnyData: Bool {
        !methods.isEmpty
            || bankAccounts.contains { !$0.isBlank }
            || otherNote?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    public func normalized(for userID: UUID? = nil) -> UserPaymentSettings {
        UserPaymentSettings(
            userID: userID ?? self.userID,
            methods: UserPaymentMethod.normalized(methods),
            bankAccounts: bankAccounts.map { $0.normalized() }.filter { !$0.isBlank },
            otherNote: Self.trimmed(otherNote).nilIfBlank,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    static func dedupedBankNames(from accounts: [BankReceivingAccount]) -> [String] {
        var seen = Set<String>()
        var names: [String] = []
        for account in accounts {
            let name = account.canonicalBankName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else {
                continue
            }
            let key = account.matchKey ?? "free:\(name.lowercased())"
            if seen.insert(key).inserted {
                names.append(name)
            }
        }
        return Array(names.prefix(BankReceivingAccount.maxCount))
    }

    private static func trimmed(_ value: String?) -> String {
        value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}

public struct TradePaymentSettingsSnapshot: Codable, Hashable, Sendable {
    public var bankName: String
    public var bankBranchName: String
    public var bankAccountType: String
    public var bankAccountNumber: String
    public var bankAccountHolder: String
    public var otherNote: String?

    public init(
        bankName: String = "",
        bankBranchName: String = "",
        bankAccountType: String = "",
        bankAccountNumber: String = "",
        bankAccountHolder: String = "",
        otherNote: String? = nil
    ) {
        self.bankName = bankName
        self.bankBranchName = bankBranchName
        self.bankAccountType = bankAccountType
        self.bankAccountNumber = bankAccountNumber
        self.bankAccountHolder = bankAccountHolder
        self.otherNote = otherNote
    }

    public var hasBankTransferDetails: Bool {
        [bankName, bankBranchName, bankAccountType, bankAccountNumber, bankAccountHolder]
            .allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
}
