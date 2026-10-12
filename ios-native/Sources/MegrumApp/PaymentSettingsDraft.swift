import Foundation
import MegrumCore

struct PaymentSettingsDraft: Equatable, Sendable {
    static let otherNoteMaxLength = 8

    var methods: [UserPaymentMethod]
    var accounts: [BankReceivingAccount]
    var otherNote: String

    static let empty = PaymentSettingsDraft(
        methods: [],
        accounts: [],
        otherNote: ""
    )

    init(settings: UserPaymentSettings?, viewer: UserProfile?) {
        self.methods = PaymentSettingsResolver.methods(settings: settings, viewer: viewer)
        self.accounts = settings?.bankAccounts ?? []
        self.otherNote = Self.limitedOtherNote(
            Self.trimmed(PaymentSettingsResolver.otherNote(settings: settings, viewer: viewer) ?? "")
        )
    }

    init(
        methods: [UserPaymentMethod],
        accounts: [BankReceivingAccount],
        otherNote: String
    ) {
        self.methods = UserPaymentMethod.normalized(methods)
        self.accounts = Array(accounts.prefix(BankReceivingAccount.maxCount))
        self.otherNote = otherNote
    }

    var normalized: PaymentSettingsDraft {
        PaymentSettingsDraft(
            methods: methods,
            accounts: accounts.map { $0.normalized() }.filter { !$0.isBlank },
            otherNote: Self.limitedOtherNote(Self.trimmed(otherNote))
        )
    }

    var summaryText: String {
        UserPaymentMethod.displayText(
            for: normalized.methods,
            otherNote: normalized.otherNote.nilIfBlank,
            emptyText: "未設定"
        )
    }

    var requiresBankAccountDetails: Bool {
        contains(.bankTransfer)
    }

    var canAddAccount: Bool {
        accounts.count < BankReceivingAccount.maxCount
    }

    var validationMessage: String? {
        let normalized = normalized
        if normalized.methods.contains(.bankTransfer) {
            if normalized.accounts.isEmpty {
                return "銀行振込を選ぶ場合は受け取り口座を1件以上入力してください"
            }
            if normalized.accounts.contains(where: { !$0.isComplete }) {
                return "受け取り口座は銀行名・支店・種別・口座番号・名義をすべて入力してください"
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

    @discardableResult
    mutating func appendAccount(_ account: BankReceivingAccount) -> Bool {
        guard canAddAccount else {
            return false
        }
        accounts.append(account)
        return true
    }

    mutating func removeAccount(id: UUID) {
        accounts.removeAll { $0.id == id }
    }

    mutating func updateAccount(_ account: BankReceivingAccount) {
        guard let index = accounts.firstIndex(where: { $0.id == account.id }) else {
            return
        }
        accounts[index] = account
    }

    func settings(userID: UUID) -> UserPaymentSettings {
        let normalized = normalized
        let offersBankTransfer = normalized.methods.contains(.bankTransfer)
        return UserPaymentSettings(
            userID: userID,
            methods: normalized.methods,
            bankAccounts: offersBankTransfer ? normalized.accounts : [],
            otherNote: normalized.methods.contains(.other) ? normalized.otherNote.nilIfBlank : nil
        )
    }

    static func limitedOtherNote(_ value: String) -> String {
        String(value.prefix(otherNoteMaxLength))
    }

    private static func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
