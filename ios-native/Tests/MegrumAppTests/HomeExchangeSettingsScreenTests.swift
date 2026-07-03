import Foundation
import CoreGraphics
import MegrumCore
@testable import MegrumApp
import XCTest

final class HomeExchangeSettingsScreenTests: XCTestCase {
    func testHomeExchangeSettingsDraftStateLoadsStoredValuesOnlyOnceAndDropsUnsetDateDetails() {
        let selectedKeys = ["2026-07-03", "2026-07-04"]
        let encodedDetails = HomeExchangeLocalDateDetailCodec.encode([
            "2026-07-03": HomeExchangeLocalDateDetail(prefecture: "", memo: "未設定"),
            "2026-07-04": HomeExchangeLocalDateDetail(prefecture: "東京都", memo: "渋谷")
        ])
        var state = HomeExchangeSettingsDraftState()

        state.loadIfNeeded(
            storedPreferenceRawValue: HomeExchangePreference.local.rawValue,
            storedLocalPrefecture: "",
            storedLocalDateKeysRawValue: HomeExchangeDateKey.rawValue(from: selectedKeys),
            storedLocalDateDetailsRawValue: encodedDetails,
            storedMailShippingFeeRawValue: IndividualListingShippingFeeDraft.owner.rawValue,
            storedMailShippingDaysRawValue: IndividualListingShippingDaysDraft.oneDay.rawValue,
            isListingReflectedDate: { _ in false },
            now: makeDate(year: 2026, month: 6, day: 25)
        )

        XCTAssertTrue(state.didLoadDraft)
        XCTAssertEqual(state.preference, .local)
        XCTAssertEqual(state.localDateKeys, ["2026-07-04"])
        XCTAssertEqual(state.localDateDetails["2026-07-04"]?.prefecture, "東京都")
        XCTAssertNil(state.localDateDetails["2026-07-03"])
        XCTAssertEqual(state.mailShippingFee, .owner)
        XCTAssertEqual(state.mailShippingDays, .oneDay)
        XCTAssertEqual(
            state.visibleMonth,
            HomeExchangeCalendarMonthBuilder.monthStart(containing: makeDate(year: 2026, month: 7, day: 4))
        )

        state.loadIfNeeded(
            storedPreferenceRawValue: HomeExchangePreference.mail.rawValue,
            storedLocalPrefecture: "大阪府",
            storedLocalDateKeysRawValue: "",
            storedLocalDateDetailsRawValue: "",
            storedMailShippingFeeRawValue: IndividualListingShippingFeeDraft.partner.rawValue,
            storedMailShippingDaysRawValue: IndividualListingShippingDaysDraft.afterFiveDays.rawValue,
            isListingReflectedDate: { _ in false },
            now: makeDate(year: 2026, month: 8, day: 1)
        )

        XCTAssertEqual(state.preference, .local)
        XCTAssertEqual(state.localDateKeys, ["2026-07-04"])
    }

    func testHomeExchangeSettingsDraftStateProtectsUserEditsFromRemoteRefresh() {
        var state = HomeExchangeSettingsDraftState()
        let initialRemote = HomeDefaultExchangeSettings(
            preference: .local,
            localPrefecture: "東京都",
            localDateKeys: ["2026-07-04"],
            localDateDetails: [
                "2026-07-04": HomeExchangeLocalDateDetail(prefecture: "東京都", memo: "渋谷")
            ],
            mailShippingFee: .owner,
            mailShippingDays: .oneDay
        )
        let laterRemote = HomeDefaultExchangeSettings(
            preference: .mail,
            localPrefecture: "大阪府",
            localDateKeys: ["2026-08-01"],
            mailShippingFee: .partner,
            mailShippingDays: .afterFiveDays
        )

        XCTAssertTrue(state.applyRemoteSettingsIfPossible(initialRemote))
        XCTAssertEqual(state.preference, .local)
        XCTAssertEqual(state.localPrefecture, "東京都")

        state.selectPreference(.both)
        XCTAssertTrue(state.hasUserEditedDraft)
        XCTAssertFalse(state.applyRemoteSettingsIfPossible(laterRemote))
        XCTAssertEqual(state.preference, .both)
        XCTAssertEqual(state.localPrefecture, "東京都")

        state.markSaveSucceeded()
        XCTAssertFalse(state.hasUserEditedDraft)
        XCTAssertTrue(state.applyRemoteSettingsIfPossible(laterRemote))
        XCTAssertEqual(state.preference, .mail)
        XCTAssertEqual(state.localPrefecture, "大阪府")
    }

    func testHomeExchangeSettingsDraftStateDateSelectionKeepsReflectedDatesReadOnly() {
        let reflectedKey = "2026-07-03"
        let editableKey = "2026-07-04"
        var state = HomeExchangeSettingsDraftState()

        state.finishDragSelection(
            [
                makeCalendarDay(key: reflectedKey),
                makeCalendarDay(key: editableKey)
            ],
            isListingReflectedDate: { $0 == reflectedKey }
        )

        XCTAssertTrue(state.hasUserEditedDraft)
        XCTAssertEqual(state.localDateKeys, [editableKey])
        XCTAssertEqual(state.editingDate?.dateKeys, [editableKey])

        state.localDateKeys.insert(reflectedKey)
        state.localDateDetails[reflectedKey] = HomeExchangeLocalDateDetail(prefecture: "東京都", memo: "個別募集")
        state.removeDateDetail([reflectedKey, editableKey], isListingReflectedDate: { $0 == reflectedKey })

        XCTAssertTrue(state.localDateKeys.contains(reflectedKey))
        XCTAssertFalse(state.localDateKeys.contains(editableKey))
    }

    func testHomeExchangeLocalDateDetailEditorStateTrimsSaveDetailAndTracksCancel() {
        var state = HomeExchangeLocalDateDetailEditorState(
            detail: HomeExchangeLocalDateDetail(prefecture: " 東京都 ", memo: " 渋谷駅付近 ")
        )

        XCTAssertTrue(state.shouldCancelOnDisappear(isReadOnly: false))
        XCTAssertFalse(state.shouldCancelOnDisappear(isReadOnly: true))
        XCTAssertEqual(state.detailForSave.prefecture, "東京都")
        XCTAssertEqual(state.detailForSave.memo, "渋谷駅付近")

        state.markFinished()
        XCTAssertFalse(state.shouldCancelOnDisappear(isReadOnly: false))
    }

    func testCalendarDragSelectionAllowsOnlyHorizontalSameRow() {
        XCTAssertTrue(
            HomeExchangeCalendarDragSelectionPolicy.allowsSelection(
                startIndex: 8,
                endIndex: 11,
                translation: CGSize(width: 90, height: 10)
            )
        )

        XCTAssertFalse(
            HomeExchangeCalendarDragSelectionPolicy.allowsSelection(
                startIndex: 8,
                endIndex: 15,
                translation: CGSize(width: 90, height: 10)
            )
        )

        XCTAssertFalse(
            HomeExchangeCalendarDragSelectionPolicy.allowsSelection(
                startIndex: 8,
                endIndex: 11,
                translation: CGSize(width: 10, height: 90)
            )
        )
    }

    func testCalendarDragSelectionResolverKeepsAccumulatedDatesWhenFinalRangeShrinks() {
        let visibleKeys = [
            "2026-06-01",
            "2026-06-02",
            "2026-06-03",
            "2026-06-04",
            "2026-06-05"
        ]

        let resolvedKeys = HomeExchangeCalendarDragSelectionResolver.resolvedKeys(
            accumulatedKeys: ["2026-06-03", "2026-06-04"],
            finalKeys: ["2026-06-01", "2026-06-02"],
            visibleKeys: visibleKeys
        )

        XCTAssertEqual(
            resolvedKeys,
            ["2026-06-01", "2026-06-02", "2026-06-03", "2026-06-04"]
        )
    }

    func testCalendarDragPreviewStateAccumulatesAndClearsResolvedDays() {
        let visibleDays = [
            makeCalendarDay(key: "2026-06-01"),
            makeCalendarDay(key: "2026-06-02"),
            makeCalendarDay(key: "2026-06-03"),
            makeCalendarDay(key: "2026-06-04"),
            makeCalendarDay(key: "2026-06-05")
        ]
        var state = HomeExchangeCalendarDragPreviewState()

        state.updatePreview(
            finalDays: Array(visibleDays[1...2]),
            visibleDays: visibleDays
        )

        XCTAssertEqual(state.dragPreviewKeys, ["2026-06-02", "2026-06-03"])
        XCTAssertEqual(
            state.activeSelectedDateKeys(selectedDateKeys: ["2026-06-05"]),
            ["2026-06-02", "2026-06-03", "2026-06-05"]
        )

        state.updatePreview(finalDays: [visibleDays[0]], visibleDays: visibleDays)

        XCTAssertEqual(state.dragPreviewKeys, ["2026-06-01", "2026-06-02", "2026-06-03"])

        let selectedDays = state.finishDragSelection(
            finalDays: [visibleDays[3]],
            visibleDays: visibleDays
        )

        XCTAssertEqual(selectedDays.map(\.key), ["2026-06-01", "2026-06-02", "2026-06-03", "2026-06-04"])
        XCTAssertTrue(state.dragPreviewKeys.isEmpty)
    }

    func testReflectedListingConditionsUseMultipleMemoMessageForSameDate() {
        let now = makeDate(year: 2026, month: 6, day: 25)
        let listings = [
            makeListing(localPrefecture: "東京都", localPlaceMemo: "東京駅付近", localSchedule: "6/28"),
            makeListing(localPrefecture: "東京都", localPlaceMemo: "渋谷で相談", localSchedule: "6/28")
        ]

        let details = HomeExchangeListingConditionReflector.reflectedDetails(
            from: listings,
            calendar: makeCalendar(),
            now: now
        )

        XCTAssertEqual(details["2026-06-28"]?.prefecture, "東京都")
        XCTAssertEqual(details["2026-06-28"]?.memo, HomeExchangeListingConditionReflector.multipleMemoText)
    }

    func testReflectedListingConditionsIgnoreConsultSchedules() {
        let listing = makeListing(
            localPrefecture: "東京都",
            localPlaceMemo: "東京駅付近",
            localSchedule: IndividualListingExchangeSummary.defaultLocalSchedule
        )

        let details = HomeExchangeListingConditionReflector.reflectedDetails(
            from: [listing],
            calendar: makeCalendar(),
            now: makeDate(year: 2026, month: 6, day: 25)
        )

        XCTAssertTrue(details.isEmpty)
    }

    func testDefaultExchangeSettingsBuildListingSummaryFromConfiguredDefault() {
        let settings = HomeDefaultExchangeSettings(
            preference: .local,
            localPrefecture: "大阪府",
            localDateKeys: ["2026-07-01", "2026-07-03"],
            mailShippingFee: .owner,
            mailShippingDays: .oneDay
        )

        let summary = settings.makeListingExchangeSummary(
            now: makeDate(year: 2026, month: 6, day: 27)
        )

        XCTAssertEqual(summary.handoffMethod, .local)
        XCTAssertEqual(summary.localPrefecture, "大阪府")
        XCTAssertEqual(summary.localSchedule, "7/1、7/3")
        XCTAssertEqual(summary.shippingFee, .owner)
        XCTAssertEqual(summary.shippingDays, .oneDay)
    }

    private func makeListing(
        localPrefecture: String,
        localPlaceMemo: String,
        localSchedule: String,
        status: IndividualListingStatus = .active
    ) -> IndividualListing {
        let summary = IndividualListingExchangeSummary(
            handoffMethod: .local,
            localPrefecture: localPrefecture,
            localPlaceMemo: localPlaceMemo,
            localSchedule: localSchedule
        )
        return IndividualListing(
            id: UUID(),
            ownerID: UUID(),
            haves: [],
            status: status,
            note: summary.storageLine
        )
    }

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        makeCalendar().date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    private func makeCalendarDay(key: String) -> HomeExchangeCalendarDay {
        let date = HomeExchangeDateKey.date(from: key) ?? makeDate(year: 2026, month: 7, day: 1)
        return HomeExchangeCalendarDay(
            date: date,
            key: key,
            isInDisplayedMonth: true,
            weekdaySymbol: "水",
            dayNumber: 1,
            monthNumber: 7
        )
    }

    private func makeCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return calendar
    }
}
