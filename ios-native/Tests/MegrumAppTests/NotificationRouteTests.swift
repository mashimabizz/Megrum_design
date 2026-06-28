@testable import MegrumApp
import MegrumCore
import XCTest

final class NotificationRouteTests: XCTestCase {
    private let tradeID = "11111111-1111-1111-1111-111111111111"
    private let disputeID = "22222222-2222-2222-2222-222222222222"
    private let userID = "33333333-3333-3333-3333-333333333333"

    func testTradeAndDisputeLinkPathsRouteToDetailIntents() {
        XCTAssertEqual(NotificationRouteIntent(linkPath: "/proposals/\(tradeID)"), .tradeDetail(id: tradeID))
        XCTAssertEqual(NotificationRouteIntent(linkPath: "/transactions/\(tradeID)"), .tradeDetail(id: tradeID))
        XCTAssertEqual(NotificationRouteIntent(linkPath: "/trades/\(tradeID)"), .tradeDetail(id: tradeID))
        XCTAssertEqual(NotificationRouteIntent(linkPath: "/transactions/\(tradeID)/capture"), .tradeEvidenceCapture(id: tradeID))
        XCTAssertEqual(NotificationRouteIntent(linkPath: "/transactions/\(tradeID)/approve"), .tradeEvidenceApproval(id: tradeID))
        XCTAssertEqual(NotificationRouteIntent(linkPath: "/transactions/\(tradeID)/rate"), .tradeEvaluation(id: tradeID))
        XCTAssertEqual(NotificationRouteIntent(linkPath: "/trades/\(tradeID)/approve"), .tradeEvidenceApproval(id: tradeID))
        XCTAssertEqual(NotificationRouteIntent(linkPath: "/trades/\(tradeID)/rate"), .tradeEvaluation(id: tradeID))
        XCTAssertEqual(
            NotificationRouteIntent(linkPath: "/trades/\(tradeID)/cancel-or-late?kind=cancel"),
            .tradeAssistance(id: tradeID, kind: .cancel)
        )
        XCTAssertEqual(
            NotificationRouteIntent(linkPath: "/transactions/\(tradeID)/cancel-or-late?kind=late"),
            .tradeAssistance(id: tradeID, kind: .late)
        )
        XCTAssertEqual(NotificationRouteIntent(linkPath: "/disputes/\(disputeID)"), .disputeDetail(id: disputeID))
    }

    func testMeguriLinkPathsRouteToBoardAndMessageIntents() {
        XCTAssertEqual(
            NotificationRouteIntent(linkPath: "/meguri-board-thread?id=thread-1&viewMode=nearby_3km"),
            .meguriBoardThread(id: "thread-1", viewMode: "nearby_3km")
        )
        XCTAssertEqual(
            NotificationRouteIntent(linkPath: "megrum-preview://meguri-board-thread?id=thread-2"),
            .meguriBoardThread(id: "thread-2", viewMode: nil)
        )
        XCTAssertEqual(
            NotificationRouteIntent(linkPath: "/meguri-letters?open=1&userId=\(userID)"),
            .meguriMessages(peerID: userID, open: "1")
        )
        XCTAssertEqual(
            NotificationRouteIntent(linkPath: "/grooms/post-1?peerId=\(userID)", kind: .groomReply),
            .meguriMessages(peerID: userID, open: nil)
        )
    }

    func testProfileAndEvaluationLinkPathsRouteToProfileIntents() {
        XCTAssertEqual(NotificationRouteIntent(linkPath: "/users/\(userID)"), .userProfile(id: userID))
        XCTAssertEqual(NotificationRouteIntent(linkPath: "/user-profile?id=\(userID)"), .userProfile(id: userID))
        XCTAssertEqual(NotificationRouteIntent(linkPath: "/users/\(userID)/evaluations"), .userEvaluations(userID: userID))
        XCTAssertEqual(NotificationRouteIntent(linkPath: "/user-evaluations?id=\(userID)"), .userEvaluations(userID: userID))
    }

    func testTabAndUnknownLinkPathsUseSafeFallbacks() {
        XCTAssertEqual(NotificationRouteIntent(linkPath: "/goods/preview"), .tab(.inventory))
        XCTAssertEqual(NotificationRouteIntent(linkPath: "/wish/preview"), .tab(.wish))
        XCTAssertEqual(NotificationRouteIntent(linkPath: "/meguri"), .tab(.meguri))
        XCTAssertEqual(
            NotificationRouteIntent(linkPath: "/unknown/deep-link"),
            .unknown(rawPath: "/unknown/deep-link", fallbackTab: .home)
        )
        XCTAssertEqual(NotificationRouteIntent(linkPath: "/transactions"), .tab(.trades))
        XCTAssertNil(NotificationRouteIntent(linkPath: nil))
        XCTAssertNil(NotificationRouteIntent(linkPath: " "))
    }

    func testDetailIntentsExposeExistingTabFallbacks() throws {
        XCTAssertEqual(try XCTUnwrap(NotificationRouteIntent(linkPath: "/transactions/\(tradeID)")).fallbackTab, .trades)
        XCTAssertEqual(try XCTUnwrap(NotificationRouteIntent(linkPath: "/disputes/\(disputeID)")).fallbackTab, .trades)
        XCTAssertEqual(try XCTUnwrap(NotificationRouteIntent(linkPath: "/meguri-board-thread?id=thread-1")).fallbackTab, .meguri)
        XCTAssertEqual(try XCTUnwrap(NotificationRouteIntent(linkPath: "/users/\(userID)")).fallbackTab, .home)
    }

    func testMessageReceivedNotificationIsTradeRelated() {
        XCTAssertTrue(MegrumNotificationKind.messageReceived.isTradeRelatedForCenter)
        XCTAssertEqual(MegrumNotificationKind.messageReceived.centerSymbolName, "message")
        XCTAssertFalse(MegrumNotificationKind.groomLiked.isTradeRelatedForCenter)
        XCTAssertEqual(MegrumNotificationKind.groomLiked.centerSymbolName, "heart")
    }
}
