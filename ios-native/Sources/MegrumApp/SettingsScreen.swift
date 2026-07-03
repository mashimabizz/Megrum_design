import MegrumCore
import MegrumDesign
import SwiftUI

@MainActor
struct SettingsScreen: View {
    @ObservedObject var appState: MegrumAppState
    var onOpenNotificationDestination: (MegrumTab) -> Void = { _ in }
    var onOpenNotificationRouteIntent: (NotificationRouteIntent) -> Bool = { _ in false }
    var onClose: (() -> Void)?
    var onAccountDeletionCompleted: () -> Void = {}
    var onSignOut: () async -> Void = {}
    @Environment(\.dismiss) private var dismiss
    @StateObject private var securityAuthState: MegrumAuthState
    @State private var presentationState = SettingsPresentationState()

    init(
        appState: MegrumAppState,
        onOpenNotificationDestination: @escaping (MegrumTab) -> Void = { _ in },
        onOpenNotificationRouteIntent: @escaping (NotificationRouteIntent) -> Bool = { _ in false },
        onClose: (() -> Void)? = nil,
        onAccountDeletionCompleted: @escaping () -> Void = {},
        securityAuthState: MegrumAuthState? = nil,
        onSignOut: @escaping () async -> Void = {}
    ) {
        self.appState = appState
        self.onOpenNotificationDestination = onOpenNotificationDestination
        self.onOpenNotificationRouteIntent = onOpenNotificationRouteIntent
        self.onClose = onClose
        self.onAccountDeletionCompleted = onAccountDeletionCompleted
        self.onSignOut = onSignOut
        _securityAuthState = StateObject(wrappedValue: securityAuthState ?? MegrumAuthStateFactory.makeDefault())
    }

    var body: some View {
        NavigationStack(path: $presentationState.navigationPath) {
            List {
                SettingsPrimarySection(
                    appState: appState,
                    profileStatusText: profileStatusText,
                    notificationStatusText: notificationStatusText,
                    pushNotificationStatusText: pushNotificationStatusText,
                    groomNotificationStatusText: groomNotificationStatusText,
                    chatroomNotificationStatusText: chatroomNotificationStatusText,
                    addressStatusText: addressStatusText,
                    subscriptionStatusText: subscriptionStatusText,
                    onOpenRoute: openRoute,
                    onSetPushNotificationsEnabled: setPushNotificationsEnabled,
                    onSetGroomActivityPushNotificationsEnabled: setGroomActivityPushNotificationsEnabled,
                    onSetChatroomActivityPushNotificationsEnabled: setChatroomActivityPushNotificationsEnabled
                )

                SettingsSupportAccountSection(
                    isSigningOut: presentationState.isSigningOut,
                    accountSummary: accountSummary,
                    loginSecuritySummary: loginSecuritySummary,
                    onOpenRoute: openRoute
                )

                SettingsDangerSection(
                    isSigningOut: presentationState.isSigningOut,
                    onSignOut: startSignOut,
                    onRequestAccountDeletion: {
                        openRoute(.accountDeletion)
                    }
                )
            }
            .navigationTitle("設定")
            .megrumInlineNavigationTitle()
            .navigationDestination(for: SettingsEssentialRoute.self) { route in
                destination(for: route)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        closeSettings()
                    }
                }
            }
        }
        .task {
            await loadInitialSettingsData()
        }
    }

    private var notificationStatusText: String {
        SettingsStatusTextResolver.notificationStatusText(
            hasNotifications: !appState.notifications.isEmpty,
            unreadCount: appState.unreadNotificationCount
        )
    }

    private var pushNotificationStatusText: String {
        SettingsStatusTextResolver.pushNotificationStatusText(isEnabled: appState.pushNotificationsEnabled)
    }

    private var groomNotificationStatusText: String {
        SettingsStatusTextResolver.groomNotificationStatusText(
            isEnabled: appState.groomActivityPushNotificationsEnabled
        )
    }

    private var chatroomNotificationStatusText: String {
        SettingsStatusTextResolver.chatroomNotificationStatusText(
            isEnabled: appState.chatroomActivityPushNotificationsEnabled
        )
    }

    private var profileStatusText: String {
        SettingsStatusTextResolver.profileStatusText(viewer: appState.viewer)
    }

    private var addressStatusText: String {
        SettingsStatusTextResolver.addressStatusText(address: appState.mailingAddress)
    }

    private var subscriptionStatusText: String {
        SettingsStatusTextResolver.subscriptionStatusText(isActive: appState.subscriptionState.isMegrumPlusActive)
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

    private func setGroomActivityPushNotificationsEnabled(_ enabled: Bool) {
        Task {
            await appState.setGroomActivityPushNotificationsEnabled(enabled)
        }
    }

    private func setChatroomActivityPushNotificationsEnabled(_ enabled: Bool) {
        Task {
            await appState.setChatroomActivityPushNotificationsEnabled(enabled)
        }
    }

    private func openRoute(_ route: SettingsEssentialRoute) {
        presentationState.openRoute(route)
    }

    @ViewBuilder
    private func destination(for route: SettingsEssentialRoute) -> some View {
        switch route {
        case .profile:
            OwnProfileScreen(appState: appState)
        case .notifications:
            NotificationCenterScreen(appState: appState) { tab in
                closeSettings()
                onOpenNotificationDestination(tab)
            } onOpenRouteIntent: { intent in
                if onOpenNotificationRouteIntent(intent) {
                    closeSettings()
                    return true
                }
                return false
            }
        case .mobilePush:
            EmptyView()
        case .address:
            AddressSettingsScreen(appState: appState)
        case .payment:
            PaymentSettingsScreen(appState: appState)
        case .premium:
            SubscriptionSettingsScreen(appState: appState)
        case .blockedUsers:
            BlockedUsersScreen(appState: appState, context: .exchange)
        case .meguriBlockedUsers:
            BlockedUsersScreen(appState: appState, context: .meguri)
        case .privacy:
            PrivacySettingsScreen(appState: appState)
        case .loginSecurity:
            LoginSecuritySettingsScreen(
                authState: securityAuthState,
                isSigningOut: presentationState.isSigningOut,
                accountSummary: accountSummary,
                onSignOut: {
                    await performSignOut(dismissSettings: true)
                }
            )
        case .help:
            SettingsHelpScreen()
        case .terms:
            LegalDocumentScreen(kind: .terms)
        case .privacyPolicy:
            LegalDocumentScreen(kind: .privacy)
        case .commerceDisclosure:
            LegalDocumentScreen(kind: .commerce)
        case .account:
            AccountOverviewScreen(appState: appState)
        case .accountDeletion:
            AccountDeletionScreen(appState: appState) {
                onAccountDeletionCompleted()
                closeSettings()
            }
        case .logout:
            EmptyView()
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
        await appState.loadSubscriptionState(reportsFailure: false)
    }

    private func performSignOut(dismissSettings: Bool) async {
        guard presentationState.beginSignOutIfNeeded() else {
            return
        }

        await onSignOut()
        presentationState.finishSignOut()

        if dismissSettings {
            closeSettings()
        }
    }

    private func closeSettings() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }
}
