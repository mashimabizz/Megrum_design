import MegrumCore
import MegrumDesign
import SwiftUI

@MainActor
struct NotificationCenterScreen: View {
    @ObservedObject var appState: MegrumAppState
    var onOpenDestination: (MegrumTab) -> Void
    var onOpenRouteIntent: (NotificationRouteIntent) -> Bool = { _ in false }
    @State private var presentationState = NotificationCenterPresentationState()

    init(
        appState: MegrumAppState,
        onOpenDestination: @escaping (MegrumTab) -> Void,
        onOpenRouteIntent: @escaping (NotificationRouteIntent) -> Bool = { _ in false }
    ) {
        self.appState = appState
        self.onOpenDestination = onOpenDestination
        self.onOpenRouteIntent = onOpenRouteIntent
    }

    var body: some View {
        NotificationCenterContent(
            presentationState: $presentationState,
            isLoading: appState.isLoadingNotifications,
            notifications: appState.notifications,
            onSelectNotification: openNotification,
            onSelectLikeGroup: openLikeGroup
        )
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
    }

    private func openNotification(_ notification: MegrumNotification) {
        Task {
            await appState.markNotificationRead(notification.id)
            guard let intent = NotificationRouteIntent(notification: notification) else {
                return
            }
            if !onOpenRouteIntent(intent) {
                onOpenDestination(intent.fallbackTab)
            }
        }
    }

    /// いいね集約行：束ねた全通知を既読化してから、最新の通知の遷移先を開く。iter1226.413。
    private func openLikeGroup(_ notifications: [MegrumNotification]) {
        guard let newest = notifications.first else {
            return
        }
        Task {
            for notification in notifications where notification.isUnread {
                await appState.markNotificationRead(notification.id)
            }
            guard let intent = NotificationRouteIntent(notification: newest) else {
                return
            }
            if !onOpenRouteIntent(intent) {
                onOpenDestination(intent.fallbackTab)
            }
        }
    }
}
