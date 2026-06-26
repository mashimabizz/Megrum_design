@testable import MegrumApp
import MegrumCore
import XCTest

final class OwnProfileSummaryTests: XCTestCase {
    func testSummaryFormatsVisibleProfileValues() {
        let viewer = UserProfile(
            id: UUID(uuidString: "20000000-0000-0000-0000-000000000001")!,
            handle: "michilion",
            displayName: "みちりおん",
            bio: "関東で交換しています。",
            avatarURL: URL(string: "https://example.com/avatar.jpg"),
            prefecture: " 東京都 "
        )

        let summary = OwnProfileSummary(
            viewer: viewer,
            inventoryCount: 12,
            wishCount: 5,
            listingCount: 3,
            proposals: [
                proposal(status: .sent),
                proposal(status: .agreed),
                proposal(status: .completed),
                proposal(status: .cancelled)
            ]
        )

        XCTAssertEqual(summary?.displayName, "みちりおん")
        XCTAssertEqual(summary?.handleText, "@michilion")
        XCTAssertEqual(summary?.bio, "関東で交換しています。")
        XCTAssertEqual(summary?.avatarURL?.absoluteString, "https://example.com/avatar.jpg")
        XCTAssertEqual(summary?.prefectureText, "東京都")
        XCTAssertEqual(summary?.inventoryCount, 12)
        XCTAssertEqual(summary?.wishCount, 5)
        XCTAssertEqual(summary?.listingCount, 3)
        XCTAssertEqual(summary?.listingText, "3")
        XCTAssertEqual(summary?.activeTradeText, "2件")
        XCTAssertEqual(summary?.completedTradeCount, 1)
        XCTAssertEqual(summary?.completedTradeText, "1")
    }

    func testSummaryReturnsNilWithoutViewer() {
        let summary = OwnProfileSummary(viewer: nil, inventoryCount: 0, wishCount: 0, proposals: [])

        XCTAssertNil(summary)
    }

    private func proposal(status: ProposalStatus) -> TradeProposal {
        TradeProposal(
            id: UUID(),
            senderID: UUID(uuidString: "20000000-0000-0000-0000-000000000011")!,
            receiverID: UUID(uuidString: "20000000-0000-0000-0000-000000000012")!,
            status: status,
            exchangeMethod: .hand,
            senderGoodsIDs: [],
            receiverGoodsIDs: []
        )
    }
}
