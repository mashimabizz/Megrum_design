@testable import MegrumApp
import MegrumCore
import XCTest

final class ProposalCreateFlowTests: XCTestCase {
    func testProposalCreateStepsStayInVisibleParityOrder() {
        XCTAssertEqual(
            ProposalCreateStep.allCases.map(\.title),
            ["出すもの", "受け取る", "待ち合わせ", "確認"]
        )
    }

    func testProposalFlowCannotAdvancePastGiveWithoutSenderGoods() {
        let configuration = ProposalCreateConfiguration(
            exchangeMethod: .hand,
            hasSelectedSenderGoods: false,
            isCreatingProposal: false,
            hasReadyMailingAddress: true,
            isLoadingMailingAddress: false,
            hasValidMeetup: true,
            receiverGoodsCount: 1,
            isListingSource: false
        )

        XCTAssertFalse(configuration.canAdvance(from: .give))
        XCTAssertEqual(configuration.blockedTitle(for: .give), "出すものを選択してください")
    }

    func testProposalFlowRequiresMeetupBeforeConfirmForHandExchange() {
        let configuration = ProposalCreateConfiguration(
            exchangeMethod: .hand,
            hasSelectedSenderGoods: true,
            isCreatingProposal: false,
            hasReadyMailingAddress: true,
            isLoadingMailingAddress: false,
            hasValidMeetup: false,
            receiverGoodsCount: 1,
            isListingSource: false
        )

        XCTAssertTrue(configuration.canAdvance(from: .give))
        XCTAssertTrue(configuration.canAdvance(from: .receive))
        XCTAssertFalse(configuration.canAdvance(from: .meetup))
        XCTAssertFalse(configuration.canAdvance(from: .confirm))
    }

    func testProposalFlowCanReachConfirmWhenSelectionsAndMeetupAreReady() {
        let configuration = ProposalCreateConfiguration(
            exchangeMethod: .hand,
            hasSelectedSenderGoods: true,
            isCreatingProposal: false,
            hasReadyMailingAddress: false,
            isLoadingMailingAddress: false,
            hasValidMeetup: true,
            receiverGoodsCount: 2,
            isListingSource: true
        )

        XCTAssertTrue(ProposalCreateStep.allCases.allSatisfy { configuration.canAdvance(from: $0) })
        XCTAssertEqual(configuration.targetStatus, .sent)
        XCTAssertEqual(configuration.targetSupplement, "ほか1件も受け取る条件です")
    }
}
