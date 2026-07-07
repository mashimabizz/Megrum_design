@testable import MegrumApp
import MegrumCore
import XCTest

final class SettingsScreenTests: XCTestCase {
    func testDrawerItemsMatchRnProfileDrawerDestinations() {
        XCTAssertEqual(
            AppDrawerDestination.primaryItems,
            [.profile, .notifications, .oshiSettings, .paymentSettings, .exchangeSettings]
        )
        XCTAssertFalse(AppDrawerDestination.primaryItems.contains(.profileEdit))
        XCTAssertFalse(AppDrawerDestination.primaryItems.contains(.schedules))
        XCTAssertEqual(
            AppDrawerDestination.compactItems,
            [.settings, .help]
        )
        XCTAssertEqual(AppDrawerDestination.plusItems, [.megrumPlus])

        XCTAssertEqual(AppDrawerDestination.notifications.title, "通知")
        XCTAssertEqual(AppDrawerDestination.oshiSettings.title, "推し設定")
        XCTAssertEqual(AppDrawerDestination.schedules.title, "スケジュール")
        XCTAssertEqual(AppDrawerDestination.paymentSettings.title, "支払い方法の設定")
        XCTAssertEqual(AppDrawerDestination.exchangeSettings.title, "交換条件の設定")
        XCTAssertEqual(AppDrawerDestination.help.title, "ヘルプ")
        XCTAssertEqual(AppDrawerDestination.megrumPlus.title, "Megrumプレミアム")
        XCTAssertEqual(AppDrawerDestination.oshiSettings.systemImage, "sparkles")
        XCTAssertEqual(AppDrawerDestination.paymentSettings.systemImage, "yensign.circle")
        XCTAssertEqual(AppDrawerDestination.exchangeSettings.systemImage, "arrow.left.arrow.right.circle")
        XCTAssertEqual(AppDrawerDestination.settings.systemImage, "checkmark.shield")
        XCTAssertEqual(AppDrawerDestination.megrumPlus.systemImage, "sparkles.rectangle.stack")
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
                .meguriBlockedUsers,
                .privacy,
                .loginSecurity,
                .help,
                .terms,
                .privacyPolicy,
                .commerceDisclosure,
                .account,
                .accountDeletion,
                .logout
            ]
        )
    }

    func testLegalDocumentKindPublicURLsPointToMegrumLegalPages() {
        XCTAssertEqual(LegalDocumentKind.terms.publicURL?.absoluteString, "https://megrum.jp/legal/terms")
        XCTAssertEqual(LegalDocumentKind.privacy.publicURL?.absoluteString, "https://megrum.jp/legal/privacy")
        XCTAssertEqual(LegalDocumentKind.commerce.publicURL?.absoluteString, "https://megrum.jp/legal/commerce")
    }

    func testSettingsPresentationStateTracksNavigationAndSignOutLifecycle() {
        var state = SettingsPresentationState()

        state.openRoute(.loginSecurity)
        state.openRoute(.accountDeletion)

        XCTAssertEqual(state.navigationPath, [.loginSecurity, .accountDeletion])
        XCTAssertTrue(state.beginSignOutIfNeeded())
        XCTAssertTrue(state.isSigningOut)
        XCTAssertFalse(state.beginSignOutIfNeeded())

        state.finishSignOut()

        XCTAssertFalse(state.isSigningOut)
        XCTAssertTrue(state.beginSignOutIfNeeded())
    }

    func testNativeLoadingFailurePresentationStateTracksRetryAndSignOutActions() {
        var state = NativeLoadingFailurePresentationState()

        XCTAssertEqual(state.retryTitle, "再読み込み")
        XCTAssertEqual(state.signOutTitle, "ログアウトしてやり直す")
        XCTAssertFalse(state.actionsDisabled)

        state.beginRetry()

        XCTAssertTrue(state.isRetrying)
        XCTAssertEqual(state.retryTitle, "再読み込み中")
        XCTAssertTrue(state.actionsDisabled)

        state.finishRetry()
        state.beginSignOut()

        XCTAssertFalse(state.isRetrying)
        XCTAssertTrue(state.isSigningOut)
        XCTAssertEqual(state.signOutTitle, "ログアウト中")
        XCTAssertTrue(state.actionsDisabled)

        state.finishSignOut()

        XCTAssertFalse(state.actionsDisabled)
    }

    func testSettingsStatusTextResolverFormatsNotificationStates() {
        XCTAssertEqual(
            SettingsStatusTextResolver.notificationStatusText(hasNotifications: false, unreadCount: 0),
            "未読なし"
        )
        XCTAssertEqual(
            SettingsStatusTextResolver.notificationStatusText(hasNotifications: true, unreadCount: 3),
            "未読 3件"
        )
        XCTAssertEqual(
            SettingsStatusTextResolver.notificationStatusText(hasNotifications: true, unreadCount: 0),
            "すべて既読"
        )
    }

    func testSettingsStatusTextResolverFormatsProfileAddressAndSubscription() {
        let viewerID = UUID(uuidString: "20000000-0000-0000-0000-000000000071")!
        let viewer = UserProfile(
            id: viewerID,
            handle: "michi",
            displayName: "みち",
            prefecture: "東京都"
        )
        let address = MailingAddress(
            userID: viewerID,
            recipientName: "松尾",
            postalCode: "1500001",
            prefecture: "東京都",
            city: "渋谷区",
            line1: "神宮前1-1-1"
        )

        XCTAssertEqual(SettingsStatusTextResolver.profileStatusText(viewer: nil), "未読み込み")
        XCTAssertEqual(SettingsStatusTextResolver.profileStatusText(viewer: viewer), "みち / 東京都")
        XCTAssertEqual(SettingsStatusTextResolver.addressStatusText(address: nil), "未登録")
        XCTAssertEqual(SettingsStatusTextResolver.addressStatusText(address: address), address.summary)
        XCTAssertEqual(SettingsStatusTextResolver.subscriptionStatusText(isActive: true), "有効")
        XCTAssertEqual(SettingsStatusTextResolver.subscriptionStatusText(isActive: false), "未加入")
    }

    func testSubscriptionSettingsPresentationStateTracksOfferAndPurchaseFeedback() {
        let fallbackOffer = MegrumPlusPurchaseOffer(
            productID: "fallback",
            displayName: "Megrumプレミアム",
            priceText: "月額500円"
        )
        let storeOffer = MegrumPlusPurchaseOffer(
            productID: "store",
            displayName: "Megrumプレミアム",
            priceText: "¥500"
        )
        var state = SubscriptionSettingsPresentationState()

        XCTAssertEqual(state.displayOffer(fallback: fallbackOffer), fallbackOffer)
        XCTAssertTrue(state.beginLoadingOfferIfNeeded())
        XCTAssertTrue(state.isLoadingOffer)
        XCTAssertFalse(state.beginLoadingOfferIfNeeded())

        state.finishLoadingOffer(storeOffer)

        XCTAssertEqual(state.displayOffer(fallback: fallbackOffer), storeOffer)
        XCTAssertFalse(state.isLoadingOffer)
        XCTAssertFalse(state.beginLoadingOfferIfNeeded())

        state.setPurchaseMessage("古い成功")
        state.setPurchaseErrorMessage("古いエラー")

        XCTAssertNil(state.purchaseMessage)
        XCTAssertEqual(state.purchaseErrorMessage, "古いエラー")
        XCTAssertTrue(state.beginPurchaseAction())
        XCTAssertTrue(state.isPurchasing)
        XCTAssertNil(state.purchaseMessage)
        XCTAssertNil(state.purchaseErrorMessage)
        XCTAssertFalse(state.beginPurchaseAction())

        state.setPurchaseMessage("有効になりました")
        XCTAssertEqual(state.purchaseMessage, "有効になりました")
        XCTAssertNil(state.purchaseErrorMessage)

        state.finishPurchaseAction()

        XCTAssertFalse(state.isPurchasing)
    }

    func testMegrumPlusRuntimeConfigurationKeepsIAPDisabledByDefault() {
        let configuration = MegrumPlusRuntimeConfiguration.current(environment: [:], infoDictionary: [:])

        XCTAssertFalse(configuration.isIAPEnabled)
    }

    func testMegrumPlusRuntimeConfigurationReadsExplicitIAPEnablement() {
        let environmentConfiguration = MegrumPlusRuntimeConfiguration.current(
            environment: ["MEGRUM_PLUS_IAP_ENABLED": "YES"],
            infoDictionary: ["MegrumPlusIAPEnabled": "NO"]
        )
        let infoConfiguration = MegrumPlusRuntimeConfiguration.current(
            environment: [:],
            infoDictionary: ["MegrumPlusIAPEnabled": "true"]
        )
        let unresolvedConfiguration = MegrumPlusRuntimeConfiguration.current(
            environment: [:],
            infoDictionary: ["MegrumPlusIAPEnabled": "$(MEGRUM_PLUS_IAP_ENABLED)"]
        )

        XCTAssertTrue(environmentConfiguration.isIAPEnabled)
        XCTAssertTrue(infoConfiguration.isIAPEnabled)
        XCTAssertFalse(unresolvedConfiguration.isIAPEnabled)
    }

    func testSettingsStatusTextResolverFormatsPushNotificationRows() {
        XCTAssertEqual(SettingsStatusTextResolver.pushNotificationStatusText(isEnabled: true), "端末に通知を届ける")
        XCTAssertEqual(SettingsStatusTextResolver.pushNotificationStatusText(isEnabled: false), "端末通知はOFF")
        XCTAssertEqual(SettingsStatusTextResolver.groomNotificationStatusText(isEnabled: true), "いいね・メッセージ")
        XCTAssertEqual(SettingsStatusTextResolver.groomNotificationStatusText(isEnabled: false), "グルーム通知はOFF")
        XCTAssertEqual(SettingsStatusTextResolver.chatroomNotificationStatusText(isEnabled: true), "投稿・返信")
        XCTAssertEqual(SettingsStatusTextResolver.chatroomNotificationStatusText(isEnabled: false), "チャットルーム通知はOFF")
    }

    func testAccountDeletionDraftValidatorRequiresReasonAndLimitsMemo() {
        XCTAssertEqual(
            AccountDeletionDraftValidator.validationMessage(reasons: [], note: ""),
            AccountDeletionDraftValidator.missingReasonMessage
        )

        let tooLongNote = String(repeating: "あ", count: AccountDeletionDraftValidator.noteMaxLength + 1)
        XCTAssertEqual(
            AccountDeletionDraftValidator.validationMessage(reasons: [.notUsing], note: tooLongNote),
            AccountDeletionDraftValidator.noteTooLongMessage
        )

        let input = AccountDeletionRequestInput(
            reasons: [.other, .notUsing, .other],
            note: "  ありがとうございました  "
        ).normalized

        XCTAssertEqual(input.reasons, [.other, .notUsing])
        XCTAssertEqual(input.note, "ありがとうございました")
    }

    func testAccountDeletionDraftStateTracksReasonsNoteAndSubmissionInput() {
        var state = AccountDeletionDraftState()
        state.toggle(.notUsing)
        state.toggle(.privacyConcern)
        state.toggle(.notUsing)
        state.setNote("  退会理由  ")

        let input = state.submissionInput

        XCTAssertEqual(state.selectedReasons, [.privacyConcern])
        XCTAssertEqual(input.reasons, [.privacyConcern])
        XCTAssertEqual(input.note, "退会理由")
    }

    func testAccountDeletionDraftStateValidatesAndMovesSteps() {
        var state = AccountDeletionDraftState()

        XCTAssertFalse(state.validateReasonsStep())
        XCTAssertEqual(
            state.validationMessage,
            AccountDeletionDraftValidator.missingReasonMessage
        )

        state.clearValidationMessage()
        XCTAssertNil(state.validationMessage)
        state.setOngoingTradeValidationMessage()
        XCTAssertEqual(state.validationMessage, "現在進行中の取引があるため退会できません")

        state.moveToReasonsStep()
        XCTAssertEqual(state.step, .reasons)
        state.returnToWarningStep()
        XCTAssertEqual(state.step, .warning)
    }

    func testAccountDeletionDraftStateLimitsNoteAndRequestsConfirmation() {
        var state = AccountDeletionDraftState()
        let tooLongNote = String(repeating: "あ", count: AccountDeletionDraftValidator.noteMaxLength + 20)

        state.setNote(tooLongNote)
        state.toggle(.other)
        let isValid = state.validateReasonsStep()
        state.requestFinalConfirmation()

        XCTAssertEqual(state.note.count, AccountDeletionDraftValidator.noteMaxLength)
        XCTAssertTrue(isValid)
        XCTAssertTrue(state.showsFinalConfirmation)
    }

    func testAccountDeletionEligibilityBlocksOnlyOngoingParticipantTrades() {
        let viewerID = UUID(uuidString: "20000000-0000-0000-0000-000000000021")!
        let partnerID = UUID(uuidString: "20000000-0000-0000-0000-000000000022")!
        let otherID = UUID(uuidString: "20000000-0000-0000-0000-000000000023")!
        let unrelatedID = UUID(uuidString: "20000000-0000-0000-0000-000000000024")!

        let proposals = [
            Self.proposal(idSuffix: 1, senderID: viewerID, receiverID: partnerID, status: .sent),
            Self.proposal(idSuffix: 2, senderID: viewerID, receiverID: partnerID, status: .negotiating),
            Self.proposal(idSuffix: 3, senderID: viewerID, receiverID: partnerID, status: .agreementOneSide),
            Self.proposal(idSuffix: 4, senderID: viewerID, receiverID: partnerID, status: .agreed),
            Self.proposal(idSuffix: 5, senderID: viewerID, receiverID: partnerID, status: .completed),
            Self.proposal(idSuffix: 6, senderID: viewerID, receiverID: partnerID, status: .cancelled),
            Self.proposal(idSuffix: 7, senderID: otherID, receiverID: partnerID, status: .sent)
        ]

        let ongoing = AccountDeletionEligibility.ongoingProposals(
            in: proposals,
            viewerID: viewerID
        )

        XCTAssertEqual(ongoing.map(\.status), [.sent, .negotiating, .agreementOneSide, .agreed])
        XCTAssertFalse(AccountDeletionEligibility.canRequestDeletion(proposals: proposals, viewerID: viewerID))
        XCTAssertTrue(AccountDeletionEligibility.canRequestDeletion(proposals: proposals, viewerID: unrelatedID))
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
            accounts: [
                BankReceivingAccount(
                    bankName: " みずほ銀行 ",
                    branchName: " 渋谷支店 ",
                    accountType: " 普通 ",
                    accountNumber: "1234567",
                    holder: " ヤマダ ハナコ "
                )
            ],
            otherNote: " 楽天ペイ相談可能です "
        )

        XCTAssertNil(draft.validationMessage)
        XCTAssertTrue(draft.requiresBankAccountDetails)
        XCTAssertEqual(PaymentSettingsDraft.limitedOtherNote("123456789"), "12345678")
        XCTAssertEqual(draft.normalized.otherNote, "楽天ペイ相談可能")
        XCTAssertEqual(draft.normalized.summaryText, "銀行振込 / PayPay / 現金交換 / 楽天ペイ相談可能")

        let normalizedAccount = draft.normalized.accounts.first
        XCTAssertEqual(normalizedAccount?.bankName, "みずほ銀行")
        XCTAssertEqual(normalizedAccount?.branchName, "渋谷支店")
        XCTAssertEqual(normalizedAccount?.accountType, "普通")
        XCTAssertEqual(normalizedAccount?.accountNumber, "1234567")
        XCTAssertEqual(normalizedAccount?.holder, "ヤマダ ハナコ")

        draft.otherNote = " "
        XCTAssertEqual(draft.validationMessage, "その他を選ぶ場合は自由入力を入力してください")

        draft.set(.other, isSelected: false)
        draft.set(.bankTransfer, isSelected: false)
        XCTAssertFalse(draft.requiresBankAccountDetails)
        XCTAssertNil(draft.settings(userID: UUID()).otherNote)
    }

    func testPaymentSettingsDraftRestoresStoredMethodsBeforeViewerFallback() {
        let userID = UUID(uuidString: "00000000-0000-0000-0000-000000000821")!
        let viewer = UserProfile(
            id: userID,
            handle: "michi",
            displayName: "みち",
            paymentMethods: [],
            paymentNote: "プロフィール側"
        )
        let settings = UserPaymentSettings(
            userID: userID,
            methods: [.paypay, .other],
            otherNote: "設定側"
        )

        let draft = PaymentSettingsDraft(settings: settings, viewer: viewer)

        XCTAssertEqual(draft.methods, [.paypay, .other])
        XCTAssertEqual(draft.otherNote, "設定側")
    }

    func testPaymentSettingsDraftFallsBackToViewerMethodsWhenStoredMethodsAreEmpty() {
        let userID = UUID(uuidString: "00000000-0000-0000-0000-000000000822")!
        let viewer = UserProfile(
            id: userID,
            handle: "michi",
            displayName: "みち",
            paymentMethods: [.bankTransfer, .cashExchange],
            paymentNote: "プロフィール側"
        )
        let settings = UserPaymentSettings(
            userID: userID,
            methods: [],
            otherNote: nil
        )

        let draft = PaymentSettingsDraft(settings: settings, viewer: viewer)

        XCTAssertEqual(draft.methods, [.bankTransfer, .cashExchange])
        XCTAssertEqual(draft.otherNote, "プロフィール側")
    }

    func testPaymentSettingsEditingStateKeepsUserEditsDuringExternalRefresh() {
        let userID = UUID(uuidString: "00000000-0000-0000-0000-000000000823")!
        let viewer = UserProfile(id: userID, handle: "michi", displayName: "みち")
        var state = PaymentSettingsEditingState()

        state.applyCurrentValues(
            settings: UserPaymentSettings(
                userID: userID,
                methods: [.paypay],
                otherNote: nil
            ),
            viewer: viewer,
            force: true
        )
        XCTAssertEqual(state.draft.methods, [.paypay])

        state.appendAccount(BankReceivingAccount(bankName: "ユーザー入力銀行"))
        state.applyCurrentValues(
            settings: UserPaymentSettings(
                userID: userID,
                methods: [.bankTransfer],
                bankName: "外部更新銀行"
            ),
            viewer: viewer
        )
        XCTAssertEqual(state.draft.accounts.first?.bankName, "ユーザー入力銀行")

        state.applyCurrentValues(
            settings: UserPaymentSettings(
                userID: userID,
                methods: [.bankTransfer],
                bankName: "外部更新銀行"
            ),
            viewer: viewer,
            force: true
        )
        XCTAssertEqual(state.draft.methods, [.bankTransfer])
        XCTAssertEqual(state.draft.accounts.first?.bankName, "外部更新銀行")
    }

    func testPaymentSettingsEditingStateValidatesBeforeSave() {
        let userID = UUID(uuidString: "00000000-0000-0000-0000-000000000824")!
        var state = PaymentSettingsEditingState()

        state.toggleMethod(.other)
        XCTAssertNil(state.settingsForSave(viewerID: userID))
        XCTAssertEqual(state.validationMessage, "その他を選ぶ場合は自由入力を入力してください")

        state.updateOtherNote("123456789")
        let settings = state.settingsForSave(viewerID: userID)
        XCTAssertEqual(settings?.methods, [.other])
        XCTAssertEqual(settings?.otherNote, "12345678")
        XCTAssertTrue(state.hasUserEditedDraft)

        state.markSaveSucceeded()
        XCTAssertFalse(state.hasUserEditedDraft)
    }

    func testPaymentSettingsEditingStateRequiresViewerBeforeSave() {
        var state = PaymentSettingsEditingState()

        state.toggleMethod(.paypay)

        XCTAssertNil(state.settingsForSave(viewerID: nil))
        XCTAssertEqual(state.validationMessage, "プロフィールを読み込めませんでした")
    }

    func testDefaultExchangeSettingsPreserveSelectedDateDetails() {
        let settings = HomeDefaultExchangeSettings(
            preference: .both,
            localPrefecture: "東京都",
            localDateKeys: ["2026-07-03"],
            localDateDetails: [
                "2026-07-03": HomeExchangeLocalDateDetail(prefecture: " 東京都 ", memo: " 会場付近 "),
                "2026-08-01": HomeExchangeLocalDateDetail(prefecture: "大阪府", memo: "未選択")
            ],
            mailShippingFee: .owner,
            mailShippingDays: .oneDay
        )

        XCTAssertEqual(settings.localDateDetails["2026-07-03"]?.prefecture, "東京都")
        XCTAssertEqual(settings.localDateDetails["2026-07-03"]?.memo, "会場付近")
        XCTAssertNil(settings.localDateDetails["2026-08-01"])
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

    func testLoginSecurityPasswordResetStatePrefillsAndValidatesEmail() {
        var state = LoginSecurityPasswordResetState()

        state.prefillEmailIfNeeded(" michi@example.com ")
        XCTAssertEqual(state.email, " michi@example.com ")
        XCTAssertEqual(state.normalizedEmail, "michi@example.com")
        XCTAssertNil(state.validationMessageForSubmission())

        state.email = "manual@example.com"
        state.prefillEmailIfNeeded("other@example.com")
        XCTAssertEqual(state.email, "manual@example.com")

        state.email = " "
        XCTAssertEqual(
            state.validationMessageForSubmission(),
            MegrumAuthInputValidator.passwordResetValidationMessage(email: "")
        )
        XCTAssertNotNil(state.inputErrorMessage)

        state.clearInputFeedback()
        XCTAssertNil(state.inputErrorMessage)
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

    func testAuthLegalConsentLinksPointToPublicWebPages() {
        XCTAssertEqual(AuthLegalLinkDestination.terms.absoluteString, "https://megrum.jp/terms")
        XCTAssertEqual(AuthLegalLinkDestination.privacy.absoluteString, "https://megrum.jp/privacy")
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

    func testAddressSettingsDraftStateBuildsTrimmedMailingAddress() {
        let userID = UUID(uuidString: "20000000-0000-0000-0000-000000000007")!
        var state = AddressSettingsDraftState()
        state.recipientName = "  みち  "
        state.postalCode = "〒150-0001"
        state.prefecture = " 東京都 "
        state.city = " 渋谷区 "
        state.line1 = " 神宮前1-1-1 "
        state.line2 = " "
        state.phoneNumber = " 090-0000-0000 "

        let address = state.mailingAddress(userID: userID)

        XCTAssertEqual(address.userID, userID)
        XCTAssertEqual(address.recipientName, "みち")
        XCTAssertEqual(address.postalCode, "1500001")
        XCTAssertEqual(address.prefecture, "東京都")
        XCTAssertEqual(address.city, "渋谷区")
        XCTAssertEqual(address.line1, "神宮前1-1-1")
        XCTAssertNil(address.line2)
        XCTAssertEqual(address.phoneNumber, "090-0000-0000")
    }

    func testAddressSettingsDraftStateAppliesAddressAndPostalCodeLookup() {
        var state = AddressSettingsDraftState()
        let savedAddress = MailingAddress(
            userID: UUID(uuidString: "20000000-0000-0000-0000-000000000008")!,
            recipientName: "みち",
            postalCode: "1000001",
            prefecture: "東京都",
            city: "千代田区",
            line1: "千代田1-1",
            line2: "本館",
            phoneNumber: "090"
        )

        state.apply(address: savedAddress)
        XCTAssertEqual(state.recipientName, "みち")
        XCTAssertEqual(state.lastAppliedPostalCode, "1000001")
        XCTAssertFalse(state.shouldLookupPostalCode("1000001"))
        XCTAssertTrue(state.shouldLookupPostalCode("1500001"))

        state.apply(
            postalCodeAddress: PostalCodeAddress(
                postalCode: "1500001",
                prefecture: "東京都",
                city: "渋谷区",
                town: "神宮前"
            )
        )

        XCTAssertEqual(state.prefecture, "東京都")
        XCTAssertEqual(state.city, "渋谷区")
        XCTAssertEqual(state.line1, "神宮前")
        XCTAssertEqual(state.lastAppliedPostalCode, "1500001")
    }

    func testAddressSettingsDraftStateNormalizesPostalCodeAndClearsInputError() {
        var state = AddressSettingsDraftState()
        state.postalCode = "150-0001"
        state.setValidationMessage("入力してください")

        let normalized = state.normalizePostalCodeInput("〒150-0001")
        state.clearInputError()

        XCTAssertEqual(normalized, "1500001")
        XCTAssertEqual(state.postalCode, "1500001")
        XCTAssertNil(state.inputErrorMessage)
    }

    private static func proposal(
        idSuffix: Int,
        senderID: UUID,
        receiverID: UUID,
        status: ProposalStatus
    ) -> TradeProposal {
        TradeProposal(
            id: UUID(uuidString: "20000000-0000-0000-0000-\(String(format: "%012d", idSuffix))")!,
            senderID: senderID,
            receiverID: receiverID,
            status: status,
            exchangeMethod: .hand,
            senderGoodsIDs: [],
            receiverGoodsIDs: []
        )
    }
}
