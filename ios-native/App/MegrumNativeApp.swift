import MegrumApp
import OSLog
import SwiftUI
#if os(iOS)
import UIKit
@preconcurrency import UserNotifications
#endif
#if os(iOS) && canImport(GoogleMobileAds)
@preconcurrency import GoogleMobileAds
#endif

@main
struct MegrumNativeApp: App {
    @StateObject private var appState = MegrumAppStateFactory.makeDefault()
    @StateObject private var authState = MegrumAuthStateFactory.makeDefault()
    #if os(iOS)
    @UIApplicationDelegateAdaptor(NativePushAppDelegate.self) private var appDelegate
    @State private var didRequestNativePushAuthorization = false
    @State private var pendingNativePushToken: String?
    @State private var notificationDestinationTab: MegrumTab?
    @State private var notificationRouteLinkPath: String?
    @State private var notificationRouteKindRawValue: String?
    #endif

    init() {
        MegrumRemoteImageCache.configure()
        Self.startGoogleMobileAdsIfAvailable()
    }

    var body: some Scene {
        WindowGroup {
            MegrumRootView(
                appState: appState,
                authState: authState,
                notificationDestinationTab: $notificationDestinationTab,
                notificationRouteLinkPath: $notificationRouteLinkPath,
                notificationRouteKindRawValue: $notificationRouteKindRawValue
            )
            #if os(iOS)
            .task {
                await requestNativePushAuthorizationIfReady()
            }
            #if DEBUG
            .task {
                await Self.dumpViewHierarchyForDebuggingIfRequested()
            }
            .task {
                await Self.performDebugAutoSignInIfRequested(authState: authState)
            }
            #endif
            .onChange(of: authState.session?.accessToken) { _, _ in
                Task {
                    await requestNativePushAuthorizationIfReady()
                    await registerPendingNativePushToken()
                }
            }
            .onChange(of: appState.viewer?.id) { _, _ in
                Task {
                    await registerPendingNativePushToken()
                }
            }
            .onChange(of: appState.isTutorialActive) { _, isActive in
                // ツアー終了後に、抑制していた通知許可を改めて要求する。
                guard !isActive else { return }
                Task {
                    await requestNativePushAuthorizationIfReady()
                }
            }
            .onChange(of: appState.appIconBadgeCount, initial: true) { _, unreadCount in
                Task {
                    do {
                        try await UNUserNotificationCenter.current().setBadgeCount(unreadCount)
                        #if DEBUG
                        print("MEGRUM_DEBUG_BADGE set to \(unreadCount)")
                        #endif
                    } catch {
                        #if DEBUG
                        print("MEGRUM_DEBUG_BADGE error: \(error) (count=\(unreadCount))")
                        #endif
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .megrumNativeAPNsTokenDidUpdate)) { notification in
                guard let token = notification.userInfo?[NativePushAppDelegate.deviceTokenUserInfoKey] as? String else {
                    return
                }
                pendingNativePushToken = token
                Task {
                    await registerPendingNativePushToken()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .megrumNativeNotificationResponseDidReceive)) { notification in
                let linkPath = notification.userInfo?[NativePushAppDelegate.linkPathUserInfoKey] as? String
                if let linkPath {
                    notificationRouteKindRawValue = notification.userInfo?[NativePushAppDelegate.notificationKindUserInfoKey] as? String
                    notificationRouteLinkPath = linkPath
                } else {
                    notificationDestinationTab = .home
                }

                guard
                    let notificationIDString = notification.userInfo?[NativePushAppDelegate.notificationIDUserInfoKey] as? String,
                    let notificationID = UUID(uuidString: notificationIDString)
                else {
                    return
                }

                Task {
                    if appState.notifications.isEmpty {
                        await appState.loadNotifications()
                    }
                    await appState.markNotificationRead(notificationID)
                }
            }
            #endif
        }
    }

    #if os(iOS)
    private static func startGoogleMobileAdsIfAvailable() {
        #if canImport(GoogleMobileAds)
        guard MegrumMobileAdsBootstrap.shouldStartSDK else {
            return
        }
        MobileAds.shared.start()
        #endif
    }

    #if DEBUG
    /// Debug-only: launch with `MEGRUM_DEBUG_AUTO_SIGNIN_EMAIL` /
    /// `MEGRUM_DEBUG_AUTO_SIGNIN_PASSWORD` to sign in automatically so live
    /// screens can be exercised from automated simulator runs.
    @MainActor
    private static func performDebugAutoSignInIfRequested(authState: MegrumAuthState) async {
        let environment = ProcessInfo.processInfo.environment
        guard
            let email = environment["MEGRUM_DEBUG_AUTO_SIGNIN_EMAIL"],
            let password = environment["MEGRUM_DEBUG_AUTO_SIGNIN_PASSWORD"],
            !email.isEmpty,
            !password.isEmpty
        else {
            return
        }
        // 保存済みセッションが期限切れでもQAが確実に動くよう、常に入り直す。
        await authState.signIn(email: email, password: password)
    }

    /// Debug-only diagnostics: launch with
    /// `MEGRUM_DEBUG_DUMP_HIERARCHY=1` to print the UIKit view hierarchy to
    /// stdout so on-device rendering issues can be inspected via
    /// `devicectl device process launch --console`. Add
    /// `MEGRUM_DEBUG_TRIGGER_REFRESH=1` to also fire the pull-to-refresh
    /// controls and dump again afterwards.
    @MainActor
    private static func dumpViewHierarchyForDebuggingIfRequested() async {
        guard ProcessInfo.processInfo.environment["MEGRUM_DEBUG_DUMP_HIERARCHY"] == "1" else {
            return
        }
        try? await Task.sleep(nanoseconds: 8_000_000_000)
        print("MEGRUM_DEBUG_OS: \(UIDevice.current.systemVersion)")
        dumpAllWindows(marker: "INITIAL")

        guard ProcessInfo.processInfo.environment["MEGRUM_DEBUG_TRIGGER_REFRESH"] == "1" else {
            return
        }
        let refreshControls = allViews(ofType: UIRefreshControl.self)
        print("MEGRUM_DEBUG_REFRESH_CONTROLS: \(refreshControls.count)")
        for control in refreshControls {
            control.sendActions(for: .valueChanged)
        }
        try? await Task.sleep(nanoseconds: 10_000_000_000)
        dumpAllWindows(marker: "AFTER_REFRESH")
    }

    @MainActor
    private static func dumpAllWindows(marker: String) {
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else {
                continue
            }
            for window in windowScene.windows {
                print("MEGRUM_DEBUG_WINDOW[\(marker)]: \(window.frame) safeArea=\(window.safeAreaInsets)")
                if let description = window.perform(Selector(("recursiveDescription")))?.takeUnretainedValue() as? String {
                    print("MEGRUM_DEBUG_HIERARCHY_BEGIN[\(marker)]")
                    print(description)
                    print("MEGRUM_DEBUG_HIERARCHY_END[\(marker)]")
                }
            }
        }
    }

    @MainActor
    private static func allViews<T: UIView>(ofType type: T.Type) -> [T] {
        var results: [T] = []
        func walk(_ view: UIView) {
            if let match = view as? T {
                results.append(match)
            }
            for subview in view.subviews {
                walk(subview)
            }
        }
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else {
                continue
            }
            for window in windowScene.windows {
                walk(window)
            }
        }
        return results
    }
    #endif

    @MainActor
    private func requestNativePushAuthorizationIfReady() async {
        guard authState.isConfigured, authState.isAuthenticated, !didRequestNativePushAuthorization else {
            return
        }
        // ガイドツアー中は通知許可ダイアログを割り込ませない（終了時に onChange から再要求）。
        // VisualQAのツアー起動は、コーディネータ起動より .task が先行する競合があるため
        // 環境変数でも判定して起動時点から抑制する。
        let visualQAInitialScreen = ProcessInfo.processInfo.environment["MEGRUM_VISUAL_QA_INITIAL_SCREEN"]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        // VisualQA起動時は通知許可ダイアログがスクリーンショット検証を塞ぐため常に抑制する。
        guard !appState.isTutorialActive, visualQAInitialScreen == nil || visualQAInitialScreen?.isEmpty == true else {
            return
        }

        didRequestNativePushAuthorization = true
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .notDetermined:
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } catch {
                break
            }
        case .authorized, .provisional, .ephemeral:
            UIApplication.shared.registerForRemoteNotifications()
        case .denied:
            break
        @unknown default:
            break
        }
    }

    @MainActor
    private func registerPendingNativePushToken() async {
        guard authState.isConfigured, authState.isAuthenticated else {
            return
        }
        guard let pendingNativePushToken else {
            return
        }

        await appState.registerNativePushDeviceToken(
            pendingNativePushToken,
            appVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        )
    }
    #endif
}

#if !os(iOS)
private extension MegrumNativeApp {
    static func startGoogleMobileAdsIfAvailable() {}
}
#endif

#if os(iOS)
private final class NativePushAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    nonisolated static let deviceTokenUserInfoKey = "deviceToken"
    nonisolated static let linkPathUserInfoKey = "linkPath"
    nonisolated static let notificationIDUserInfoKey = "notificationID"
    nonisolated static let notificationKindUserInfoKey = "notificationKind"
    private static let logger = Logger(subsystem: "tokyo.megrum.native", category: "NativePush")

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        NotificationCenter.default.post(
            name: .megrumNativeAPNsTokenDidUpdate,
            object: nil,
            userInfo: [
                Self.deviceTokenUserInfoKey: deviceToken.map { String(format: "%02x", $0) }.joined()
            ]
        )
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        #if DEBUG
        Self.logger.debug("APNs registration failed: \(error.localizedDescription, privacy: .public)")
        #endif
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        var routedUserInfo: [String: String] = [:]

        if let linkPath = userInfo["linkPath"] as? String ?? userInfo["link_path"] as? String {
            routedUserInfo[Self.linkPathUserInfoKey] = linkPath
        }
        if let notificationID = userInfo["notificationId"] as? String ?? userInfo["notification_id"] as? String {
            routedUserInfo[Self.notificationIDUserInfoKey] = notificationID
        }
        if let kind = userInfo["kind"] as? String
            ?? userInfo["notificationKind"] as? String
            ?? userInfo["notification_kind"] as? String {
            routedUserInfo[Self.notificationKindUserInfoKey] = kind
        }

        NotificationCenter.default.post(
            name: .megrumNativeNotificationResponseDidReceive,
            object: nil,
            userInfo: routedUserInfo
        )
    }
}

private extension Notification.Name {
    static let megrumNativeAPNsTokenDidUpdate = Notification.Name("megrumNativeAPNsTokenDidUpdate")
    static let megrumNativeNotificationResponseDidReceive = Notification.Name("megrumNativeNotificationResponseDidReceive")
}
#endif
