@testable import MegrumApp
import XCTest

final class TradeChatAffordanceTests: XCTestCase {
    func testArrivalQuickActionsMapToSendableMessageBodies() {
        XCTAssertEqual(TradeArrivalQuickAction.enroute.messageBody, "向かっています")
        XCTAssertEqual(TradeArrivalQuickAction.arrived.messageBody, "到着しました")
        XCTAssertEqual(TradeArrivalQuickAction.left.messageBody, "離れました")
    }

    func testArrivalQuickActionsHaveAccessibleLabelsAndSymbols() {
        for action in TradeArrivalQuickAction.allCases {
            XCTAssertFalse(action.title.isEmpty)
            XCTAssertFalse(action.messageBody.isEmpty)
            XCTAssertFalse(action.systemImage.isEmpty)
        }
    }

    func testAssistanceRequestKindsHaveChatMenuLabels() {
        for kind in TradeAssistanceRequestKind.allCases {
            XCTAssertFalse(kind.title.isEmpty)
            XCTAssertFalse(kind.systemImage.isEmpty)
            XCTAssertFalse(kind.placeholder.isEmpty)
        }
    }

    func testAssistanceRequestSystemMessageKeepsKindPrefix() {
        XCTAssertEqual(TradeAssistanceRequestKind.late.systemMessageBody(from: "10分遅れます"), "遅刻申請：10分遅れます")
        XCTAssertEqual(TradeAssistanceRequestKind.cancel.systemMessageBody(from: "   "), "キャンセル申請")
    }
}
