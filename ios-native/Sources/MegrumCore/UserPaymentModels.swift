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

public struct UserPaymentSettings: Identifiable, Codable, Hashable, Sendable {
    public var userID: UUID
    public var methods: [UserPaymentMethod]
    public var bankName: String
    public var bankBranchName: String
    public var bankAccountType: String
    public var bankAccountNumber: String
    public var bankAccountHolder: String
    public var otherNote: String?
    public var createdAt: Date?
    public var updatedAt: Date?

    public var id: UUID { userID }

    public init(
        userID: UUID,
        methods: [UserPaymentMethod] = [],
        bankName: String = "",
        bankBranchName: String = "",
        bankAccountType: String = "",
        bankAccountNumber: String = "",
        bankAccountHolder: String = "",
        otherNote: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.userID = userID
        self.methods = UserPaymentMethod.normalized(methods)
        self.bankName = bankName
        self.bankBranchName = bankBranchName
        self.bankAccountType = bankAccountType
        self.bankAccountNumber = bankAccountNumber
        self.bankAccountHolder = bankAccountHolder
        self.otherNote = otherNote
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var publicSummaryText: String {
        UserPaymentMethod.displayText(for: methods, otherNote: otherNote)
    }

    public func normalized(for userID: UUID? = nil) -> UserPaymentSettings {
        UserPaymentSettings(
            userID: userID ?? self.userID,
            methods: UserPaymentMethod.normalized(methods),
            bankName: Self.trimmed(bankName),
            bankBranchName: Self.trimmed(bankBranchName),
            bankAccountType: Self.trimmed(bankAccountType),
            bankAccountNumber: Self.trimmed(bankAccountNumber),
            bankAccountHolder: Self.trimmed(bankAccountHolder),
            otherNote: Self.trimmed(otherNote).nilIfBlank,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
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
