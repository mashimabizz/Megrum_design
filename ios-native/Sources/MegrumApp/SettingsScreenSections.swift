import SwiftUI

@MainActor
struct SettingsPrimarySection: View {
    @ObservedObject var appState: MegrumAppState
    var profileStatusText: String
    var notificationStatusText: String
    var pushNotificationStatusText: String
    var addressStatusText: String
    var subscriptionStatusText: String
    var onOpenRoute: (SettingsEssentialRoute) -> Void
    var onSetPushNotificationsEnabled: @MainActor @Sendable (Bool) -> Void

    var body: some View {
        Section {
            SettingsNavigationButtonRow(
                title: "自分のプロフィール",
                subtitle: profileStatusText,
                systemImage: "person.crop.circle"
            ) {
                onOpenRoute(.profile)
            }

            SettingsNavigationButtonRow(
                title: "通知",
                subtitle: notificationStatusText,
                systemImage: "bell",
                badgeCount: appState.unreadNotificationCount
            ) {
                onOpenRoute(.notifications)
            }

            SettingsPushNotificationRow(
                statusText: pushNotificationStatusText,
                isEnabled: appState.pushNotificationsEnabled,
                isLoading: appState.isLoadingPushNotificationSetting,
                isSaving: appState.isSavingPushNotificationSetting,
                onToggle: onSetPushNotificationsEnabled
            )

            SettingsNavigationButtonRow(
                title: "住所設定",
                subtitle: addressStatusText,
                systemImage: "shippingbox"
            ) {
                onOpenRoute(.address)
            }

            SettingsNavigationButtonRow(
                title: "Premium会員",
                subtitle: subscriptionStatusText,
                systemImage: "sparkles.rectangle.stack"
            ) {
                onOpenRoute(.premium)
            }

            SettingsNavigationButtonRow(
                title: "ブロックした人",
                subtitle: "一覧と解除",
                systemImage: "person.crop.circle.badge.xmark"
            ) {
                onOpenRoute(.blockedUsers)
            }
        }
    }
}

@MainActor
struct SettingsSupportAccountSection: View {
    var isSigningOut: Bool
    var accountSummary: SettingsAccountSummary
    var loginSecuritySummary: LoginSecuritySummary
    var onOpenRoute: (SettingsEssentialRoute) -> Void

    var body: some View {
        Section {
            SettingsNavigationButtonRow(
                title: "ヘルプ",
                subtitle: "問い合わせと困った時の確認",
                systemImage: "questionmark.circle"
            ) {
                onOpenRoute(.help)
            }

            SettingsNavigationButtonRow(
                title: "プライバシーと安全",
                subtitle: "ブロック・公開範囲・ポリシー",
                systemImage: "lock.shield"
            ) {
                onOpenRoute(.privacy)
            }

            SettingsNavigationButtonRow(
                title: "ログインとセキュリティ",
                subtitle: loginSecuritySummary.shortStatusText,
                systemImage: "person.badge.key"
            ) {
                onOpenRoute(.loginSecurity)
            }

            SettingsNavigationButtonRow(
                title: "利用規約",
                subtitle: "公開前確認用の要約",
                systemImage: "doc.text"
            ) {
                onOpenRoute(.terms)
            }

            SettingsNavigationButtonRow(
                title: "プライバシーポリシー",
                subtitle: "取り扱う情報の要点",
                systemImage: "hand.raised"
            ) {
                onOpenRoute(.privacyPolicy)
            }

            SettingsNavigationButtonRow(
                title: "特定商取引法に基づく表記",
                subtitle: "有料機能と事業者表示の入口",
                systemImage: "building.columns"
            ) {
                onOpenRoute(.commerceDisclosure)
            }

            SettingsNavigationButtonRow(
                title: "アカウント",
                subtitle: accountSummary.shortStatusText,
                systemImage: "person.text.rectangle"
            ) {
                onOpenRoute(.account)
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
