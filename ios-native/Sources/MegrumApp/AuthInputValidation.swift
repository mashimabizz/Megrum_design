import Foundation

public struct AuthSignUpInput: Equatable, Sendable {
    public var email: String
    public var password: String
    public var handle: String?
    public var displayName: String?

    public init(email: String, password: String, handle: String? = nil, displayName: String? = nil) {
        self.email = email
        self.password = password
        self.handle = handle
        self.displayName = displayName
    }
}

public enum MegrumAuthInputValidator {
    public static let invalidEmailMessage = "メールアドレスの形式を確認してください"
    public static let missingPasswordMessage = "パスワードを入力してください"
    public static let shortPasswordMessage = "パスワードは8文字以上で入力してください"
    public static let invalidHandleMessage = "ユーザーIDは3〜24文字の英数字と_で入力してください"

    public static func normalizedEmail(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func isValidEmail(_ email: String) -> Bool {
        let value = normalizedEmail(email)
        guard !value.isEmpty, value.rangeOfCharacter(from: .whitespacesAndNewlines) == nil else {
            return false
        }

        let parts = value.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2, !parts[0].isEmpty, !parts[1].isEmpty else {
            return false
        }

        let domain = parts[1]
        let labels = domain.split(separator: ".", omittingEmptySubsequences: false)
        return labels.count >= 2 && labels.allSatisfy { !$0.isEmpty }
    }

    public static func isValidSignInPassword(_ password: String) -> Bool {
        !password.isEmpty
    }

    public static func isValidSignUpPassword(_ password: String) -> Bool {
        password.count >= 8 && !password.isBlank
    }

    public static func normalizedHandle(_ handle: String?) -> String? {
        handle.nilIfBlank
    }

    public static func isValidHandle(_ handle: String?) -> Bool {
        guard let handle = normalizedHandle(handle) else {
            return true
        }
        guard (3...24).contains(handle.count) else {
            return false
        }
        return handle.range(of: #"^[A-Za-z0-9_]+$"#, options: .regularExpression) != nil
    }

    public static func signInValidationMessage(email: String, password: String) -> String? {
        guard isValidEmail(email) else {
            return invalidEmailMessage
        }
        guard isValidSignInPassword(password) else {
            return missingPasswordMessage
        }
        return nil
    }

    public static func signUpValidationMessage(email: String, password: String, handle: String?) -> String? {
        guard isValidEmail(email) else {
            return invalidEmailMessage
        }
        guard isValidSignUpPassword(password) else {
            return shortPasswordMessage
        }
        guard isValidHandle(handle) else {
            return invalidHandleMessage
        }
        return nil
    }

    public static func passwordResetValidationMessage(email: String) -> String? {
        isValidEmail(email) ? nil : invalidEmailMessage
    }
}
