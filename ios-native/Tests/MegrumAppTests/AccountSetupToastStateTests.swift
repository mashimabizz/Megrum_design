@testable import MegrumApp
import Foundation
import XCTest

final class AccountSetupToastStateTests: XCTestCase {
    func testToastStateIgnoresStaleClearRequests() {
        let staleID = UUID(uuidString: "30000000-0000-0000-0000-00000000A001")!
        let currentID = UUID(uuidString: "30000000-0000-0000-0000-00000000A002")!
        var state = AccountSetupToastState()

        state.showToast("最初の通知", id: staleID)
        state.showToast("新しい通知", id: currentID)
        state.clearToast(ifMatching: staleID)

        XCTAssertEqual(state.message, "新しい通知")

        state.clearToast(ifMatching: currentID)

        XCTAssertNil(state.message)
    }
}
