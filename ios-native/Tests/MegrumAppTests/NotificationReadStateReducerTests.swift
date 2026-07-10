@testable import MegrumApp
import MegrumCore
import XCTest

final class NotificationReadStateReducerTests: XCTestCase {
    func testNotificationCenterPresentationStateFiltersTradeAndMeguriNotifications() {
        let unreadTradeID = UUID(uuidString: "00000000-0000-0000-0000-000000000111")!
        let readTradeID = UUID(uuidString: "00000000-0000-0000-0000-000000000112")!
        let communityID = UUID(uuidString: "00000000-0000-0000-0000-000000000113")!
        let readAt = Date(timeIntervalSince1970: 700)
        let notifications = [
            makeNotification(id: unreadTradeID, kind: .proposalReceived),
            makeNotification(id: readTradeID, kind: .messageReceived, readAt: readAt),
            makeNotification(id: communityID, kind: .groomLiked),
        ]
        var state = NotificationCenterPresentationState()

        XCTAssertEqual(state.visibleNotifications(in: notifications).map(\.id), [unreadTradeID, readTradeID, communityID])
        XCTAssertEqual(state.emptyTitle, "まだ通知はありません")

        state.filter = .trades
        XCTAssertEqual(state.visibleNotifications(in: notifications).map(\.id), [unreadTradeID, readTradeID])
        XCTAssertEqual(state.emptyTitle, "取引の通知はありません")

        state.filter = .meguri
        XCTAssertEqual(state.visibleNotifications(in: notifications).map(\.id), [communityID])
        XCTAssertEqual(state.emptyTitle, "めぐりの通知はありません")
    }

    func testNotificationCenterPresentationStateGroupsSectionsByRecency() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let todayID = UUID(uuidString: "00000000-0000-0000-0000-000000000121")!
        let thisWeekID = UUID(uuidString: "00000000-0000-0000-0000-000000000122")!
        let earlierID = UUID(uuidString: "00000000-0000-0000-0000-000000000123")!
        let notifications = [
            makeNotification(id: todayID, createdAt: now.addingTimeInterval(-60)),
            makeNotification(id: thisWeekID, createdAt: now.addingTimeInterval(-3 * 24 * 60 * 60)),
            makeNotification(id: earlierID, createdAt: now.addingTimeInterval(-30 * 24 * 60 * 60)),
        ]
        let state = NotificationCenterPresentationState()

        let sections = state.sections(in: notifications, now: now)

        XCTAssertEqual(sections.map(\.title), ["今日", "今週", "それ以前"])
        XCTAssertEqual(sections[0].notifications.map(\.id), [todayID])
        XCTAssertEqual(sections[1].notifications.map(\.id), [thisWeekID])
        XCTAssertEqual(sections[2].notifications.map(\.id), [earlierID])

        // 空セクションは出さない。
        let onlyToday = state.sections(
            in: [makeNotification(id: todayID, createdAt: now)],
            now: now
        )
        XCTAssertEqual(onlyToday.map(\.title), ["今日"])
    }

    func testMarkReadOnlyUpdatesUnreadMatchingNotification() {
        let targetID = UUID(uuidString: "00000000-0000-0000-0000-000000000101")!
        let otherID = UUID(uuidString: "00000000-0000-0000-0000-000000000102")!
        let existingReadAt = Date(timeIntervalSince1970: 100)
        let readAt = Date(timeIntervalSince1970: 200)
        let notifications = [
            makeNotification(id: targetID),
            makeNotification(id: otherID, readAt: existingReadAt),
        ]

        let updated = NotificationReadStateReducer.markRead(
            notifications,
            id: targetID,
            readAt: readAt
        )

        XCTAssertEqual(updated.first(where: { $0.id == targetID })?.readAt, readAt)
        XCTAssertEqual(updated.first(where: { $0.id == otherID })?.readAt, existingReadAt)
        XCTAssertEqual(NotificationReadStateReducer.unreadCount(in: updated), 0)
    }

    func testMarkUnreadRollsBackOnlyMatchingNotification() {
        let targetID = UUID(uuidString: "00000000-0000-0000-0000-000000000103")!
        let otherID = UUID(uuidString: "00000000-0000-0000-0000-000000000104")!
        let readAt = Date(timeIntervalSince1970: 300)
        let notifications = [
            makeNotification(id: targetID, readAt: readAt),
            makeNotification(id: otherID, readAt: readAt),
        ]

        let updated = NotificationReadStateReducer.markUnread(notifications, id: targetID)

        XCTAssertNil(updated.first(where: { $0.id == targetID })?.readAt)
        XCTAssertEqual(updated.first(where: { $0.id == otherID })?.readAt, readAt)
    }

    func testMarkAllReadKeepsExistingReadTimestamps() {
        let unreadID = UUID(uuidString: "00000000-0000-0000-0000-000000000105")!
        let readID = UUID(uuidString: "00000000-0000-0000-0000-000000000106")!
        let existingReadAt = Date(timeIntervalSince1970: 400)
        let readAt = Date(timeIntervalSince1970: 500)
        let notifications = [
            makeNotification(id: unreadID),
            makeNotification(id: readID, readAt: existingReadAt),
        ]

        let updated = NotificationReadStateReducer.markAllRead(notifications, readAt: readAt)

        XCTAssertEqual(updated.first(where: { $0.id == unreadID })?.readAt, readAt)
        XCTAssertEqual(updated.first(where: { $0.id == readID })?.readAt, existingReadAt)
        XCTAssertEqual(NotificationReadStateReducer.unreadCount(in: updated), 0)
    }

    func testMergingUpdatedReplacesOnlyReturnedNotifications() {
        let targetID = UUID(uuidString: "00000000-0000-0000-0000-000000000107")!
        let otherID = UUID(uuidString: "00000000-0000-0000-0000-000000000108")!
        let notifications = [
            makeNotification(id: targetID, title: "古い通知"),
            makeNotification(id: otherID, title: "そのまま"),
        ]
        let serverReadAt = Date(timeIntervalSince1970: 600)
        let serverNotification = makeNotification(
            id: targetID,
            title: "サーバー通知",
            readAt: serverReadAt
        )

        let updated = NotificationReadStateReducer.mergingUpdated(
            notifications,
            updated: [serverNotification]
        )

        XCTAssertEqual(updated.first(where: { $0.id == targetID })?.title, "サーバー通知")
        XCTAssertEqual(updated.first(where: { $0.id == targetID })?.readAt, serverReadAt)
        XCTAssertEqual(updated.first(where: { $0.id == otherID })?.title, "そのまま")
    }

    private func makeNotification(
        id: UUID,
        kind: MegrumNotificationKind = .proposalReceived,
        title: String = "通知",
        readAt: Date? = nil,
        createdAt: Date = Date(timeIntervalSince1970: 0)
    ) -> MegrumNotification {
        MegrumNotification(
            id: id,
            kind: kind,
            title: title,
            body: "本文",
            linkPath: "/proposals/\(id.uuidString)",
            readAt: readAt,
            createdAt: createdAt
        )
    }
}
