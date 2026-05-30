import MegrumApp
import SwiftUI
#if os(iOS)
import UIKit
@preconcurrency import UserNotifications
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
    #endif

    var body: some Scene {
        WindowGroup {
            MegrumRootView(
                appState: appState,
                authState: authState,
                notificationDestinationTab: $notificationDestinationTab
            )
            #if os(iOS)
            .task {
                await requestNativePushAuthorizationIfReady()
            }
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
                notificationDestinationTab = MegrumTab(notificationLinkPath: linkPath) ?? .home

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
    @MainActor
    private func requestNativePushAuthorizationIfReady() async {
        guard authState.isConfigured, authState.isAuthenticated, !didRequestNativePushAuthorization else {
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

#if os(iOS)
private final class NativePushAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    nonisolated static let deviceTokenUserInfoKey = "deviceToken"
    nonisolated static let linkPathUserInfoKey = "linkPath"
    nonisolated static let notificationIDUserInfoKey = "notificationID"

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
        print("APNs registration failed: \(error.localizedDescription)")
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
