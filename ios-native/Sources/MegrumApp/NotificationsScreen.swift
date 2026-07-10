import MegrumCore
import MegrumDesign
import SwiftUI

@MainActor
struct NotificationCenterScreen: View {
    @ObservedObject var appState: MegrumAppState
    var onOpenDestination: (MegrumTab) -> Void
    var onOpenRouteIntent: (NotificationRouteIntent) -> Bool = { _ in false }
    @State private var presentationState = NotificationCenterPresentationState()
    /// iter1226.422：グルーム系通知は通知一覧の上に直接ビューアを開く（閉じると一覧へ戻る）。
    @State private var groomViewerSelection: GroomPost?

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
            thumbnailURLByID: appState.notificationThumbnailURLByID,
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
        // iter1226.422：グルーム通知タップ→その場でビューア（めぐりホームを経由しない）。
        .modifier(
            GroomViewerPresentationModifier(
                selectedGroom: $groomViewerSelection,
                grooms: groomViewerSelection.map { [$0] } ?? [],
                appState: appState
            )
        )
    }

    /// グルーム系の通知なら通知一覧の上に直接ビューアを開く。開けない（圏外×無料など）
    /// 場合は false を返し、従来のタブ遷移へフォールバックする。
    private func openGroomInPlaceIfPossible(_ intent: NotificationRouteIntent) async -> Bool {
        let groomID: UUID?
        switch intent {
        case .ownGroom(let postIDString):
            groomID = postIDString.flatMap(UUID.init(uuidString:))
        case .groomDetail(let idString):
            groomID = UUID(uuidString: idString)
        default:
            return false
        }
        guard let groomID else {
            return false
        }
        let cached = appState.groomMapPosts.first { $0.id == groomID }
            ?? appState.grooms.first { $0.id == groomID }
        let resolved: GroomPost?
        if let cached {
            resolved = cached
        } else {
            resolved = await appState.loadGroomPost(id: groomID)
        }
        guard let groom = resolved else {
            return false
        }
        guard MeguriAccessPolicy.canOpenGroom(
            groom,
            currentCoordinate: nil,
            viewerID: appState.viewer?.id,
            hasEncountered: groom.encounteredInRange,
            subscriptionState: appState.subscriptionState
        ) else {
            return false
        }
        groomViewerSelection = groom
        return true
    }

    private func openNotification(_ notification: MegrumNotification) {
        Task {
            await appState.markNotificationRead(notification.id)
            guard let intent = NotificationRouteIntent(notification: notification) else {
                return
            }
            if await openGroomInPlaceIfPossible(intent) {
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
            if await openGroomInPlaceIfPossible(intent) {
                return
            }
            if !onOpenRouteIntent(intent) {
                onOpenDestination(intent.fallbackTab)
            }
        }
    }
}
