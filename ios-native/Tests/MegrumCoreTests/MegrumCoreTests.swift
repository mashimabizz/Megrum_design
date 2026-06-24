import XCTest
@testable import MegrumCore

final class MegrumCoreTests: XCTestCase {
    func testExchangeMethodDisplayNames() {
        XCTAssertEqual(ExchangeMethod.hand.displayName, "現地交換")
        XCTAssertEqual(ExchangeMethod.mail.displayName, "郵送交換")
        XCTAssertEqual(ExchangeMethod.both.displayName, "現地交換・郵送OK")
    }

    func testProposalStatusRawValueMatchesExistingStateMachine() {
        XCTAssertEqual(ProposalStatus.agreementOneSide.rawValue, "agreement_one_side")
        XCTAssertEqual(ProposalStatus.cancelled.rawValue, "cancelled")
        XCTAssertEqual(ProposalStatus.completed.rawValue, "completed")
    }

    func testAccountStatusSetupBoundary() {
        XCTAssertTrue(AccountStatus.registered.requiresSetup)
        XCTAssertTrue(AccountStatus.verified.requiresSetup)
        XCTAssertTrue(AccountStatus.onboarding.requiresSetup)
        XCTAssertFalse(AccountStatus.active.requiresSetup)
        XCTAssertEqual(AccountStatus.deletionRequested.rawValue, "deletion_requested")
    }

    func testOshiRequestKindMemberSelectionBoundary() {
        XCTAssertTrue(OshiRequestKind.group.supportsMemberSelection)
        XCTAssertTrue(OshiRequestKind.work.supportsMemberSelection)
        XCTAssertFalse(OshiRequestKind.solo.supportsMemberSelection)
        XCTAssertEqual(OshiRequestKind.allCases.map(\.displayName), ["グループ", "作品", "ソロ活動"])

        XCTAssertTrue(OshiGroup(id: UUID(), name: "TWICE", kind: .group).supportsMemberSelection)
        XCTAssertTrue(OshiGroup(id: UUID(), name: "呪術廻戦", kind: .work).supportsMemberSelection)
        XCTAssertFalse(OshiGroup(id: UUID(), name: "IU", kind: .solo).supportsMemberSelection)
    }

    func testBoardAudienceRawValuesMatchDatabase() {
        XCTAssertEqual(BoardThread.Audience.nearby3km.rawValue, "nearby_3km")
        XCTAssertEqual(BoardThread.Audience.samePrefecture.rawValue, "same_prefecture")
        XCTAssertEqual(BoardThread.Audience.sameSpot.rawValue, "same_spot")
        XCTAssertEqual(BoardThread.Audience.global.rawValue, "global")
    }

    func testTradeProposalBuildsCounterProposalInputForReceiver() {
        let senderID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let receiverID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let senderGoodsID = UUID(uuidString: "00000000-0000-0000-0000-000000000101")!
        let receiverGoodsID = UUID(uuidString: "00000000-0000-0000-0000-000000000201")!
        let listingID = UUID(uuidString: "00000000-0000-0000-0000-000000000301")!
        let proposal = TradeProposal(
            id: UUID(),
            senderID: senderID,
            receiverID: receiverID,
            listingID: listingID,
            status: .sent,
            exchangeMethod: .both,
            senderGoodsIDs: [senderGoodsID],
            receiverGoodsIDs: [receiverGoodsID],
            conditionTags: ["終演後OK"]
        )

        let input = proposal.counterProposalInput(
            from: receiverID,
            exchangeMethod: .mail,
            conditionTags: ["即日発送"],
            message: "郵送でお願いします"
        )

        XCTAssertEqual(input?.receiverID, senderID)
        XCTAssertEqual(input?.senderGoodsIDs, [receiverGoodsID])
        XCTAssertEqual(input?.receiverGoodsIDs, [senderGoodsID])
        XCTAssertEqual(input?.exchangeMethod, .mail)
        XCTAssertEqual(input?.conditionTags, ["即日発送"])
        XCTAssertEqual(input?.message, "郵送でお願いします")
        XCTAssertEqual(input?.status, .negotiating)
        XCTAssertEqual(input?.listingID, listingID)
    }

    func testProposalMeetupInputValidatesRequiredLocalExchangeFields() {
        let valid = ProposalMeetupInput(
            startAt: Date(timeIntervalSince1970: 1_000),
            endAt: Date(timeIntervalSince1970: 2_800),
            placeName: " 横浜アリーナ 北口 ",
            latitude: 35.5122,
            longitude: 139.6171
        )
        let invalidPlace = ProposalMeetupInput(
            startAt: valid.startAt,
            endAt: valid.endAt,
            placeName: " ",
            latitude: valid.latitude,
            longitude: valid.longitude
        )
        let invalidRange = ProposalMeetupInput(
            startAt: valid.endAt,
            endAt: valid.startAt,
            placeName: valid.placeName,
            latitude: valid.latitude,
            longitude: valid.longitude
        )

        XCTAssertTrue(valid.isValid)
        XCTAssertEqual(valid.normalizedPlaceName, "横浜アリーナ 北口")
        XCTAssertFalse(invalidPlace.isValid)
        XCTAssertFalse(invalidRange.isValid)
    }

    func testTradeProposalCounterProposalAvailabilityMatchesOpenStatuses() {
        let senderID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let receiverID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let senderGoodsID = UUID(uuidString: "00000000-0000-0000-0000-000000000101")!
        let receiverGoodsID = UUID(uuidString: "00000000-0000-0000-0000-000000000201")!
        let openProposal = TradeProposal(
            id: UUID(),
            senderID: senderID,
            receiverID: receiverID,
            status: .negotiating,
            exchangeMethod: .both,
            senderGoodsIDs: [senderGoodsID],
            receiverGoodsIDs: [receiverGoodsID]
        )
        let agreedProposal = TradeProposal(
            id: UUID(),
            senderID: senderID,
            receiverID: receiverID,
            status: .agreed,
            exchangeMethod: .both,
            senderGoodsIDs: [senderGoodsID],
            receiverGoodsIDs: [receiverGoodsID]
        )

        XCTAssertTrue(openProposal.canCreateCounterProposal(from: receiverID))
        XCTAssertFalse(agreedProposal.canCreateCounterProposal(from: receiverID))
        XCTAssertNil(
            agreedProposal.counterProposalInput(
                from: receiverID,
                exchangeMethod: .mail,
                conditionTags: [],
                message: nil
            )
        )
    }

    func testTradeProposalCounterProposalInputRejectsNonParticipant() {
        let senderID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let receiverID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let outsiderID = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
        let proposal = TradeProposal(
            id: UUID(),
            senderID: senderID,
            receiverID: receiverID,
            status: .sent,
            exchangeMethod: .hand,
            senderGoodsIDs: [UUID()],
            receiverGoodsIDs: [UUID()]
        )

        XCTAssertNil(
            proposal.counterProposalInput(
                from: outsiderID,
                exchangeMethod: .mail,
                conditionTags: [],
                message: nil
            )
        )
    }

    func testPersonalScheduleOverlapBoundary() {
        let schedule = PersonalSchedule(
            id: UUID(),
            userID: UUID(),
            title: "物販列",
            placeName: "北口",
            startAt: Date(timeIntervalSince1970: 1_000),
            endAt: Date(timeIntervalSince1970: 2_000)
        )

        XCTAssertTrue(
            schedule.overlaps(
                start: Date(timeIntervalSince1970: 1_500),
                end: Date(timeIntervalSince1970: 2_500)
            )
        )
        XCTAssertFalse(
            schedule.overlaps(
                start: Date(timeIntervalSince1970: 2_000),
                end: Date(timeIntervalSince1970: 3_000)
            )
        )
        XCTAssertEqual(schedule.durationInterval.duration, 1_000)
    }

    func testPersonalScheduleCreateInputNormalizesAndValidates() {
        let start = Date(timeIntervalSince1970: 1_000)
        let end = Date(timeIntervalSince1970: 2_000)
        let input = PersonalScheduleCreateInput(
            title: " 物販列 ",
            placeName: " 北口 ",
            startAt: start,
            endAt: end,
            note: " 友達と合流 "
        )

        XCTAssertTrue(input.isValid)
        XCTAssertEqual(input.normalizedTitle, "物販列")
        XCTAssertEqual(input.normalizedPlaceName, "北口")
        XCTAssertEqual(input.normalizedNote, "友達と合流")

        let invalid = PersonalScheduleCreateInput(title: " ", startAt: end, endAt: start)
        XCTAssertFalse(invalid.isValid)
        XCTAssertTrue(invalid.normalizedTitle.isEmpty)
    }
}
