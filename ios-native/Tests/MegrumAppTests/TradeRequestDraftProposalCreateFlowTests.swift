@testable import MegrumApp
import MegrumCore
import XCTest

final class TradeRequestDraftProposalCreateFlowTests: XCTestCase {
    func testProposalCreationPolicyRequiresMeetupForOnsiteMethods() {
        for method in [ExchangeMethod.hand, .both] {
            let configuration = ProposalCreateConfiguration(
                exchangeMethod: method,
                hasSelectedSenderGoods: true,
                isCreatingProposal: false,
                hasReadyMailingAddress: method == .both,
                isLoadingMailingAddress: false,
                hasValidMeetup: false,
                receiverGoodsCount: 1,
                isListingSource: false
            )

            XCTAssertTrue(configuration.requiresMeetupBeforeSubmit)
            XCTAssertNil(configuration.targetStatus)
            XCTAssertFalse(configuration.canSubmit)
            XCTAssertEqual(configuration.submitTitle, "待ち合わせ入力が必要")
        }
    }

    func testProposalCreationPolicyRequiresAddressForMailingMethods() {
        for method in [ExchangeMethod.mail, .both] {
            let configuration = ProposalCreateConfiguration(
                exchangeMethod: method,
                hasSelectedSenderGoods: true,
                isCreatingProposal: false,
                hasReadyMailingAddress: false,
                isLoadingMailingAddress: false,
                hasValidMeetup: method == .both,
                receiverGoodsCount: 1,
                isListingSource: false
            )

            XCTAssertTrue(configuration.requiresMailingAddressBeforeSubmit)
            XCTAssertNil(configuration.targetStatus)
            XCTAssertFalse(configuration.canSubmit)
            XCTAssertEqual(configuration.submitTitle, "住所登録が必要")
        }
    }

    func testProposalCreationPolicyAllowsBothOnlyWhenAddressAndMeetupAreReady() {
        let configuration = ProposalCreateConfiguration(
            exchangeMethod: .both,
            hasSelectedSenderGoods: true,
            isCreatingProposal: false,
            hasReadyMailingAddress: true,
            isLoadingMailingAddress: false,
            hasValidMeetup: true,
            receiverGoodsCount: 2,
            isListingSource: true
        )

        XCTAssertEqual(configuration.targetStatus, .sent)
        XCTAssertTrue(configuration.canSubmit)
        XCTAssertEqual(
            configuration.conditionTagOptions,
            ["即日発送", "同日発送", "開演前OK", "終演後OK", "グッズ販売中OK", "短時間OK", "同種優先"]
        )
        XCTAssertEqual(configuration.targetSubtitle, "個別募集から選択")
        XCTAssertEqual(configuration.targetSupplement, "ほか1件も受け取る条件です")
    }

    func testProposalCandidateGridUsesTwoColumnsOnPhoneWidth() {
        XCTAssertEqual(ProposalCandidateGridMetrics.estimatedColumnCount(containerWidth: 155), 1)
        XCTAssertEqual(ProposalCandidateGridMetrics.estimatedColumnCount(containerWidth: 350), 2)
        XCTAssertEqual(ProposalCandidateGridMetrics.estimatedColumnCount(containerWidth: 520), 3)
    }

    func testProposalMeetupMapDraftParsesAndBoundsCoordinates() throws {
        let coordinate = try XCTUnwrap(
            ProposalMeetupMapDraft.coordinate(
                latitudeText: " 35.681236 ",
                longitudeText: " 139.767125 "
            )
        )

        XCTAssertEqual(coordinate.latitude, 35.681236, accuracy: 0.000001)
        XCTAssertEqual(coordinate.longitude, 139.767125, accuracy: 0.000001)
        XCTAssertEqual(ProposalMeetupMapDraft.coordinateText(139.7671254), "139.767125")
        XCTAssertNil(ProposalMeetupMapDraft.coordinate(latitudeText: "91", longitudeText: "139.767125"))
        XCTAssertNil(ProposalMeetupMapDraft.coordinate(latitudeText: "35.681236", longitudeText: "-181"))
    }

    func testProposalMeetupCandidateDraftBuildsSelectedLocalMeetup() throws {
        let start = Date(timeIntervalSince1970: 1_000)
        let candidate = ProposalMeetupCandidateDraft(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000501")!,
            startAt: start,
            endAt: start.addingTimeInterval(1_800),
            placeName: " 横浜アリーナ 北口 ",
            latitudeText: "35.512200",
            longitudeText: "139.617100"
        )

        let meetup = try XCTUnwrap(candidate.meetupInput)

        XCTAssertTrue(candidate.isValid)
        XCTAssertEqual(meetup.normalizedPlaceName, "横浜アリーナ 北口")
        XCTAssertEqual(meetup.latitude, 35.5122, accuracy: 0.000001)
        XCTAssertEqual(meetup.longitude, 139.6171, accuracy: 0.000001)
        XCTAssertTrue(candidate.summary(index: 1).contains("候補2"))
        XCTAssertEqual(ProposalMeetupCandidateDraft.maxCandidates, 3)
    }

    func testProposalMeetupCandidateDraftAppliesCurrentLocationWithoutOverwritingPlace() {
        let coordinate = MegrumLocationCoordinate(latitude: 35.681236, longitude: 139.767125)
        let emptyPlace = ProposalMeetupCandidateDraft().applyingCurrentLocation(coordinate)
        let namedPlace = ProposalMeetupCandidateDraft(placeName: "会場ロビー").applyingCurrentLocation(coordinate)

        XCTAssertEqual(emptyPlace.placeName, "現在地")
        XCTAssertEqual(emptyPlace.latitudeText, "35.681236")
        XCTAssertEqual(emptyPlace.longitudeText, "139.767125")
        XCTAssertEqual(namedPlace.placeName, "会場ロビー")
    }

    func testProposalScheduleContextFiltersDedupesAndFindsSelectedOverlap() throws {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000101")!
        let partnerID = UUID(uuidString: "00000000-0000-0000-0000-000000000202")!
        let otherID = UUID(uuidString: "00000000-0000-0000-0000-000000000303")!
        let duplicatedID = UUID(uuidString: "00000000-0000-0000-0000-000000000401")!
        let start = Date(timeIntervalSince1970: 1_000)
        let end = Date(timeIntervalSince1970: 2_000)

        let viewerSchedule = PersonalSchedule(
            id: duplicatedID,
            userID: viewerID,
            title: "物販列",
            placeName: "北口",
            startAt: start,
            endAt: end
        )
        let partnerSchedule = PersonalSchedule(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000402")!,
            userID: partnerID,
            title: "開演前準備",
            placeName: "会場ロビー",
            startAt: Date(timeIntervalSince1970: 2_400),
            endAt: Date(timeIntervalSince1970: 3_000)
        )
        let unrelatedSchedule = PersonalSchedule(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000403")!,
            userID: otherID,
            title: "別ユーザー予定",
            startAt: start,
            endAt: end
        )

        let context = ProposalScheduleContext(
            schedules: [partnerSchedule, viewerSchedule, unrelatedSchedule, viewerSchedule],
            viewerID: viewerID,
            partnerID: partnerID,
            selectedStartAt: Date(timeIntervalSince1970: 1_500),
            selectedEndAt: Date(timeIntervalSince1970: 1_800)
        )

        XCTAssertEqual(context.schedules.map(\.id), [duplicatedID, partnerSchedule.id])
        XCTAssertEqual(context.selectedOverlaps.map(\.id), [duplicatedID])
        XCTAssertEqual(context.roleText(for: viewerSchedule), "あなた")
        XCTAssertEqual(context.roleText(for: partnerSchedule), "相手")
        XCTAssertEqual(context.placeSuggestions, ["北口", "会場ロビー"])

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        XCTAssertEqual(
            context.visibleDays(anchorDate: start, mode: .fiveDays, calendar: calendar).count,
            5
        )
        XCTAssertEqual(context.schedules(on: start, calendar: calendar).map(\.id), [duplicatedID, partnerSchedule.id])
    }
}
