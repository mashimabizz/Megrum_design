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
                    SettingsMenuRowLabel(
                        title: "自分のプロフィール",
                        subtitle: profileStatusText,
                        systemImage: "person.crop.circle"
                    )
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
                    SettingsMenuRowLabel(
                        title: "通知",
                        subtitle: notificationStatusText,
                        systemImage: "bell",
                        badgeCount: appState.unreadNotificationCount
                    )
                }

                SettingsPushNotificationRow(
                    statusText: pushNotificationStatusText,
                    isEnabled: appState.pushNotificationsEnabled,
                    isLoading: appState.isLoadingPushNotificationSetting,
                    isSaving: appState.isSavingPushNotificationSetting,
                    onToggle: setPushNotificationsEnabled
                )

                NavigationLink {
                    AddressSettingsScreen(appState: appState)
                } label: {
                    SettingsMenuRowLabel(
                        title: "住所設定",
                        subtitle: addressStatusText,
                        systemImage: "shippingbox"
                    )
                }

                NavigationLink {
                    PaymentSettingsScreen(appState: appState)
                } label: {
                    SettingsMenuRowLabel(
                        title: "支払い条件設定",
                        subtitle: paymentStatusText,
                        systemImage: "yensign.circle"
                    )
                }

                NavigationLink {
                    BlockedUsersScreen(appState: appState)
                } label: {
                    SettingsMenuRowLabel(
                        title: "ブロックした人",
                        subtitle: "一覧と解除",
                        systemImage: "person.crop.circle.badge.xmark"
                    )
                }
            }

            Section {
                NavigationLink {
                    SettingsHelpScreen()
                } label: {
                    SettingsMenuRowLabel(
                        title: "ヘルプ",
                        subtitle: "問い合わせと困った時の確認",
                        systemImage: "questionmark.circle"
                    )
                }

                NavigationLink {
                    PrivacySettingsScreen(appState: appState)
                } label: {
                    SettingsMenuRowLabel(
                        title: "プライバシーと安全",
                        subtitle: "ブロック・公開範囲・ポリシー",
                        systemImage: "lock.shield"
                    )
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
                    SettingsMenuRowLabel(
                        title: "ログインとセキュリティ",
                        subtitle: loginSecuritySummary.shortStatusText,
                        systemImage: "person.badge.key"
                    )
                }

                NavigationLink {
                    LegalDocumentScreen(kind: .terms)
                } label: {
                    SettingsMenuRowLabel(
                        title: "利用規約",
                        subtitle: "公開前確認用の要約",
                        systemImage: "doc.text"
                    )
                }

                NavigationLink {
                    LegalDocumentScreen(kind: .privacy)
                } label: {
                    SettingsMenuRowLabel(
                        title: "プライバシーポリシー",
                        subtitle: "取り扱う情報の要点",
                        systemImage: "hand.raised"
                    )
                }

                NavigationLink {
                    LegalDocumentScreen(kind: .commerce)
                } label: {
                    SettingsMenuRowLabel(
                        title: "特定商取引法に基づく表記",
                        subtitle: "有料機能と事業者表示の入口",
                        systemImage: "building.columns"
                    )
                }

                NavigationLink {
                    AccountOverviewScreen(appState: appState)
                } label: {
                    SettingsMenuRowLabel(
                        title: "アカウント",
                        subtitle: accountSummary.shortStatusText,
                        systemImage: "person.text.rectangle"
                    )
                }
            } header: {
                Text("サポートとアカウント")
            }

            Section {
                SettingsSignOutButtonRow(
                    isSigningOut: isSigningOut,
                    onTap: startSignOut
                )
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
            await loadInitialSettingsData()
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

    private var paymentStatusText: String {
        appState.viewer?.paymentSummaryText ?? "未設定"
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

    private func startSignOut() {
        Task {
            await performSignOut(dismissSettings: true)
        }
    }

    private func setPushNotificationsEnabled(_ enabled: Bool) {
        Task {
            await appState.setPushNotificationsEnabled(enabled)
        }
    }

    private func loadInitialSettingsData() async {
        if appState.mailingAddress == nil {
            await appState.loadMailingAddress()
        }
        if appState.notifications.isEmpty {
            await appState.loadNotifications()
        }
        await appState.loadPushNotificationSetting()
        if appState.paymentSettings == nil {
            await appState.loadPaymentSettings()
        }
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
