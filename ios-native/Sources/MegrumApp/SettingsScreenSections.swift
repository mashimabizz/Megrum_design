import SwiftUI

@MainActor
struct SettingsPrimarySection: View {
    @ObservedObject var appState: MegrumAppState
    var profileStatusText: String
    var notificationStatusText: String
    var pushNotificationStatusText: String
    var addressStatusText: String
    var subscriptionStatusText: String
    var onOpenNotificationDestination: (MegrumTab) -> Void
    var onOpenNotificationRouteIntent: (NotificationRouteIntent) -> Bool
    var onSetPushNotificationsEnabled: @MainActor @Sendable (Bool) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
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
                onToggle: onSetPushNotificationsEnabled
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
                SubscriptionSettingsScreen(appState: appState)
            } label: {
                SettingsMenuRowLabel(
                    title: "Premium会員",
                    subtitle: subscriptionStatusText,
                    systemImage: "sparkles.rectangle.stack"
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
    }
}

@MainActor
struct SettingsSupportAccountSection: View {
    @ObservedObject var appState: MegrumAppState
    var securityAuthState: MegrumAuthState
    var isSigningOut: Bool
    var accountSummary: SettingsAccountSummary
    var loginSecuritySummary: LoginSecuritySummary
    var onSignOut: () async -> Void

    var body: some View {
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
                    onSignOut: onSignOut
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
    }
}

@MainActor
struct SettingsDangerSection: View {
    var isSigningOut: Bool
    var onSignOut: () -> Void

    var body: some View {
        Section {
            SettingsSignOutButtonRow(
                isSigningOut: isSigningOut,
                onTap: onSignOut
            )
        }
    }
}
