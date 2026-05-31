import MegrumCore
import MegrumDesign
import SwiftUI

@MainActor
struct SettingsScreen: View {
    @ObservedObject var appState: MegrumAppState
    var onOpenNotificationDestination: (MegrumTab) -> Void = { _ in }
    var onOpenNotificationRouteIntent: (NotificationRouteIntent) -> Bool = { _ in false }
    var onSignOut: () async -> Void = {}
    @Environment(\.dismiss) private var dismiss
    @StateObject private var securityAuthState: MegrumAuthState
    @State private var isSigningOut = false

    init(
        appState: MegrumAppState,
        onOpenNotificationDestination: @escaping (MegrumTab) -> Void = { _ in },
        onOpenNotificationRouteIntent: @escaping (NotificationRouteIntent) -> Bool = { _ in false },
        securityAuthState: MegrumAuthState? = nil,
        onSignOut: @escaping () async -> Void = {}
    ) {
        self.appState = appState
        self.onOpenNotificationDestination = onOpenNotificationDestination
        self.onOpenNotificationRouteIntent = onOpenNotificationRouteIntent
        self.onSignOut = onSignOut
        _securityAuthState = StateObject(wrappedValue: securityAuthState ?? MegrumAuthStateFactory.makeDefault())
    }

    var body: some View {
        List {
            Section {
                NavigationLink {
                    OwnProfileScreen(appState: appState)
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("自分のプロフィール")
                                .font(.body.weight(.semibold))
                            Text(profileStatusText)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(MegrumTheme.muted)
                        }
                    } icon: {
                        Image(systemName: "person.crop.circle")
                            .foregroundStyle(MegrumTheme.lavender)
                    }
                }

                NavigationLink {
                    NotificationCenterScreen(appState: appState) { tab in
                        dismiss()
                        onOpenNotificationDestination(tab)
                    } onOpenRouteIntent: { intent in
                        if onOpenNotificationRouteIntent(intent) {
                            dismiss()
                            return true
                        }
                        return false
                    }
                } label: {
                    Label {
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("通知")
                                    .font(.body.weight(.semibold))
                                Text(notificationStatusText)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(MegrumTheme.muted)
                            }

                            Spacer()

                            if appState.unreadNotificationCount > 0 {
                                Text("\(appState.unreadNotificationCount)")
                                    .font(.caption.weight(.black))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(MegrumTheme.pink, in: Capsule())
                            }
                        }
                    } icon: {
                        Image(systemName: "bell")
                            .foregroundStyle(MegrumTheme.lavender)
                    }
                }

                HStack(spacing: 12) {
                    Label {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("モバイル通知")
                                .font(.body.weight(.semibold))
                            Text(pushNotificationStatusText)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(MegrumTheme.muted)
                        }
                    } icon: {
                        Image(systemName: "iphone.radiowaves.left.and.right")
                            .foregroundStyle(MegrumTheme.lavender)
                    }

                    Spacer(minLength: 12)

                    if appState.isLoadingPushNotificationSetting {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Toggle(
                            "モバイル通知",
                            isOn: Binding(
                                get: { appState.pushNotificationsEnabled },
                                set: { enabled in
                                    Task {
                                        await appState.setPushNotificationsEnabled(enabled)
                                    }
                                }
                            )
                        )
                        .labelsHidden()
                        .disabled(appState.isSavingPushNotificationSetting)
                    }
                }

                NavigationLink {
                    AddressSettingsScreen(appState: appState)
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("住所設定")
                                .font(.body.weight(.semibold))
                            Text(addressStatusText)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(MegrumTheme.muted)
                        }
                    } icon: {
                        Image(systemName: "shippingbox")
                            .foregroundStyle(MegrumTheme.lavender)
                    }
                }

                NavigationLink {
                    BlockedUsersScreen(appState: appState)
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("ブロックした人")
                                .font(.body.weight(.semibold))
                            Text("一覧と解除")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(MegrumTheme.muted)
                        }
                    } icon: {
                        Image(systemName: "person.crop.circle.badge.xmark")
                            .foregroundStyle(MegrumTheme.lavender)
                    }
                }
            }

            Section {
                NavigationLink {
                    SettingsHelpScreen()
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("ヘルプ")
                                .font(.body.weight(.semibold))
                            Text("問い合わせと困った時の確認")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(MegrumTheme.muted)
                        }
                    } icon: {
                        Image(systemName: "questionmark.circle")
                            .foregroundStyle(MegrumTheme.lavender)
                    }
                }

                NavigationLink {
                    PrivacySettingsScreen(appState: appState)
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("プライバシーと安全")
                                .font(.body.weight(.semibold))
                            Text("ブロック・公開範囲・ポリシー")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(MegrumTheme.muted)
                        }
                    } icon: {
                        Image(systemName: "lock.shield")
                            .foregroundStyle(MegrumTheme.lavender)
                    }
                }

                NavigationLink {
                    LoginSecuritySettingsScreen(
                        authState: securityAuthState,
                        isSigningOut: isSigningOut,
                        accountSummary: accountSummary,
                        onSignOut: {
                            await performSignOut(dismissSettings: true)
                        }
                    )
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("ログインとセキュリティ")
                                .font(.body.weight(.semibold))
                            Text(loginSecuritySummary.shortStatusText)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(MegrumTheme.muted)
                        }
                    } icon: {
                        Image(systemName: "person.badge.key")
                            .foregroundStyle(MegrumTheme.lavender)
                    }
                }

                NavigationLink {
                    LegalDocumentScreen(kind: .terms)
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("利用規約")
                                .font(.body.weight(.semibold))
                            Text("公開前確認用の要約")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(MegrumTheme.muted)
                        }
                    } icon: {
                        Image(systemName: "doc.text")
                            .foregroundStyle(MegrumTheme.lavender)
                    }
                }

                NavigationLink {
                    LegalDocumentScreen(kind: .privacy)
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("プライバシーポリシー")
                                .font(.body.weight(.semibold))
                            Text("取り扱う情報の要点")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(MegrumTheme.muted)
                        }
                    } icon: {
                        Image(systemName: "hand.raised")
                            .foregroundStyle(MegrumTheme.lavender)
                    }
                }

                NavigationLink {
                    LegalDocumentScreen(kind: .commerce)
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("特定商取引法に基づく表記")
                                .font(.body.weight(.semibold))
                            Text("有料機能と事業者表示の入口")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(MegrumTheme.muted)
                        }
                    } icon: {
                        Image(systemName: "building.columns")
                            .foregroundStyle(MegrumTheme.lavender)
                    }
                }

                NavigationLink {
                    AccountOverviewScreen(appState: appState)
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("アカウント")
                                .font(.body.weight(.semibold))
                            Text(accountSummary.shortStatusText)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(MegrumTheme.muted)
                        }
                    } icon: {
                        Image(systemName: "person.text.rectangle")
                            .foregroundStyle(MegrumTheme.lavender)
                    }
                }
            } header: {
                Text("サポートとアカウント")
            }

            Section {
                Button(role: .destructive) {
                    Task {
                        await performSignOut(dismissSettings: true)
                    }
                } label: {
                    HStack {
                        Label("ログアウト", systemImage: "rectangle.portrait.and.arrow.right")
                        if isSigningOut {
                            Spacer()
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                }
                .disabled(isSigningOut)
            }
        }
        .navigationTitle("設定")
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
        .task {
            if appState.mailingAddress == nil {
                await appState.loadMailingAddress()
            }
            if appState.notifications.isEmpty {
                await appState.loadNotifications()
            }
            await appState.loadPushNotificationSetting()
        }
    }

    private var notificationStatusText: String {
        guard !appState.notifications.isEmpty else {
            return "未読なし"
        }
        if appState.unreadNotificationCount > 0 {
            return "未読 \(appState.unreadNotificationCount)件"
        }
        return "すべて既読"
    }

    private var pushNotificationStatusText: String {
        appState.pushNotificationsEnabled ? "端末に通知を届ける" : "端末通知はOFF"
    }

    private var profileStatusText: String {
        guard let viewer = appState.viewer else {
            return "未読み込み"
        }
        if let prefecture = viewer.prefecture, !prefecture.isEmpty {
            return "\(viewer.displayName) / \(prefecture)"
        }
        return viewer.displayName
    }

    private var addressStatusText: String {
        guard let address = appState.mailingAddress, address.isReady else {
            return "未登録"
        }
        return address.summary
    }

    private var accountSummary: SettingsAccountSummary {
        SettingsAccountSummary(
            viewer: appState.viewer,
            pushNotificationsEnabled: appState.pushNotificationsEnabled,
            mailingAddress: appState.mailingAddress
        )
    }

    private var loginSecuritySummary: LoginSecuritySummary {
        LoginSecuritySummary(
            authSession: securityAuthState.session,
            isAuthenticated: securityAuthState.isAuthenticated,
            isAuthConfigured: securityAuthState.isConfigured,
            accountSummary: accountSummary
        )
    }

    private func performSignOut(dismissSettings: Bool) async {
        guard !isSigningOut else {
            return
        }

        isSigningOut = true
        await onSignOut()
        isSigningOut = false

        if dismissSettings {
            dismiss()
        }
    }
}

struct SettingsAccountSummary: Equatable {
    var userIDText: String
    var handleText: String
    var displayNameText: String
    var activityAreaText: String
    var accountStatusText: String
    var pushNotificationText: String
    var addressStatusText: String

    init(
        viewer: UserProfile?,
        pushNotificationsEnabled: Bool,
        mailingAddress: MailingAddress?
    ) {
        userIDText = viewer?.id.uuidString.lowercased() ?? "未読み込み"
        handleText = Self.trimmed(viewer?.handle, fallback: "未設定")
        displayNameText = Self.trimmed(viewer?.displayName, fallback: "未設定")
        activityAreaText = Self.trimmed(viewer?.prefecture, fallback: "未設定")
        accountStatusText = viewer?.accountStatus.settingsDisplayName ?? "未読み込み"
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

    private static func trimmed(_ value: String?, fallback: String) -> String {
        let trimmedValue = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmedValue.isEmpty ? fallback : trimmedValue
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
        emailText = Self.trimmed(authSession?.user.email, fallback: "メール未取得")
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

    private static func trimmed(_ value: String?, fallback: String) -> String {
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

enum SettingsEssentialRoute: String, CaseIterable, Identifiable {
    case notifications
    case mobilePush
    case address
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

@MainActor
private struct LoginSecuritySettingsScreen: View {
    @ObservedObject var authState: MegrumAuthState
    var isSigningOut: Bool
    var accountSummary: SettingsAccountSummary
    var onSignOut: () async -> Void

    @FocusState private var focusedField: Field?
    @State private var resetEmail = ""
    @State private var resetInputErrorMessage: String?

    private var summary: LoginSecuritySummary {
        LoginSecuritySummary(
            authSession: authState.session,
            isAuthenticated: authState.isAuthenticated,
            isAuthConfigured: authState.isConfigured,
            accountSummary: accountSummary
        )
    }

    var body: some View {
        List {
            Section {
                SettingsValueRow(title: "認証状態", value: summary.authStatusText)
                SettingsValueRow(title: "ログインメール", value: summary.emailText)
                SettingsValueRow(title: "認証ユーザーID", value: summary.authUserIDText, isMonospaced: true)
                SettingsValueRow(title: "プロフィールID", value: summary.profileUserIDText, isMonospaced: true)
                SettingsValueRow(title: "接続状態", value: summary.authConfigurationText)
                SettingsValueRow(title: "アカウント状態", value: summary.accountStatusText)
            } header: {
                Text("現在の状態")
            }

            Section {
                resetEmailField

                Button {
                    Task { await sendPasswordReset() }
                } label: {
                    HStack(spacing: 8) {
                        if authState.isLoading {
                            ProgressView()
                                .controlSize(.small)
                        }
                        Text("再設定メールを送る")
                    }
                }
                .disabled(authState.isLoading)

                if let resetInputErrorMessage {
                    SecurityFeedbackRow(message: resetInputErrorMessage, style: .error)
                } else if let errorMessage = authState.errorMessage {
                    SecurityFeedbackRow(message: errorMessage, style: .error)
                } else if let successMessage = authState.passwordResetMessage ?? authState.successMessage {
                    SecurityFeedbackRow(message: successMessage, style: .success)
                }
            } header: {
                Text("パスワード再設定")
            } footer: {
                Text("メール/パスワードでログインしている場合は、登録メールへ再設定リンクを送れます。")
            }

            Section {
                Button(role: .destructive) {
                    Task {
                        focusedField = nil
                        await onSignOut()
                    }
                } label: {
                    HStack {
                        Label("ログアウト", systemImage: "rectangle.portrait.and.arrow.right")
                        if isSigningOut {
                            Spacer()
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                }
                .disabled(isSigningOut)
            } footer: {
                Text("ログアウトすると、この端末のセッションを外してログイン/新規登録画面に戻ります。")
            }
        }
        .navigationTitle("ログインとセキュリティ")
        .megrumInlineNavigationTitle()
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            #if os(iOS)
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("閉じる") {
                    focusedField = nil
                }
            }
            #endif
        }
        .onAppear {
            prefillResetEmailIfNeeded()
        }
        .onChange(of: authState.session?.user.email) { _, _ in
            prefillResetEmailIfNeeded()
        }
        .onChange(of: resetEmail) { _, _ in
            resetInputErrorMessage = nil
            authState.clearFeedback()
        }
    }

    @ViewBuilder
    private var resetEmailField: some View {
        #if os(iOS)
        TextField("ログインメール", text: $resetEmail)
            .focused($focusedField, equals: .resetEmail)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .keyboardType(.emailAddress)
            .textContentType(.emailAddress)
            .submitLabel(.send)
            .onSubmit {
                Task { await sendPasswordReset() }
            }
        #else
        TextField("ログインメール", text: $resetEmail)
            .focused($focusedField, equals: .resetEmail)
            .textContentType(.emailAddress)
            .onSubmit {
                Task { await sendPasswordReset() }
            }
        #endif
    }

    private func sendPasswordReset() async {
        focusedField = nil
        resetInputErrorMessage = nil
        let normalizedEmail = MegrumAuthInputValidator.normalizedEmail(resetEmail)
        if let validationMessage = MegrumAuthInputValidator.passwordResetValidationMessage(email: normalizedEmail) {
            authState.clearFeedback()
            resetInputErrorMessage = validationMessage
            return
        }

        _ = await authState.sendPasswordReset(email: normalizedEmail)
    }

    private func prefillResetEmailIfNeeded() {
        guard resetEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        resetEmail = summary.resetEmailPrefill
    }

    private enum Field {
        case resetEmail
    }
}

private struct SecurityFeedbackRow: View {
    enum Style {
        case error
        case success
    }

    var message: String
    var style: Style

    var body: some View {
        Text(message)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
            .accessibilityLabel(message)
    }

    private var foregroundColor: Color {
        switch style {
        case .error:
            Color(red: 0.851, green: 0.51, blue: 0.42)
        case .success:
            MegrumTheme.ok
        }
    }
}

@MainActor
private struct PrivacySettingsScreen: View {
    @ObservedObject var appState: MegrumAppState

    var body: some View {
        List {
            Section {
                NavigationLink {
                    BlockedUsersScreen(appState: appState)
                } label: {
                    HelpRouteRow(
                        iconName: "person.crop.circle.badge.xmark",
                        title: "ブロックした人",
                        message: "ブロック中の相手を確認し、必要に応じて解除できます。"
                    )
                }

                NavigationLink {
                    LegalDocumentScreen(kind: .privacy)
                } label: {
                    HelpRouteRow(
                        iconName: "hand.raised",
                        title: "プライバシーポリシー",
                        message: "Megrumが扱う情報と利用目的を確認できます。"
                    )
                }
            } header: {
                Text("安全管理")
            }

            Section {
                HelpRouteRow(
                    iconName: "location.circle",
                    title: "位置情報",
                    message: "グルームと掲示板は位置情報の許可状態に応じて表示範囲が変わります。端末の設定アプリから変更できます。"
                )
                HelpRouteRow(
                    iconName: "bell.badge",
                    title: "通知の表示",
                    message: "通知のON/OFFは設定一覧のモバイル通知から変更できます。"
                )
                HelpRouteRow(
                    iconName: "shippingbox",
                    title: "住所情報",
                    message: "住所は取引に必要な場面だけで扱います。住所設定から内容を確認できます。"
                )
            } header: {
                Text("共有される情報")
            }
        }
        .navigationTitle("プライバシーと安全")
        .megrumInlineNavigationTitle()
    }
}

private struct SettingsHelpScreen: View {
    private let supportEmail = "support@megrum.jp"

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("困った時は、状況が分かる内容を添えてお問い合わせください。")
                        .font(.body)
                        .foregroundStyle(MegrumTheme.ink)

                    Text(supportEmail)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(MegrumTheme.lavender)
                        .textSelection(.enabled)
                }
                .padding(.vertical, 4)
            } header: {
                Text("問い合わせ")
            }

            Section {
                HelpRouteRow(
                    iconName: "bell",
                    title: "通知",
                    message: "打診、取引チャット、評価、掲示板の更新を確認できます。届かない時はモバイル通知のON/OFFも見直してください。"
                )
                HelpRouteRow(
                    iconName: "shippingbox",
                    title: "住所設定",
                    message: "住所情報を登録・更新できます。取引で必要になる場面に備えて、内容が古くないか確認してください。"
                )
                HelpRouteRow(
                    iconName: "person.crop.circle.badge.xmark",
                    title: "ブロックした人",
                    message: "ブロック中の相手を確認し、必要に応じて解除できます。"
                )
                HelpRouteRow(
                    iconName: "rectangle.portrait.and.arrow.right",
                    title: "ログアウト",
                    message: "共有端末や機種変更前など、今の端末からMegrumのセッションを外したい時に使います。"
                )
            } header: {
                Text("よく使う設定")
            }

            Section {
                NavigationLink {
                    LegalDocumentScreen(kind: .terms)
                } label: {
                    HelpRouteRow(
                        iconName: "doc.text",
                        title: "利用規約",
                        message: "公開前レビュー後の正式本文へ差し替えるための入口です。"
                    )
                }
                NavigationLink {
                    LegalDocumentScreen(kind: .privacy)
                } label: {
                    HelpRouteRow(
                        iconName: "hand.raised",
                        title: "プライバシーポリシー",
                        message: "扱う情報と問い合わせ先を確認できます。"
                    )
                }
                NavigationLink {
                    LegalDocumentScreen(kind: .commerce)
                } label: {
                    HelpRouteRow(
                        iconName: "building.columns",
                        title: "特定商取引法に基づく表記",
                        message: "有料機能と事業者表示の確認入口です。"
                    )
                }
            } header: {
                Text("法的文書")
            }

            Section {
                Text("取引中の相手と連絡が取れない、待ち合わせに不安がある、相手の行動に問題を感じる場合は、取引チャットの内容や状況を整理してサポートへ連絡してください。")
                    .font(.body)
                    .foregroundStyle(MegrumTheme.ink)
                    .padding(.vertical, 4)
            } header: {
                Text("取引で困った時")
            }
        }
        .navigationTitle("ヘルプ")
        .megrumInlineNavigationTitle()
    }
}

private struct HelpRouteRow: View {
    var iconName: String
    var title: String
    var message: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(MegrumTheme.ink)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(MegrumTheme.muted)
            }
            .padding(.vertical, 3)
        } icon: {
            Image(systemName: iconName)
                .foregroundStyle(MegrumTheme.lavender)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityHint(message)
    }
}

private struct LegalDocumentScreen: View {
    var kind: LegalDocumentKind

    var body: some View {
        List {
            Section {
                Text(kind.statusMessage)
                    .font(.body)
                    .foregroundStyle(MegrumTheme.ink)
                    .padding(.vertical, 4)
            } header: {
                Text("ステータス")
            }

            Section {
                ForEach(kind.summaryItems) { item in
                    LegalSummaryRow(item: item)
                }
            } header: {
                Text("主要項目")
            }

            Section {
                Text("support@megrum.jp")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(MegrumTheme.lavender)
                    .textSelection(.enabled)
            } header: {
                Text("問い合わせ先")
            }
        }
        .navigationTitle(kind.title)
        .megrumInlineNavigationTitle()
    }
}

enum LegalDocumentKind {
    case terms
    case privacy
    case commerce

    var title: String {
        switch self {
        case .terms:
            "利用規約"
        case .privacy:
            "プライバシーポリシー"
        case .commerce:
            "特定商取引法に基づく表記"
        }
    }

    var statusMessage: String {
        "この画面は正式な法的本文ではありません。公開前レビュー後の原文へ差し替えるための入口として、確認に必要な要点だけを表示しています。"
    }

    var summaryItems: [LegalSummaryItem] {
        switch self {
        case .terms:
            [
                LegalSummaryItem(
                    title: "Megrumの目的",
                    body: "推し活グッズの取引を、打診、取引チャット、待ち合わせ、評価まで一連の流れで支援します。"
                ),
                LegalSummaryItem(
                    title: "ユーザーの責任",
                    body: "登録内容、在庫情報、wish、取引相手とのやりとりは、正確で相手に誤解を与えない内容にしてください。"
                ),
                LegalSummaryItem(
                    title: "禁止事項",
                    body: "チケット転売、盗品や権利侵害品の取引、相手への迷惑行為、アプリ外での不適切な誘導は禁止です。"
                ),
                LegalSummaryItem(
                    title: "取引と安全",
                    body: "合意した内容を守り、待ち合わせや取引チャットの情報は当該取引の目的にだけ使います。"
                ),
                LegalSummaryItem(
                    title: "運営の対応",
                    body: "通報や異議申し立てを確認し、必要に応じて表示制限、アカウント制限、証跡確認を行います。"
                )
            ]
        case .privacy:
            [
                LegalSummaryItem(
                    title: "取得する情報",
                    body: "アカウント、プロフィール、推し、在庫情報、wish、打診、取引チャット、住所情報、位置情報、通知設定などを扱います。"
                ),
                LegalSummaryItem(
                    title: "利用目的",
                    body: "アカウント管理、取引の成立と安全な進行、通知、問い合わせ対応、不正利用の防止、サービス改善に利用します。"
                ),
                LegalSummaryItem(
                    title: "相手への表示",
                    body: "取引に必要なプロフィール、在庫情報、wish、待ち合わせ情報、任意共有した服装写真や現在地を、必要な範囲で表示します。"
                ),
                LegalSummaryItem(
                    title: "保存と削除",
                    body: "取引の安全確認、異議申し立て、法令対応に必要な範囲で保存し、不要になった情報は削除または非表示化します。"
                ),
                LegalSummaryItem(
                    title: "外部サービス",
                    body: "認証、通知、決済、分析、問い合わせ対応などで外部サービスを使う場合があります。"
                )
            ]
        case .commerce:
            [
                LegalSummaryItem(
                    title: "表示方針",
                    body: "代表者名・住所・電話番号は、請求があれば遅滞なく開示する方針です。"
                ),
                LegalSummaryItem(
                    title: "有料機能",
                    body: "Premium、めぐりPlus、ブーストなどの価格と提供条件は、公開前レビュー済みの本文に合わせて表示します。"
                ),
                LegalSummaryItem(
                    title: "問い合わせ先",
                    body: "問い合わせは support@megrum.jp で受け付けます。"
                )
            ]
        }
    }
}

struct LegalSummaryItem: Identifiable, Equatable {
    var title: String
    var body: String

    var id: String { title }
}

private struct LegalSummaryRow: View {
    var item: LegalSummaryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(item.title)
                .font(.body.weight(.semibold))
                .foregroundStyle(MegrumTheme.ink)
            Text(item.body)
                .font(.subheadline)
                .foregroundStyle(MegrumTheme.muted)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(item.title)
        .accessibilityHint(item.body)
    }
}

@MainActor
private struct AccountOverviewScreen: View {
    @ObservedObject var appState: MegrumAppState

    private var summary: SettingsAccountSummary {
        SettingsAccountSummary(
            viewer: appState.viewer,
            pushNotificationsEnabled: appState.pushNotificationsEnabled,
            mailingAddress: appState.mailingAddress
        )
    }

    var body: some View {
        List {
            Section {
                SettingsValueRow(title: "アカウントID", value: summary.userIDText, isMonospaced: true)
                SettingsValueRow(title: "ユーザーID", value: summary.handleText)
                SettingsValueRow(title: "表示名", value: summary.displayNameText)
                SettingsValueRow(title: "活動エリア", value: summary.activityAreaText)
                SettingsValueRow(title: "アカウント状態", value: summary.accountStatusText)
            } header: {
                Text("基本情報")
            }

            Section {
                SettingsValueRow(title: "モバイル通知", value: summary.pushNotificationText)
                SettingsValueRow(title: "住所登録", value: summary.addressStatusText)
            } header: {
                Text("設定状態")
            }
        }
        .navigationTitle("アカウント")
        .megrumInlineNavigationTitle()
        .task {
            if appState.mailingAddress == nil {
                await appState.loadMailingAddress()
            }
            await appState.loadPushNotificationSetting()
        }
    }
}

private struct SettingsValueRow: View {
    var title: String
    var value: String
    var isMonospaced = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(MegrumTheme.muted)
            Text(value)
                .font(isMonospaced ? .body.monospaced() : .body)
                .foregroundStyle(MegrumTheme.ink)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title)、\(value)")
    }
}

private struct MeguriMessagePeerRoute: Identifiable, Hashable {
    var peerID: UUID

    var id: UUID { peerID }
}

@MainActor
private struct NotificationsScreen: View {
    @ObservedObject var appState: MegrumAppState
    var onOpenDestination: (MegrumTab) -> Void
    @State private var filter: NotificationFilter = .all
    @State private var selectedMeguriPeer: MeguriMessagePeerRoute?

    var body: some View {
        List {
            Section {
                Picker("表示", selection: $filter) {
                    ForEach(NotificationFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
            }

            Section {
                if appState.isLoadingNotifications {
                    HStack(spacing: 10) {
                        ProgressView()
                            .controlSize(.small)
                        Text("通知を読み込んでいます")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(MegrumTheme.muted)
                    }
                } else if visibleNotifications.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(emptyTitle)
                            .font(.headline.weight(.bold))
                        Text("打診、取引チャット、掲示板の更新がここにまとまります。")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(MegrumTheme.muted)
                    }
                    .padding(.vertical, 8)
                } else {
                    ForEach(visibleNotifications) { notification in
                        NotificationRow(notification: notification) {
                            Task {
                                await appState.markNotificationRead(notification.id)
                                if let peerID = notification.meguriMessagePeerID {
                                    selectedMeguriPeer = MeguriMessagePeerRoute(peerID: peerID)
                                } else if let destination = MegrumTab(notificationLinkPath: notification.linkPath) {
                                    onOpenDestination(destination)
                                }
                            }
                        }
                    }
                }
            } header: {
                Text("\(visibleNotifications.count)件")
            }
        }
        .navigationTitle("通知")
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if appState.unreadNotificationCount > 0 {
                    Button("すべて既読") {
                        Task {
                            await appState.markAllNotificationsRead()
                        }
                    }
                    .disabled(appState.isMarkingNotificationsRead)
                }
            }
        }
        .task {
            await appState.loadNotifications()
        }
        .refreshable {
            await appState.loadNotifications()
        }
        .navigationDestination(item: $selectedMeguriPeer) { route in
            MeguriMessagesScreen(appState: appState, peerID: route.peerID)
        }
    }

    private var visibleNotifications: [MegrumNotification] {
        switch filter {
        case .all:
            appState.notifications
        case .unread:
            appState.notifications.filter(\.isUnread)
        case .trades:
            appState.notifications.filter { $0.kind.isTradeRelated }
        }
    }

    private var emptyTitle: String {
        switch filter {
        case .all:
            "まだ通知はありません"
        case .unread:
            "未読の通知はありません"
        case .trades:
            "取引の通知はありません"
        }
    }
}

@MainActor
private struct MeguriMessagesScreen: View {
    @ObservedObject var appState: MegrumAppState
    var peerID: UUID
    @State private var draft = ""

    private var messages: [MeguriMessage] {
        appState.meguriMessages(with: peerID)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if appState.isLoadingMeguriMessages {
                            HStack(spacing: 10) {
                                ProgressView()
                                    .controlSize(.small)
                                Text("読み込んでいます")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(MegrumTheme.muted)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 12)
                        } else if messages.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("まだメッセージはありません")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(MegrumTheme.ink)
                                Text("グルームへの返信から、そのまま会話を始められます。")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(MegrumTheme.muted)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 12)
                        } else {
                            ForEach(messages) { message in
                                MeguriMessageBubble(
                                    message: message,
                                    isMine: message.senderID == appState.viewer?.id
                                )
                                .id(message.id)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 18)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: messages.count) { _, _ in
                    guard let lastID = messages.last?.id else {
                        return
                    }
                    withAnimation(.snappy(duration: 0.24)) {
                        proxy.scrollTo(lastID, anchor: .bottom)
                    }
                }
            }

            MeguriMessageInput(
                text: $draft,
                isSending: appState.sendingMeguriMessageRecipientID == peerID
            ) {
                Task {
                    let sent = await appState.sendMeguriMessage(recipientID: peerID, body: draft)
                    if sent {
                        draft = ""
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .navigationTitle(peerTitle)
        .megrumInlineNavigationTitle()
        .task {
            await appState.loadMeguriMessages()
            await appState.markMeguriMessagesRead(peerID: peerID)
        }
    }

    private var peerTitle: String {
        for message in messages {
            if message.senderID == peerID {
                return displayName(name: message.senderDisplayName, handle: message.senderHandle)
            }
            if message.recipientID == peerID {
                return displayName(name: message.recipientDisplayName, handle: message.recipientHandle)
            }
        }
        return "めぐりメッセージ"
    }

    private func displayName(name: String?, handle: String?) -> String {
        if let name, !name.isEmpty {
            return name
        }
        if let handle, !handle.isEmpty {
            return "@\(handle)"
        }
        return "めぐりメッセージ"
    }
}

private struct MeguriMessageBubble: View {
    var message: MeguriMessage
    var isMine: Bool

    var body: some View {
        VStack(alignment: isMine ? .trailing : .leading, spacing: 4) {
            Text(messageText)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(isMine ? .white : MegrumTheme.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    isMine ? AnyShapeStyle(MegrumTheme.lavender) : AnyShapeStyle(.white.opacity(0.9)),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )

            Text(message.createdAt.formatted(date: .omitted, time: .shortened))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: isMine ? .trailing : .leading)
    }

    private var messageText: String {
        if message.locked {
            return "このメッセージは現在表示できません"
        }
        if let body = message.body, !body.isEmpty {
            return body
        }
        return message.messageType == .image ? "画像" : ""
    }
}

private struct MeguriMessageInput: View {
    @Binding var text: String
    var isSending: Bool
    var onSend: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            TextField("メッセージ", text: $text, axis: .vertical)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .lineLimit(1...4)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            Button(action: onSend) {
                Group {
                    if isSending {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 17, weight: .heavy))
                    }
                }
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(MegrumTheme.lavender, in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
            .opacity(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
            .accessibilityLabel("送信")
        }
    }
}

private enum NotificationFilter: String, CaseIterable, Identifiable {
    case all
    case unread
    case trades

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            "すべて"
        case .unread:
            "未読"
        case .trades:
            "取引"
        }
    }
}

private struct NotificationRow: View {
    var notification: MegrumNotification
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: notification.kind.symbolName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(notification.kind.tint)
                    .frame(width: 42, height: 42)
                    .background(notification.kind.tint.opacity(0.14), in: Circle())

                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(notification.title)
                            .font(.headline.weight(notification.isUnread ? .black : .bold))
                            .foregroundStyle(MegrumTheme.ink)
                            .lineLimit(2)

                        Spacer(minLength: 8)

                        Text(relativeTimeText)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(MegrumTheme.muted)
                    }

                    if let body = notification.body, !body.isEmpty {
                        Text(body)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(MegrumTheme.muted)
                            .lineLimit(3)
                    }
                }

                if notification.isUnread {
                    Circle()
                        .fill(MegrumTheme.pink)
                        .frame(width: 9, height: 9)
                        .padding(.top, 7)
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(notification.title)
    }

    private var relativeTimeText: String {
        let seconds = max(0, Int(Date().timeIntervalSince(notification.createdAt)))
        let minutes = seconds / 60
        if minutes < 1 {
            return "今"
        }
        if minutes < 60 {
            return "\(minutes)分前"
        }
        let hours = minutes / 60
        if hours < 24 {
            return "\(hours)時間前"
        }
        let days = hours / 24
        if days < 7 {
            return "\(days)日前"
        }
        return notification.createdAt.formatted(.dateTime.month().day())
    }
}

private extension MegrumNotificationKind {
    var symbolName: String {
        switch self {
        case .proposalReceived:
            "envelope.badge"
        case .proposalAccepted, .tradeCompleted:
            "checkmark.circle"
        case .proposalRejected:
            "xmark.circle"
        case .proposalRevised:
            "pencil.circle"
        case .evidenceAdded:
            "camera"
        case .evaluationReceived:
            "star"
        case .disputeReceived, .disputeResponded, .disputeClosed, .cancelRequested:
            "exclamationmark.triangle"
        case .expiresSoon:
            "clock"
        case .groomReply, .meguriMessage:
            "message"
        case .meguriBoardReply, .meguriBoardMention:
            "text.bubble"
        case .unknown:
            "bell"
        }
    }

    var tint: Color {
        switch self {
        case .proposalAccepted, .tradeCompleted:
            Color.green
        case .proposalRejected, .disputeReceived, .disputeResponded, .disputeClosed, .cancelRequested:
            Color.orange
        case .evaluationReceived, .meguriBoardMention, .expiresSoon:
            MegrumTheme.pink
        default:
            MegrumTheme.lavender
        }
    }

    var isTradeRelated: Bool {
        switch self {
        case .proposalReceived, .proposalAccepted, .proposalRejected, .proposalRevised,
             .evidenceAdded, .tradeCompleted, .evaluationReceived, .disputeReceived,
             .disputeResponded, .disputeClosed, .cancelRequested, .expiresSoon:
            true
        case .groomReply, .meguriMessage, .meguriBoardReply, .meguriBoardMention, .unknown:
            false
        }
    }
}

public extension MegrumTab {
    init?(notificationLinkPath: String?) {
        guard let linkPath = notificationLinkPath?.lowercased(), !linkPath.isEmpty else {
            return nil
        }
        if linkPath.contains("meguri") || linkPath.contains("groom") {
            self = .meguri
        } else if linkPath.contains("proposal")
            || linkPath.contains("trade")
            || linkPath.contains("deal")
            || linkPath.contains("dispute") {
            self = .trades
        } else if linkPath.contains("inventory") || linkPath.contains("goods") {
            self = .inventory
        } else if linkPath.contains("wish") {
            self = .wish
        } else {
            self = .home
        }
    }
}

private extension MegrumNotification {
    var meguriMessagePeerID: UUID? {
        guard kind == .groomReply || kind == .meguriMessage else {
            return nil
        }
        guard let linkPath, !linkPath.isEmpty else {
            return nil
        }

        if let components = URLComponents(string: linkPath) {
            for item in components.queryItems ?? [] {
                let key = item.name.lowercased()
                if (key == "userid" || key == "user_id" || key == "peerid" || key == "peer_id"),
                   let value = item.value,
                   let id = UUID(uuidString: value) {
                    return id
                }
            }
        }

        let separators = CharacterSet(charactersIn: "/?&=#")
        return linkPath
            .components(separatedBy: separators)
            .compactMap { UUID(uuidString: $0) }
            .first
    }
}

@MainActor
struct BlockedUsersScreen: View {
    @ObservedObject var appState: MegrumAppState
    @State private var userPendingUnblock: BlockedUser?
    @State private var isShowingUnblockDialog = false

    var body: some View {
        List {
            Section {
                if appState.isLoadingBlockedUsers {
                    HStack(spacing: 10) {
                        ProgressView()
                            .controlSize(.small)
                        Text("読み込んでいます")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(MegrumTheme.muted)
                    }
                } else if appState.blockedUsers.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ブロック中のユーザーはいません")
                            .font(.headline.weight(.bold))
                        Text("必要になった時は、プロフィールや掲示板のメニューから追加できます。")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(MegrumTheme.muted)
                    }
                    .padding(.vertical, 8)
                } else {
                    ForEach(appState.blockedUsers) { user in
                        BlockedUserRow(
                            user: user,
                            isUnblocking: appState.unblockingUserID == user.userID,
                            onUnblock: {
                                userPendingUnblock = user
                                isShowingUnblockDialog = true
                            }
                        )
                    }
                }
            } header: {
                Text("\(appState.blockedUsers.count)人")
            }
        }
        .navigationTitle("ブロックした人")
        .megrumInlineNavigationTitle()
        .task {
            await appState.loadBlockedUsers()
        }
        .refreshable {
            await appState.loadBlockedUsers()
        }
        .confirmationDialog("ブロックを解除しますか？", isPresented: $isShowingUnblockDialog, titleVisibility: .visible) {
            if let user = userPendingUnblock {
                Button("解除", role: .destructive) {
                    Task {
                        _ = await appState.unblockUser(user.userID)
                        userPendingUnblock = nil
                    }
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            if let user = userPendingUnblock {
                Text("\(user.displayName)さんをブロックした人から外します。")
            }
        }
    }
}

private struct BlockedUserRow: View {
    var user: BlockedUser
    var isUnblocking: Bool
    var onUnblock: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            avatar

            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(MegrumTheme.ink)
                Text("@\(user.handle)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MegrumTheme.muted)
                Text(blockedAtText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MegrumTheme.muted.opacity(0.85))
            }

            Spacer(minLength: 8)

            Button {
                onUnblock()
            } label: {
                if isUnblocking {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text("解除")
                        .font(.subheadline.weight(.bold))
                }
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            .disabled(isUnblocking)
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var avatar: some View {
        if let avatarURL = user.avatarURL {
            AsyncImage(url: avatarURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                avatarPlaceholder
            }
            .frame(width: 46, height: 46)
            .clipShape(Circle())
        } else {
            avatarPlaceholder
        }
    }

    private var avatarPlaceholder: some View {
        Circle()
            .fill(MegrumTheme.lavender.opacity(0.18))
            .frame(width: 46, height: 46)
            .overlay {
                Text(String(user.displayName.prefix(1)))
                    .font(.headline.weight(.black))
                    .foregroundStyle(MegrumTheme.lavender)
            }
    }

    private var blockedAtText: String {
        guard let blockedAt = user.blockedAt else {
            return "ブロック中"
        }
        return blockedAt.formatted(.dateTime.month().day()) + "からブロック中"
    }
}

@MainActor
struct AddressSettingsScreen: View {
    @ObservedObject var appState: MegrumAppState
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?

    @State private var recipientName = ""
    @State private var postalCode = ""
    @State private var prefecture = ""
    @State private var city = ""
    @State private var line1 = ""
    @State private var line2 = ""
    @State private var phoneNumber = ""
    @State private var postalCodeLookupTask: Task<Void, Never>?
    @State private var lastAppliedPostalCode = ""
    @State private var inputErrorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                form
                saveButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 36)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("住所設定")
        .megrumInlineNavigationTitle()
        .toolbar {
            #if os(iOS)
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完了") {
                    focusedField = nil
                }
                .font(.body.weight(.semibold))
            }
            #endif
        }
        .task {
            await appState.loadMailingAddress()
            apply(address: appState.mailingAddress)
        }
        .onDisappear {
            postalCodeLookupTask?.cancel()
        }
        .onChange(of: appState.mailingAddress) { _, address in
            apply(address: address)
        }
        .onChange(of: draftAddress) { _, _ in
            inputErrorMessage = nil
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("住所設定")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
            Text("取引で必要になる住所を、本人だけが編集できます")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
    }

    private var form: some View {
        VStack(spacing: 12) {
            TextField("宛名", text: $recipientName)
                .focused($focusedField, equals: .recipientName)
                .textContentType(.name)
                .submitLabel(.next)
                .onSubmit { focusedField = .postalCode }
                .megrumTextFieldStyle()

            HStack(spacing: 10) {
                TextField("郵便番号（ハイフンなし）", text: $postalCode)
                    .focused($focusedField, equals: .postalCode)
                    .textContentType(.postalCode)
                    #if os(iOS)
                    .keyboardType(.numberPad)
                    #endif
                    .onChange(of: postalCode) { _, value in
                        let normalized = normalizedPostalCode(value)
                        if normalized != value {
                            postalCode = normalized
                        }
                        schedulePostalCodeLookup(normalized)
                    }

                if appState.isLookingUpPostalCode {
                    ProgressView()
                        .controlSize(.small)
                }
            }
                .megrumTextFieldStyle()

            TextField("都道府県", text: $prefecture)
                .focused($focusedField, equals: .prefecture)
                .textContentType(.addressState)
                .submitLabel(.next)
                .onSubmit { focusedField = .city }
                .megrumTextFieldStyle()

            TextField("市区町村", text: $city)
                .focused($focusedField, equals: .city)
                .textContentType(.addressCity)
                .submitLabel(.next)
                .onSubmit { focusedField = .line1 }
                .megrumTextFieldStyle()

            TextField("番地・建物名", text: $line1)
                .focused($focusedField, equals: .line1)
                .textContentType(.streetAddressLine1)
                .submitLabel(.next)
                .onSubmit { focusedField = .line2 }
                .megrumTextFieldStyle()

            TextField("補足住所（任意）", text: $line2)
                .focused($focusedField, equals: .line2)
                .textContentType(.streetAddressLine2)
                .submitLabel(.next)
                .onSubmit { focusedField = .phoneNumber }
                .megrumTextFieldStyle()

            TextField("電話番号（任意）", text: $phoneNumber)
                .focused($focusedField, equals: .phoneNumber)
                .textContentType(.telephoneNumber)
                #if os(iOS)
                .keyboardType(.phonePad)
                #endif
                .megrumTextFieldStyle()

            if let inputErrorMessage {
                Text(inputErrorMessage)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.851, green: 0.51, blue: 0.42))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color(red: 0.851, green: 0.51, blue: 0.42).opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
                    .accessibilityLabel(inputErrorMessage)
            } else if let errorMessage = appState.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.851, green: 0.51, blue: 0.42))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color(red: 0.851, green: 0.51, blue: 0.42).opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private var saveButton: some View {
        Button {
            Task { await save() }
        } label: {
            HStack(spacing: 10) {
                if appState.isSavingMailingAddress {
                    ProgressView()
                        .controlSize(.small)
                }
                Text("保存する")
                    .font(.system(size: 16, weight: .black, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.roundedRectangle(radius: 18))
        .tint(MegrumTheme.lavender)
        .disabled(appState.isSavingMailingAddress)
        .accessibilityHint("入力した住所を保存します")
    }

    private var draftAddress: MailingAddress {
        MailingAddress(
            userID: appState.viewer?.id ?? NativePreviewData.viewerID,
            recipientName: recipientName.trimmingCharacters(in: .whitespacesAndNewlines),
            postalCode: normalizedPostalCode(postalCode),
            prefecture: prefecture.trimmingCharacters(in: .whitespacesAndNewlines),
            city: city.trimmingCharacters(in: .whitespacesAndNewlines),
            line1: line1.trimmingCharacters(in: .whitespacesAndNewlines),
            line2: line2.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank,
            phoneNumber: phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank
        )
    }

    private func save() async {
        focusedField = nil
        inputErrorMessage = MailingAddressDraftValidator.validationMessage(for: draftAddress)
        guard inputErrorMessage == nil else {
            return
        }

        if await appState.saveMailingAddress(draftAddress) {
            inputErrorMessage = nil
            dismiss()
        }
    }

    private func apply(address: MailingAddress?) {
        guard let address else {
            return
        }
        recipientName = address.recipientName
        postalCode = address.postalCode
        prefecture = address.prefecture
        city = address.city
        line1 = address.line1
        line2 = address.line2 ?? ""
        phoneNumber = address.phoneNumber ?? ""
        lastAppliedPostalCode = address.postalCode
    }

    private func normalizedPostalCode(_ value: String) -> String {
        String(value.filter(\.isNumber).prefix(7))
    }

    private func schedulePostalCodeLookup(_ value: String) {
        postalCodeLookupTask?.cancel()
        guard value.count == 7, value != lastAppliedPostalCode else {
            return
        }

        postalCodeLookupTask = Task { [value] in
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard !Task.isCancelled else {
                return
            }
            guard let address = await appState.lookupPostalCode(value) else {
                return
            }
            guard !Task.isCancelled else {
                return
            }
            prefecture = address.prefecture
            city = address.city
            line1 = address.line1Suggestion
            lastAppliedPostalCode = address.postalCode
        }
    }

    private enum Field {
        case recipientName
        case postalCode
        case prefecture
        case city
        case line1
        case line2
        case phoneNumber
    }
}

private extension String {
    var nilIfBlank: String? {
        isEmpty ? nil : self
    }
}
