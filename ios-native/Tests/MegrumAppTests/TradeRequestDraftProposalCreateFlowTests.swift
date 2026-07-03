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

    func testProposalCandidateListStaysSingleColumnLikeRnFlatList() {
        XCTAssertEqual(ProposalCandidateListMetrics.estimatedColumnCount(containerWidth: 155), 1)
        XCTAssertEqual(ProposalCandidateListMetrics.estimatedColumnCount(containerWidth: 350), 1)
        XCTAssertEqual(ProposalCandidateListMetrics.estimatedColumnCount(containerWidth: 520), 1)
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
        XCTAssertEqual(ProposalMeetupCandidateDraft.maxCandidates, 5)
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

    func testProposalMeetupCurrentLocationDraftResolverRequiresMeetupAndCoordinate() {
        let coordinate = MegrumLocationCoordinate(latitude: 35.681236, longitude: 139.767125)
        let draft = ProposalMeetupCandidateDraft(placeName: "会場ロビー")

        XCTAssertNil(
            ProposalMeetupCurrentLocationDraftResolver.resolvedDraft(
                currentDraft: draft,
                coordinate: coordinate,
                requiresMeetupBeforeSubmit: false
            )
        )
        XCTAssertNil(
            ProposalMeetupCurrentLocationDraftResolver.resolvedDraft(
                currentDraft: draft,
                coordinate: nil,
                requiresMeetupBeforeSubmit: true
            )
        )

        let resolved = ProposalMeetupCurrentLocationDraftResolver.resolvedDraft(
            currentDraft: draft,
            coordinate: coordinate,
            requiresMeetupBeforeSubmit: true
        )

        XCTAssertEqual(resolved?.placeName, "会場ロビー")
        XCTAssertEqual(resolved?.latitudeText, "35.681236")
        XCTAssertEqual(resolved?.longitudeText, "139.767125")
    }

    func testProposalMeetupCandidateSelectionReducerKeepsExpectedIndexAfterRemoval() {
        XCTAssertEqual(
            ProposalMeetupCandidateSelectionReducer.selectedIndexAfterRemoving(
                removedIndex: 0,
                selectedIndex: 2,
                remainingCount: 3
            ),
            1
        )
        XCTAssertEqual(
            ProposalMeetupCandidateSelectionReducer.selectedIndexAfterRemoving(
                removedIndex: 1,
                selectedIndex: 1,
                remainingCount: 2
            ),
            1
        )
        XCTAssertEqual(
            ProposalMeetupCandidateSelectionReducer.selectedIndexAfterRemoving(
                removedIndex: 2,
                selectedIndex: 0,
                remainingCount: 2
            ),
            0
        )
        XCTAssertNil(
            ProposalMeetupCandidateSelectionReducer.selectedIndexAfterRemoving(
                removedIndex: 0,
                selectedIndex: 0,
                remainingCount: 0
            )
        )
    }

    func testProposalMeetupPlaceDraftResolverFindsLatestPreviousReusableDraft() throws {
        let resolved = try XCTUnwrap(
            ProposalMeetupPlaceDraftResolver.previousReusableDraft(
                before: 3,
                in: [
                    ProposalMeetupCandidateDraft(placeName: " 北口 "),
                    ProposalMeetupCandidateDraft(placeName: " "),
                    ProposalMeetupCandidateDraft(placeName: " 南口 "),
                    ProposalMeetupCandidateDraft(placeName: " 現在の候補 ")
                ]
            )
        )

        XCTAssertEqual(resolved.normalizedPlaceName, "南口")
    }

    func testProposalMeetupPlaceDraftResolverUsesCoordinateOnlyDraft() throws {
        let resolved = try XCTUnwrap(
            ProposalMeetupPlaceDraftResolver.previousReusableDraft(
                before: 2,
                in: [
                    ProposalMeetupCandidateDraft(latitudeText: "not", longitudeText: "139.1"),
                    ProposalMeetupCandidateDraft(latitudeText: "35.681236", longitudeText: "139.767125"),
                    ProposalMeetupCandidateDraft(placeName: "現在の候補")
                ]
            )
        )

        XCTAssertEqual(resolved.latitudeText, "35.681236")
        XCTAssertEqual(resolved.longitudeText, "139.767125")
    }

    func testProposalMeetupPlaceDraftResolverIgnoresCurrentAndInvalidDrafts() {
        let resolved = ProposalMeetupPlaceDraftResolver.previousReusableDraft(
            before: 1,
            in: [
                ProposalMeetupCandidateDraft(placeName: " ", latitudeText: "91", longitudeText: "139.1"),
                ProposalMeetupCandidateDraft(placeName: "現在の候補")
            ]
        )

        XCTAssertNil(resolved)
    }

    func testProposalScheduleTextDateParserParsesSupportedLocalScheduleFormats() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current
        let now = try XCTUnwrap(
            calendar.date(from: DateComponents(year: 2026, month: 6, day: 30, hour: 10))
        )

        for sample in ["6月7日", "6/7", "6.7", " 6月7日　"] {
            let date = try XCTUnwrap(ProposalScheduleTextDateParser.date(from: sample, now: now))
            let components = calendar.dateComponents([.year, .month, .day, .hour], from: date)

            XCTAssertEqual(components.year, 2026)
            XCTAssertEqual(components.month, 6)
            XCTAssertEqual(components.day, 7)
            XCTAssertEqual(components.hour, 12)
        }
    }

    func testProposalScheduleTextDateParserIgnoresBlankDefaultAndUnsupportedText() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current
        let now = calendar.date(from: DateComponents(year: 2026, month: 6, day: 30, hour: 10)) ?? Date()

        XCTAssertNil(ProposalScheduleTextDateParser.date(from: " ", now: now))
        XCTAssertNil(ProposalScheduleTextDateParser.date(from: IndividualListingExchangeSummary.defaultLocalSchedule, now: now))
        XCTAssertNil(ProposalScheduleTextDateParser.date(from: "来週あたり", now: now))
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

    func testProposalScheduleBackgroundPresentationStateTracksVisibleMode() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let anchor = try XCTUnwrap(
            DateComponents(calendar: calendar, timeZone: calendar.timeZone, year: 2026, month: 6, day: 5).date
        )
        let context = ProposalScheduleContext(
            schedules: [],
            viewerID: nil,
            partnerID: UUID(uuidString: "00000000-0000-0000-0000-000000000202")!,
            selectedStartAt: anchor,
            selectedEndAt: anchor.addingTimeInterval(1_800)
        )

        var state = ProposalScheduleBackgroundPresentationState()

        XCTAssertEqual(state.mode, .fiveDays)
        XCTAssertEqual(state.visibleDays(context: context, anchorDate: anchor, calendar: calendar).count, 5)

        state.mode = .month

        XCTAssertEqual(state.visibleDays(context: context, anchorDate: anchor, calendar: calendar).count, 30)
    }

    func testProposalMeetupCalendarModelShiftsWeekByFiveDays() {
        let calendar = Calendar(identifier: .gregorian)
        let anchor = Date(timeIntervalSince1970: 86_400 * 3)

        let shifted = ProposalMeetupCalendarModel.shiftedAnchor(anchorDate: anchor, direction: 1, calendar: calendar)

        XCTAssertEqual(
            Int(shifted.timeIntervalSince(calendar.startOfDay(for: anchor)) / 86_400),
            5
        )
        XCTAssertEqual(ProposalMeetupCalendarModel.visibleDayCount, 5)
        XCTAssertEqual(ProposalMeetupCalendarModel.monthColumnCount, 7)
    }

    func testProposalMeetupCalendarDisplayStateUsesVisualQAMonthAndReturnsToWeek() {
        var state = ProposalMeetupCalendarDisplayState(
            environment: ["MEGRUM_VISUAL_QA_INITIAL_SCREEN": "proposal-meetup-month"]
        )

        XCTAssertEqual(state.displayMode, .month)
        XCTAssertFalse(state.showsWeekTitle)

        state.showWeek()

        XCTAssertEqual(state.displayMode, .week)
        XCTAssertTrue(state.showsWeekTitle)

        XCTAssertEqual(ProposalMeetupCalendarDisplayState(environment: [:]).displayMode, .week)
    }

    func testProposalMeetupCalendarMonthGridPadsToSevenColumns() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let components = DateComponents(calendar: calendar, timeZone: calendar.timeZone, year: 2026, month: 6, day: 5)
        let anchor = try XCTUnwrap(components.date)

        let days = ProposalMeetupCalendarModel.monthGridDays(anchorDate: anchor, calendar: calendar)
        let concreteDays = days.compactMap { $0 }

        XCTAssertEqual(days.count % 7, 0)
        XCTAssertEqual(concreteDays.count, 30)
        XCTAssertEqual(calendar.component(.day, from: try XCTUnwrap(concreteDays.first)), 1)
        XCTAssertEqual(calendar.component(.day, from: try XCTUnwrap(concreteDays.last)), 30)
        XCTAssertTrue(days.indices.contains(0))
        XCTAssertNil(days[0])
    }

    func testProposalMeetupCalendarMonthNavigationUsesYearMonthTitle() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let anchor = try XCTUnwrap(DateComponents(calendar: calendar, timeZone: calendar.timeZone, year: 2026, month: 1, day: 31).date)

        XCTAssertEqual(ProposalMeetupCalendarModel.monthTitle(anchorDate: anchor, calendar: calendar), "2026年1月")

        let nextMonth = ProposalMeetupCalendarModel.shiftedMonthAnchor(anchorDate: anchor, direction: 1, calendar: calendar)
        XCTAssertEqual(ProposalMeetupCalendarModel.monthTitle(anchorDate: nextMonth, calendar: calendar), "2026年2月")
        XCTAssertEqual(calendar.component(.day, from: nextMonth), 1)

        let previousMonth = ProposalMeetupCalendarModel.shiftedMonthAnchor(anchorDate: anchor, direction: -1, calendar: calendar)
        XCTAssertEqual(ProposalMeetupCalendarModel.monthTitle(anchorDate: previousMonth, calendar: calendar), "2025年12月")
        XCTAssertEqual(calendar.component(.day, from: previousMonth), 1)
    }

    func testProposalMeetupMonthGridUsesRnPercentCellsWithSlightViewportOverflow() {
        let containerWidth: CGFloat = 353
        let cellWidth = ProposalMeetupCalendarModel.monthDayCellWidth(containerWidth: containerWidth)
        let gridWidth = ProposalMeetupCalendarModel.monthGridWidth(containerWidth: containerWidth)

        XCTAssertEqual(cellWidth, 48)
        XCTAssertEqual(gridWidth, 360)
        XCTAssertGreaterThan(gridWidth, containerWidth)
        XCTAssertEqual(ProposalMeetupCalendarModel.monthGridHeight(rowCount: 6), 524)
    }

    func testProposalMeetupWeekGridUsesRnCalendarMetrics() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = try XCTUnwrap(DateComponents(calendar: calendar, timeZone: calendar.timeZone, year: 2026, month: 6, day: 5).date)
        let containerWidth: CGFloat = 353
        let dayWidth = ProposalMeetupCalendarModel.dayWidth(containerWidth: containerWidth)
        let gridWidth = ProposalMeetupCalendarModel.weekGridWidth(dayWidth: dayWidth)

        XCTAssertLessThanOrEqual(gridWidth, containerWidth)
        XCTAssertEqual(dayWidth, 62)
        XCTAssertEqual(gridWidth, 350)
        XCTAssertEqual(ProposalMeetupCalendarModel.weekDayColumnsWidth(dayWidth: dayWidth), 310)
        XCTAssertEqual(ProposalMeetupCalendarModel.slotHeight, 16)
        XCTAssertEqual(ProposalMeetupCalendarModel.timeLabelWidth, 40)
        XCTAssertEqual(ProposalMeetupCalendarModel.daySpacing, 0)
        XCTAssertEqual(ProposalMeetupCalendarModel.weekdayLabel(for: date, calendar: calendar), "金")
        XCTAssertEqual(ProposalMeetupCalendarModel.dayNumberLabel(for: date, calendar: calendar), "5")
    }

    func testProposalMeetupWeekSwipeFollowsFingerAndUsesRnThreshold() {
        let containerWidth: CGFloat = 353

        XCTAssertEqual(
            ProposalMeetupCalendarModel.clampedWeekDragOffset(200, containerWidth: containerWidth),
            containerWidth * ProposalMeetupCalendarModel.edgeCarryRatio,
            accuracy: 0.001
        )
        XCTAssertEqual(
            ProposalMeetupCalendarModel.clampedWeekDragOffset(-40, containerWidth: containerWidth),
            -40,
            accuracy: 0.001
        )
        XCTAssertFalse(
            ProposalMeetupCalendarModel.shouldShiftWeek(
                translationWidth: 44,
                translationHeight: 2,
                containerWidth: containerWidth
            )
        )
        XCTAssertTrue(
            ProposalMeetupCalendarModel.shouldShiftWeek(
                translationWidth: -90,
                translationHeight: 10,
                containerWidth: containerWidth
            )
        )
        XCTAssertFalse(
            ProposalMeetupCalendarModel.shouldShiftWeek(
                translationWidth: 120,
                translationHeight: 110,
                containerWidth: containerWidth
            )
        )
    }

    func testProposalMeetupCalendarHourSlotIndexSupportsOverlayPlacement() {
        XCTAssertEqual(ProposalMeetupCalendarModel.slotIndex(forHour: 12), 48)
        XCTAssertEqual(ProposalMeetupCalendarModel.slotIndex(forHour: -1), 0)
        XCTAssertEqual(ProposalMeetupCalendarModel.slotIndex(forHour: 30), ProposalMeetupCalendarModel.slotCount - 1)
    }

    func testProposalMeetupCalendarCreatesDefaultCandidateOnTapOrLongPress() {
        XCTAssertTrue(ProposalMeetupCalendarModel.shouldCreateCandidateOnBoardEnd(wasLongPressed: false))
        XCTAssertTrue(ProposalMeetupCalendarModel.shouldCreateCandidateOnBoardEnd(wasLongPressed: true))
        XCTAssertEqual(ProposalMeetupCalendarModel.longPressDuration, 0.28, accuracy: 0.001)
        XCTAssertEqual(ProposalMeetupCalendarModel.defaultDurationSlots, 4)
        XCTAssertEqual(
            ProposalMeetupCalendarModel.defaultDurationSlots * ProposalMeetupCalendarModel.slotMinutes,
            60
        )
    }

    func testProposalMeetupCalendarDragSelectionNormalizesDraggedDuration() {
        let downwardRange = ProposalMeetupCalendarModel.normalizedSlotRange(startSlot: 40, currentSlot: 46)
        XCTAssertEqual(downwardRange.lowerBound, 40)
        XCTAssertEqual(downwardRange.upperBound, 47)

        let upwardRange = ProposalMeetupCalendarModel.normalizedSlotRange(startSlot: 40, currentSlot: 34)
        XCTAssertEqual(upwardRange.lowerBound, 34)
        XCTAssertEqual(upwardRange.upperBound, 41)
    }

    func testProposalMeetupCalendarPointMapsCenteredWeekColumnsToDays() {
        let containerWidth: CGFloat = 353
        let dayWidth = ProposalMeetupCalendarModel.dayWidth(containerWidth: containerWidth)
        let gridInset = ProposalMeetupCalendarModel.weekGridLeadingInset(
            containerWidth: containerWidth,
            dayWidth: dayWidth
        )
        let targetX = gridInset
            + ProposalMeetupCalendarModel.timeLabelWidth
            + dayWidth * 2
            + dayWidth / 2
        let targetY = ProposalMeetupCalendarModel.slotHeight * 48 + 1

        let point = ProposalMeetupCalendarModel.weekCalendarPoint(
            from: CGPoint(x: targetX, y: targetY),
            containerWidth: containerWidth,
            dayWidth: dayWidth
        )

        XCTAssertEqual(gridInset, 1.5, accuracy: 0.001)
        XCTAssertEqual(point.dayIndex, 2)
        XCTAssertEqual(point.slot, 48)
    }

    func testProposalMeetupCandidateDraftApplyingCalendarRangeRewritesDates() {
        let calendar = Calendar(identifier: .gregorian)
        let day = Date(timeIntervalSince1970: 86_400 * 10)
        let base = ProposalMeetupCandidateDraft(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000601")!,
            startAt: Date(timeIntervalSince1970: 120),
            endAt: Date(timeIntervalSince1970: 240),
            placeName: "北口"
        )

        let updated = base.applyingCalendarRange(
            day: day,
            startSlot: 8,
            endSlot: 12,
            calendar: calendar
        )

        XCTAssertEqual(ProposalMeetupCalendarModel.slotIndex(for: updated.startAt, calendar: calendar), 8)
        XCTAssertEqual(ProposalMeetupCalendarModel.slotIndex(for: updated.endAt, calendar: calendar), 12)
        XCTAssertEqual(calendar.startOfDay(for: updated.startAt), calendar.startOfDay(for: day))
        XCTAssertEqual(updated.placeName, "北口")
    }
}
