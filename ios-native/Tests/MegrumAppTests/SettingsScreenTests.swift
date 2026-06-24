@testable import MegrumApp
import MegrumCore
import XCTest

final class SettingsScreenTests: XCTestCase {
    func testDrawerItemsMatchRnProfileDrawerDestinations() {
        XCTAssertEqual(
            AppDrawerDestination.primaryItems,
            [.profile, .notifications, .oshiSettings, .schedules, .paymentSettings, .exchangeSettings]
        )
        XCTAssertFalse(AppDrawerDestination.primaryItems.contains(.profileEdit))
        XCTAssertEqual(
            AppDrawerDestination.compactItems,
            [.settings, .help]
        )

        XCTAssertEqual(AppDrawerDestination.notifications.title, "通知")
        XCTAssertEqual(AppDrawerDestination.oshiSettings.title, "推し設定")
        XCTAssertEqual(AppDrawerDestination.schedules.title, "スケジュール")
        XCTAssertEqual(AppDrawerDestination.paymentSettings.title, "支払条件設定")
        XCTAssertEqual(AppDrawerDestination.exchangeSettings.title, "交換条件設定")
        XCTAssertEqual(AppDrawerDestination.help.title, "ヘルプ")
        XCTAssertEqual(AppDrawerDestination.oshiSettings.systemImage, "sparkles")
        XCTAssertEqual(AppDrawerDestination.paymentSettings.systemImage, "yensign.circle")
        XCTAssertEqual(AppDrawerDestination.exchangeSettings.systemImage, "arrow.left.arrow.right.circle")
        XCTAssertEqual(AppDrawerDestination.settings.systemImage, "checkmark.shield")
    }

    func testSettingsEssentialRoutesCoverP0Settings() {
        XCTAssertEqual(
            SettingsEssentialRoute.p0Routes,
            [
                .notifications,
                .mobilePush,
                .address,
                .premium,
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
        )
    }

    func testAccountSummaryFormatsViewerAndReadyAddress() {
        let viewerID = UUID(uuidString: "20000000-0000-0000-0000-000000000001")!
        let viewer = UserProfile(
            id: viewerID,
            handle: "michilion",
            displayName: " みちりおん ",
            prefecture: " 東京都 ",
            paymentMethods: [.bankTransfer, .cashExchange, .other],
            paymentNote: "メルペイ相談可"
        )
        let address = MailingAddress(
            userID: viewerID,
            recipientName: "松尾",
            postalCode: "1500001",
            prefecture: "東京都",
            city: "渋谷区",
            line1: "神宮前1-1-1"
        )

        let summary = SettingsAccountSummary(
            viewer: viewer,
            pushNotificationsEnabled: true,
            mailingAddress: address
        )

        XCTAssertEqual(summary.userIDText, "20000000-0000-0000-0000-000000000001")
        XCTAssertEqual(summary.handleText, "michilion")
        XCTAssertEqual(summary.displayNameText, "みちりおん")
        XCTAssertEqual(summary.activityAreaText, "東京都")
        XCTAssertEqual(summary.accountStatusText, "アクティブ")
        XCTAssertEqual(summary.paymentMethodsText, "銀行振込 / 現金交換 / メルペイ相談可")
        XCTAssertEqual(summary.pushNotificationText, "ON")
        XCTAssertEqual(summary.addressStatusText, "登録済み")
        XCTAssertEqual(summary.shortStatusText, "みちりおん / 通知ON")
    }

    func testAccountSummaryUsesFallbacksWhenValuesAreMissing() {
        let viewer = UserProfile(
            id: UUID(uuidString: "20000000-0000-0000-0000-000000000002")!,
            handle: "empty",
            displayName: " ",
            prefecture: nil
        )

        let summary = SettingsAccountSummary(
            viewer: viewer,
            pushNotificationsEnabled: false,
            mailingAddress: nil
        )

        XCTAssertEqual(summary.displayNameText, "未設定")
        XCTAssertEqual(summary.activityAreaText, "未設定")
        XCTAssertEqual(summary.accountStatusText, "アクティブ")
        XCTAssertEqual(summary.paymentMethodsText, "未設定")
        XCTAssertEqual(summary.pushNotificationText, "OFF")
        XCTAssertEqual(summary.addressStatusText, "未登録")
        XCTAssertEqual(summary.shortStatusText, "未設定 / 通知OFF")
    }

    func testAccountSummaryHandlesUnloadedViewer() {
        let summary = SettingsAccountSummary(
            viewer: nil,
            pushNotificationsEnabled: true,
            mailingAddress: nil
        )

        XCTAssertEqual(summary.userIDText, "未読み込み")
        XCTAssertEqual(summary.handleText, "未設定")
        XCTAssertEqual(summary.displayNameText, "未設定")
        XCTAssertEqual(summary.activityAreaText, "未設定")
        XCTAssertEqual(summary.accountStatusText, "未読み込み")
    }

    func testPaymentSettingsDraftFormatsPreviewAndValidation() {
        var draft = PaymentSettingsDraft(
            methods: [.bankTransfer, .paypay, .cashExchange, .other],
            bankName: " みずほ銀行 ",
            bankBranchName: " 渋谷支店 ",
            bankAccountType: " 普通 ",
            bankAccountNumber: "1234567",
            bankAccountHolder: " ヤマダ ハナコ ",
            otherNote: " 楽天ペイ相談可能です "
        )

        XCTAssertNil(draft.validationMessage)
        XCTAssertEqual(PaymentSettingsDraft.limitedOtherNote("123456789"), "12345678")
        XCTAssertEqual(draft.normalized.otherNote, "楽天ペイ相談可能")
        XCTAssertEqual(draft.normalized.summaryText, "銀行振込 / PayPay / 現金交換 / 楽天ペイ相談可能")
        XCTAssertEqual(draft.normalized.bankPreviewText, "口座: みずほ銀行 渋谷支店 普通 ****4567")

        draft.otherNote = " "
        XCTAssertEqual(draft.validationMessage, "その他を選ぶ場合は自由入力を入力してください")

        draft.set(.other, isSelected: false)
        XCTAssertNil(draft.settings(userID: UUID()).otherNote)
    }

    func testLoginSecuritySummaryFormatsAuthenticatedSession() {
        let viewerID = UUID(uuidString: "20000000-0000-0000-0000-000000000003")!
        let authUserID = UUID(uuidString: "99999999-9999-9999-9999-999999999999")!
        let accountSummary = SettingsAccountSummary(
            viewer: UserProfile(
                id: viewerID,
                handle: "michi",
                displayName: "みち",
                accountStatus: .verified
            ),
            pushNotificationsEnabled: true,
            mailingAddress: nil
        )
        let authSession = AuthSession(
            accessToken: "access",
            refreshToken: "refresh",
            user: AuthUser(
                id: authUserID,
                email: " michi@example.com "
            )
        )

        let summary = LoginSecuritySummary(
            authSession: authSession,
            isAuthenticated: true,
            isAuthConfigured: true,
            accountSummary: accountSummary
        )

        XCTAssertEqual(summary.authStatusText, "ログイン中")
        XCTAssertEqual(summary.emailText, "michi@example.com")
        XCTAssertEqual(summary.authUserIDText, "99999999-9999-9999-9999-999999999999")
        XCTAssertEqual(summary.profileUserIDText, "20000000-0000-0000-0000-000000000003")
        XCTAssertEqual(summary.authConfigurationText, "Supabase接続")
        XCTAssertEqual(summary.accountStatusText, "認証済")
        XCTAssertEqual(summary.shortStatusText, "ログイン中 / Supabase接続")
        XCTAssertEqual(summary.resetEmailPrefill, "michi@example.com")
    }

    func testLoginSecuritySummaryUsesFallbacksWithoutSessionEmail() {
        let accountSummary = SettingsAccountSummary(
            viewer: nil,
            pushNotificationsEnabled: false,
            mailingAddress: nil
        )

        let summary = LoginSecuritySummary(
            authSession: nil,
            isAuthenticated: false,
            isAuthConfigured: false,
            accountSummary: accountSummary
        )

        XCTAssertEqual(summary.authStatusText, "再ログインが必要")
        XCTAssertEqual(summary.emailText, "メール未取得")
        XCTAssertEqual(summary.authUserIDText, "セッション未確認")
        XCTAssertEqual(summary.profileUserIDText, "未読み込み")
        XCTAssertEqual(summary.authConfigurationText, "プレビュー接続")
        XCTAssertEqual(summary.accountStatusText, "未読み込み")
        XCTAssertEqual(summary.resetEmailPrefill, "")
    }

    func testLegalDocumentKindsExposeMinimumEntrancesWithoutFullText() {
        XCTAssertEqual(LegalDocumentKind.terms.title, "利用規約")
        XCTAssertEqual(LegalDocumentKind.privacy.title, "プライバシーポリシー")
        XCTAssertEqual(LegalDocumentKind.commerce.title, "特定商取引法に基づく表記")
        XCTAssertTrue(LegalDocumentKind.terms.statusMessage.contains("正式な法的本文ではありません"))
        XCTAssertTrue(LegalDocumentKind.commerce.summaryItems.contains { item in
            item.title == "表示方針" && item.body.contains("請求があれば")
        })
    }

    func testMailingAddressDraftValidatorRequiresFieldsBeforeSave() {
        let address = MailingAddress(
            userID: UUID(uuidString: "20000000-0000-0000-0000-000000000004")!,
            recipientName: "",
            postalCode: "",
            prefecture: "",
            city: "",
            line1: ""
        )

        XCTAssertEqual(
            MailingAddressDraftValidator.validationMessage(for: address),
            MailingAddressDraftValidator.missingRequiredMessage
        )
    }

    func testMailingAddressDraftValidatorSeparatesPostalCodeLength() {
        let address = MailingAddress(
            userID: UUID(uuidString: "20000000-0000-0000-0000-000000000005")!,
            recipientName: "みち",
            postalCode: "150000",
            prefecture: "東京都",
            city: "渋谷区",
            line1: "神宮前1-1-1"
        )

        XCTAssertEqual(
            MailingAddressDraftValidator.validationMessage(for: address),
            MailingAddressDraftValidator.invalidPostalCodeMessage
        )
    }

    func testMailingAddressDraftValidatorAcceptsReadyAddress() {
        let address = MailingAddress(
            userID: UUID(uuidString: "20000000-0000-0000-0000-000000000006")!,
            recipientName: "みち",
            postalCode: "1500001",
            prefecture: "東京都",
            city: "渋谷区",
            line1: "神宮前1-1-1"
        )

        XCTAssertNil(MailingAddressDraftValidator.validationMessage(for: address))
    }
}
