@testable import MegrumApp
import Foundation
import MegrumCore
import XCTest

final class ProposalCreateSheetTests: XCTestCase {
    func testProposalCreateSheetDraftStateOrdersAndPrunesConditionTags() {
        var draft = ProposalCreateSheetDraftState()

        draft.toggleConditionTag("終演後OK")
        draft.toggleConditionTag("即日発送")
        XCTAssertEqual(
            draft.orderedConditionTags(options: ["即日発送", "同日発送", "終演後OK"]),
            ["即日発送", "終演後OK"]
        )

        draft.toggleConditionTag("終演後OK")
        XCTAssertEqual(draft.orderedConditionTags(options: ["即日発送", "終演後OK"]), ["即日発送"])

        draft.toggleConditionTag("グッズ販売中OK")
        draft.pruneConditionTags(to: ["終演後OK", "グッズ販売中OK"])
        XCTAssertEqual(draft.orderedConditionTags(options: ["終演後OK", "グッズ販売中OK"]), ["グッズ販売中OK"])
    }

    func testProposalCreateSheetDraftStateBoundsMeetupEndAfterStart() {
        let now = Date(timeIntervalSinceReferenceDate: 10_000)
        var draft = ProposalCreateSheetDraftState(now: now)
        let newStart = now.addingTimeInterval(3_600)

        draft.boundMeetupEnd(after: newStart)

        XCTAssertEqual(draft.meetupEndAt, newStart.addingTimeInterval(30 * 60))
    }

    func testProposalCreateSheetDraftStateAppliesCurrentLocationOnlyForMeetup() throws {
        var draft = ProposalCreateSheetDraftState()
        let coordinate = MegrumLocationCoordinate(latitude: 35.681236, longitude: 139.7671254)

        draft.applyCurrentLocation(coordinate, requiresMeetupBeforeSubmit: false)
        XCTAssertTrue(draft.meetupPlaceName.isEmpty)

        draft.applyCurrentLocation(coordinate, requiresMeetupBeforeSubmit: true)
        XCTAssertEqual(draft.meetupPlaceName, "現在地")
        XCTAssertEqual(draft.meetupLatitudeText, "35.681236")
        XCTAssertEqual(draft.meetupLongitudeText, "139.767125")
        XCTAssertNotNil(draft.meetupInput)
    }

    func testMailProposalCanSubmitDirectly() {
        let configuration = ProposalCreateConfiguration(
            exchangeMethod: .mail,
            hasSelectedSenderGoods: true,
            isCreatingProposal: false,
            hasReadyMailingAddress: true,
            isLoadingMailingAddress: false,
            hasValidMeetup: false,
            receiverGoodsCount: 1,
            isListingSource: false
        )

        XCTAssertEqual(configuration.conditionTagOptions, ["即日発送", "同日発送", "開演前OK", "終演後OK", "グッズ販売中OK", "短時間OK", "同種優先"])
        XCTAssertEqual(configuration.targetStatus, .sent)
        XCTAssertTrue(configuration.canSubmit)
        XCTAssertNil(configuration.methodNotice)
        XCTAssertEqual(configuration.submitTitle, "この内容で打診を送信")
    }

    func testHandProposalRequiresMeetupBeforeSubmit() {
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

        XCTAssertEqual(configuration.conditionTagOptions, ["開演前OK", "終演後OK", "グッズ販売中OK", "短時間OK", "同種優先"])
        XCTAssertNil(configuration.targetStatus)
        XCTAssertFalse(configuration.canSubmit)
        XCTAssertNotNil(configuration.methodNotice)
        XCTAssertEqual(configuration.submitTitle, "待ち合わせ入力が必要")
    }

    func testHandProposalCanSubmitWithValidMeetup() {
        let configuration = ProposalCreateConfiguration(
            exchangeMethod: .hand,
            hasSelectedSenderGoods: true,
            isCreatingProposal: false,
            hasReadyMailingAddress: false,
            isLoadingMailingAddress: false,
            hasValidMeetup: true,
            receiverGoodsCount: 1,
            isListingSource: false
        )

        XCTAssertEqual(configuration.conditionTagOptions, ["開演前OK", "終演後OK", "グッズ販売中OK", "短時間OK", "同種優先"])
        XCTAssertEqual(configuration.targetStatus, .sent)
        XCTAssertTrue(configuration.canSubmit)
        XCTAssertNil(configuration.methodNotice)
        XCTAssertEqual(configuration.submitTitle, "この内容で打診を送信")
    }

    func testMailProposalRequiresReadyMailingAddress() {
        let configuration = ProposalCreateConfiguration(
            exchangeMethod: .mail,
            hasSelectedSenderGoods: true,
            isCreatingProposal: false,
            hasReadyMailingAddress: false,
            isLoadingMailingAddress: false,
            hasValidMeetup: false,
            receiverGoodsCount: 1,
            isListingSource: false
        )

        XCTAssertNil(configuration.targetStatus)
        XCTAssertFalse(configuration.canSubmit)
        XCTAssertEqual(configuration.submitTitle, "住所登録が必要")
        XCTAssertEqual(configuration.methodNotice, "郵送交換は住所登録が必要です。設定から住所を登録してください。")
    }

    func testBothProposalCanSubmitWithReadyAddressAndValidMeetup() {
        let configuration = ProposalCreateConfiguration(
            exchangeMethod: .both,
            hasSelectedSenderGoods: true,
            isCreatingProposal: false,
            hasReadyMailingAddress: true,
            isLoadingMailingAddress: false,
            hasValidMeetup: true,
            receiverGoodsCount: 1,
            isListingSource: false
        )

        XCTAssertEqual(configuration.conditionTagOptions, ["即日発送", "同日発送", "開演前OK", "終演後OK", "グッズ販売中OK", "短時間OK", "同種優先"])
        XCTAssertEqual(configuration.targetStatus, .sent)
        XCTAssertTrue(configuration.canSubmit)
        XCTAssertNil(configuration.methodNotice)
        XCTAssertEqual(configuration.submitTitle, "この内容で打診を送信")
    }

    func testBothProposalRequiresReadyMailingAddressEvenWithValidMeetup() {
        let configuration = ProposalCreateConfiguration(
            exchangeMethod: .both,
            hasSelectedSenderGoods: true,
            isCreatingProposal: false,
            hasReadyMailingAddress: false,
            isLoadingMailingAddress: false,
            hasValidMeetup: true,
            receiverGoodsCount: 1,
            isListingSource: false
        )

        XCTAssertNil(configuration.targetStatus)
        XCTAssertFalse(configuration.canSubmit)
        XCTAssertEqual(configuration.submitTitle, "住所登録が必要")
        XCTAssertEqual(configuration.methodNotice, "郵送交換は住所登録が必要です。設定から住所を登録してください。")
    }

    func testListingSourceShowsListingContextAndBundleCount() {
        let configuration = ProposalCreateConfiguration(
            exchangeMethod: .mail,
            hasSelectedSenderGoods: true,
            isCreatingProposal: false,
            hasReadyMailingAddress: true,
            isLoadingMailingAddress: false,
            hasValidMeetup: false,
            receiverGoodsCount: 3,
            isListingSource: true
        )

        XCTAssertEqual(configuration.targetSubtitle, "個別募集から選択")
        XCTAssertEqual(configuration.targetSupplement, "ほか2件も受け取る条件です")
    }
}
