import XCTest
@testable import MegrumCore

final class MegrumCoreTests: XCTestCase {
    func testExchangeMethodDisplayNames() {
        XCTAssertEqual(ExchangeMethod.hand.displayName, "現地交換")
        XCTAssertEqual(ExchangeMethod.mail.displayName, "郵送交換")
        XCTAssertEqual(ExchangeMethod.both.displayName, "どちらもOK")
    }

    func testProposalStatusRawValueMatchesExistingStateMachine() {
        XCTAssertEqual(ProposalStatus.agreementOneSide.rawValue, "agreement_one_side")
    }
}
