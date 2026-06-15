import Foundation
import MegrumCore

struct SettingsAccountSummary: Equatable {
    var userIDText: String
    var handleText: String
    var displayNameText: String
    var activityAreaText: String
    var accountStatusText: String
    var paymentMethodsText: String
    var pushNotificationText: String
    var addressStatusText: String

    init(
        viewer: UserProfile?,
        pushNotificationsEnabled: Bool,
        mailingAddress: MailingAddress?
    ) {
        userIDText = viewer?.id.uuidString.lowercased() ?? "未読み込み"
        handleText = SettingsDisplayText.nonEmpty(viewer?.handle, fallback: "未設定")
        displayNameText = SettingsDisplayText.nonEmpty(viewer?.displayName, fallback: "未設定")
        activityAreaText = SettingsDisplayText.nonEmpty(viewer?.prefecture, fallback: "未設定")
        accountStatusText = viewer?.accountStatus.settingsDisplayName ?? "未読み込み"
        paymentMethodsText = Self.paymentMethodsText(viewer?.paymentMethods ?? [], otherNote: viewer?.paymentNote)
        pushNotificationText = pushNotificationsEnabled ? "ON" : "OFF"

        if let mailingAddress, mailingAddress.isReady {
            addressStatusText = "登録済み"
        } else {
            addressStatusText = "未登録"
        }
    }

    var shortStatusText: String {
        "\(displayNameText) / 通知\(pushNotificationText)"
    }

    private static func paymentMethodsText(_ methods: [UserPaymentMethod], otherNote: String?) -> String {
        UserPaymentMethod.displayText(for: methods, otherNote: otherNote)
    }
}

struct LoginSecuritySummary: Equatable {
    var authStatusText: String
    var emailText: String
    var authUserIDText: String
    var profileUserIDText: String
    var authConfigurationText: String
    var accountStatusText: String

    init(
        authSession: AuthSession?,
        isAuthenticated: Bool,
        isAuthConfigured: Bool,
        accountSummary: SettingsAccountSummary
    ) {
        authStatusText = isAuthenticated ? "ログイン中" : "再ログインが必要"
        emailText = SettingsDisplayText.nonEmpty(authSession?.user.email, fallback: "メール未取得")
        authUserIDText = authSession?.user.id.uuidString.lowercased() ?? "セッション未確認"
        profileUserIDText = accountSummary.userIDText
        authConfigurationText = isAuthConfigured ? "Supabase接続" : "プレビュー接続"
        accountStatusText = accountSummary.accountStatusText
    }

    var shortStatusText: String {
        "\(authStatusText) / \(authConfigurationText)"
    }

    var resetEmailPrefill: String {
        emailText == "メール未取得" ? "" : emailText
    }

}

private enum SettingsDisplayText {
    static func nonEmpty(_ value: String?, fallback: String) -> String {
        let trimmedValue = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmedValue.isEmpty ? fallback : trimmedValue
    }
}

enum MailingAddressDraftValidator {
    static let missingRequiredMessage = "宛名・郵便番号・都道府県・市区町村・番地を入力してください"
    static let invalidPostalCodeMessage = "郵便番号は7桁で入力してください"

    static func validationMessage(for address: MailingAddress) -> String? {
        let requiredValues = [
            address.recipientName,
            address.postalCode,
            address.prefecture,
            address.city,
            address.line1
        ]
        if requiredValues.contains(where: { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
            return missingRequiredMessage
        }
        if address.postalCode.count != 7 {
            return invalidPostalCodeMessage
        }
        return nil
    }
}

enum SettingsEssentialRoute: String, CaseIterable, Identifiable {
    case notifications
    case mobilePush
    case address
    case payment
    case blockedUsers
    case privacy
    case loginSecurity
    case help
    case terms
    case privacyPolicy
    case commerceDisclosure
    case account
    case logout

    var id: String { rawValue }

    static let p0Routes: [SettingsEssentialRoute] = [
        .notifications,
        .mobilePush,
        .address,
        .payment,
        .blockedUsers,
        .privacy,
        .loginSecurity,
        .help,
        .terms,
        .privacyPolicy,
        .commerceDisclosure,
        .account,
        .logout
    ]
}

private extension AccountStatus {
    var settingsDisplayName: String {
        switch self {
        case .registered:
            "仮登録"
        case .verified:
            "認証済"
        case .onboarding:
            "オンボ中"
        case .active:
            "アクティブ"
        case .suspended:
            "停止中"
        case .deletionRequested:
            "削除申請中"
        case .deleted:
            "削除済"
        }
    }
}
