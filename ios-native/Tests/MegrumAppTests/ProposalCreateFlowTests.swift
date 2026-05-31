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

    func testProposalFlowCannotSubmitWithoutReceiverGoods() {
        let configuration = ProposalCreateConfiguration(
            exchangeMethod: .mail,
            hasSelectedSenderGoods: true,
            isCreatingProposal: false,
            hasReadyMailingAddress: true,
            isLoadingMailingAddress: false,
            hasValidMeetup: false,
            receiverGoodsCount: 0,
            isListingSource: false
        )

        XCTAssertFalse(configuration.canSubmit)
        XCTAssertEqual(configuration.submitTitle, "受け取るものを選択")
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

    func testProposalSubmittedSummaryOmitsTagsWhenEmpty() {
        let summary = ProposalSubmittedSummary(
            senderCount: 2,
            receiverCount: 1,
            methodTitle: "現地交換",
            meetupSummary: "6月1日 12:00 / 横浜アリーナ",
            conditionTags: []
        )

        XCTAssertEqual(summary.detailText, "2件を提示 / 1件を受け取り候補で送信しました。")
    }

    func testProposalSubmittedSummaryIncludesConditionTags() {
        let summary = ProposalSubmittedSummary(
            senderCount: 1,
            receiverCount: 3,
            methodTitle: "現地 / 郵送",
            meetupSummary: "6月1日 12:00 / 横浜アリーナ",
            conditionTags: ["終演後OK", "同日発送"]
        )

        XCTAssertEqual(summary.detailText, "1件を提示 / 3件を受け取り候補・終演後OK / 同日発送")
    }
}
