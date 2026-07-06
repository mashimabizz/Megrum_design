import Foundation
import MegrumCore

@MainActor
extension MegrumAppState {
    /// チャットルームを開いた記録を残し、対応する通知を自動既読にする。
    public func recordBoardThreadVisit(_ threadID: UUID) {
        guard let viewerID = viewer?.id else {
            return
        }
        BoardThreadVisitStore.recordVisit(threadID: threadID, viewerID: viewerID)
        Task { [weak self] in
            await self?.autoMarkViewedNotificationsRead()
        }
    }

    /// すでに見ためぐりメッセージ / チャットルームの通知を自動で既読にする。
    /// - めぐりメッセージ：その相手からの未読メッセージが残っていない
    /// - チャットルーム：通知より後にそのルームを開いた記録がある
    public func autoMarkViewedNotificationsRead() async {
        guard let viewerID = viewer?.id else {
            return
        }
        let targets = notifications.filter { notification in
            notification.isUnread && shouldAutoMarkRead(notification, viewerID: viewerID)
        }
        guard !targets.isEmpty else {
            return
        }

        let readAt = Date()
        for target in targets {
            notifications = NotificationReadStateReducer.markRead(
                notifications,
                id: target.id,
                readAt: readAt
            )
        }
        // サーバー反映はベストエフォート（失敗しても次回ロード時に再判定される）。
        for target in targets {
            _ = try? await repository.markNotificationRead(target.id)
        }
    }

    private func shouldAutoMarkRead(_ notification: MegrumNotification, viewerID: UUID) -> Bool {
        guard let intent = NotificationRouteIntent(notification: notification) else {
            return false
        }
        switch intent {
        case .meguriBoardThread(let id, _):
            guard let threadID = UUID(uuidString: id),
                  let visitedAt = BoardThreadVisitStore.visitedAt(threadID: threadID, viewerID: viewerID)
            else {
                return false
            }
            return visitedAt >= notification.createdAt
        case .meguriMessages(let peerID, _):
            guard let peerID = peerID.flatMap(UUID.init(uuidString:)) else {
                return false
            }
            let messages = meguriMessages(with: peerID)
            guard !messages.isEmpty else {
                return false
            }
            return !messages.contains { message in
                message.senderID == peerID
                    && message.recipientID == viewerID
                    && message.readAt == nil
            }
        default:
            return false
        }
    }
}
