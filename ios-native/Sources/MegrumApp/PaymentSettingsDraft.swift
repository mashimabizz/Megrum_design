import Foundation
import MegrumCore

struct PaymentSettingsDraft: Equatable, Sendable {
    static let otherNoteMaxLength = 8

    var methods: [UserPaymentMethod]
    var bankName: String
    var bankBranchName: String
    var bankAccountType: String
    var bankAccountNumber: String
    var bankAccountHolder: String
    var otherNote: String

    static let empty = PaymentSettingsDraft(
        methods: [],
        bankName: "",
        bankBranchName: "",
        bankAccountType: "",
        bankAccountNumber: "",
        bankAccountHolder: "",
        otherNote: ""
    )

    init(settings: UserPaymentSettings?, viewer: UserProfile?) {
        self.methods = PaymentSettingsResolver.methods(settings: settings, viewer: viewer)
        self.bankName = settings?.bankName ?? ""
        self.bankBranchName = settings?.bankBranchName ?? ""
        self.bankAccountType = settings?.bankAccountType ?? ""
        self.bankAccountNumber = settings?.bankAccountNumber ?? ""
        self.bankAccountHolder = settings?.bankAccountHolder ?? ""
        self.otherNote = Self.limitedOtherNote(Self.trimmed(PaymentSettingsResolver.otherNote(settings: settings, viewer: viewer) ?? ""))
    }

    init(
        methods: [UserPaymentMethod],
        bankName: String,
        bankBranchName: String,
        bankAccountType: String,
        bankAccountNumber: String,
        bankAccountHolder: String,
        otherNote: String
    ) {
        self.methods = UserPaymentMethod.normalized(methods)
        self.bankName = bankName
        self.bankBranchName = bankBranchName
        self.bankAccountType = bankAccountType
        self.bankAccountNumber = bankAccountNumber
        self.bankAccountHolder = bankAccountHolder
        self.otherNote = otherNote
    }

    var normalized: PaymentSettingsDraft {
        PaymentSettingsDraft(
            methods: methods,
            bankName: trimmed(bankName),
            bankBranchName: trimmed(bankBranchName),
            bankAccountType: trimmed(bankAccountType),
            bankAccountNumber: normalizedAccountNumber,
            bankAccountHolder: trimmed(bankAccountHolder),
            otherNote: Self.limitedOtherNote(trimmed(otherNote))
        )
    }

    var summaryText: String {
        UserPaymentMethod.displayText(
            for: normalized.methods,
            otherNote: normalized.otherNote.nilIfBlank,
            emptyText: "未設定"
        )
    }

    var bankPreviewText: String? {
        let normalized = normalized
        guard normalized.methods.contains(.bankTransfer),
              !normalized.bankName.isEmpty,
              !normalized.bankBranchName.isEmpty,
              !normalized.bankAccountType.isEmpty,
              !normalized.bankAccountNumber.isEmpty
        else {
            return nil
        }
        return "口座: \(normalized.bankName) \(normalized.bankBranchName) \(normalized.bankAccountType) \(maskedAccountNumber(normalized.bankAccountNumber))"
    }

    var requiresBankAccountDetails: Bool {
        contains(.bankTransfer)
    }

    var validationMessage: String? {
        let normalized = normalized
        if normalized.methods.contains(.bankTransfer) {
            let bankValues = [
                normalized.bankName,
                normalized.bankBranchName,
                normalized.bankAccountType,
                normalized.bankAccountNumber,
                normalized.bankAccountHolder
            ]
            if bankValues.contains(where: \.isEmpty) {
                return "銀行振込を選ぶ場合は口座情報を入力してください"
            }
        }
        if normalized.methods.contains(.other), normalized.otherNote.isEmpty {
            return "その他を選ぶ場合は自由入力を入力してください"
        }
        return nil
    }

    mutating func set(_ method: UserPaymentMethod, isSelected: Bool) {
        if isSelected {
            methods.append(method)
        } else {
            methods.removeAll { $0 == method }
        }
        methods = UserPaymentMethod.normalized(methods)
    }

    func contains(_ method: UserPaymentMethod) -> Bool {
        methods.contains(method)
    }

    func settings(userID: UUID) -> UserPaymentSettings {
        let normalized = normalized
        return UserPaymentSettings(
            userID: userID,
            methods: normalized.methods,
            bankName: normalized.bankName,
            bankBranchName: normalized.bankBranchName,
            bankAccountType: normalized.bankAccountType,
            bankAccountNumber: normalized.bankAccountNumber,
            bankAccountHolder: normalized.bankAccountHolder,
            otherNote: normalized.methods.contains(.other) ? normalized.otherNote.nilIfBlank : nil
        )
    }

    static func limitedOtherNote(_ value: String) -> String {
        String(value.prefix(otherNoteMaxLength))
    }

    private var normalizedAccountNumber: String {
        String(bankAccountNumber.filter(\.isNumber).prefix(32))
    }

    private func trimmed(_ value: String) -> String {
        Self.trimmed(value)
    }

    private static func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func maskedAccountNumber(_ value: String) -> String {
        let suffix = String(value.suffix(4))
        return "****\(suffix)"
    }
}
