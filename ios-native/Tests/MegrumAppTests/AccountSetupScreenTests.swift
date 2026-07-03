@testable import MegrumApp
import MegrumCore
import XCTest

final class AccountSetupScreenTests: XCTestCase {
    func testAccountSetupDraftValidatorRequiresDisplayName() {
        let message = AccountSetupDraftValidator.validationMessage(
            displayName: " ",
            handle: "michirion",
            prefecture: "東京都",
            birthDate: Date(timeIntervalSince1970: 0),
            gender: .female,
            oshiSelections: [makeOshiInput()]
        )

        XCTAssertEqual(message, AccountSetupDraftValidator.missingDisplayNameMessage)
    }

    func testAccountSetupDraftValidatorRequiresOshiSelection() {
        let message = AccountSetupDraftValidator.validationMessage(
            displayName: "みち",
            oshiSelections: []
        )

        XCTAssertEqual(message, AccountSetupDraftValidator.missingOshiMessage)
    }

    func testAccountSetupDraftValidatorRequiresHandle() {
        let message = validationMessage(handle: " ")

        XCTAssertEqual(message, AccountSetupDraftValidator.missingHandleMessage)
    }

    func testAccountSetupDraftValidatorRejectsInvalidHandle() {
        let message = validationMessage(handle: "みち")

        XCTAssertEqual(message, AccountSetupDraftValidator.invalidHandleMessage)
    }

    func testAccountSetupDraftValidatorRequiresPrefecture() {
        let message = validationMessage(prefecture: nil)

        XCTAssertEqual(message, AccountSetupDraftValidator.missingPrefectureMessage)
    }

    func testAccountSetupDraftValidatorRejectsInvalidPrefecture() {
        let message = validationMessage(prefecture: "東都")

        XCTAssertEqual(message, AccountSetupDraftValidator.invalidPrefectureMessage)
    }

    func testAccountSetupDraftValidatorRequiresBirthDate() {
        let message = validationMessage(birthDate: nil)

        XCTAssertEqual(message, AccountSetupDraftValidator.missingBirthDateMessage)
    }

    func testAccountSetupDraftValidatorRejectsFutureBirthDate() {
        let message = validationMessage(birthDate: Date().addingTimeInterval(86_400))

        XCTAssertEqual(message, AccountSetupDraftValidator.futureBirthDateMessage)
    }

    func testAccountSetupDraftValidatorRequiresGender() {
        let message = validationMessage(gender: nil)

        XCTAssertEqual(message, AccountSetupDraftValidator.missingGenderMessage)
    }

    func testAccountSetupDraftValidatorAcceptsOnlyFemaleAndMale() {
        XCTAssertEqual(AccountSetupGenderOptions.all, [.female, .male])
        XCTAssertNil(validationMessage(gender: .female))
        XCTAssertNil(validationMessage(gender: .male))
        XCTAssertEqual(validationMessage(gender: .other), AccountSetupDraftValidator.missingGenderMessage)
        XCTAssertEqual(validationMessage(gender: .noAnswer), AccountSetupDraftValidator.missingGenderMessage)
    }

    func testAccountSetupDraftValidatorAcceptsReadyDraft() {
        let message = AccountSetupDraftValidator.validationMessage(
            displayName: " みち ",
            oshiSelections: [makeOshiInput()]
        )

        XCTAssertNil(message)
    }

    func testAccountSetupDraftValidatorAcceptsCompleteDraft() {
        XCTAssertNil(validationMessage())
    }

    func testAccountSetupStepsKeepNameAndHandleInput() {
        XCTAssertEqual(
            AccountSetupStep.allCases,
            [.welcome, .oshi, .area, .displayName, .handle, .birthDate, .gender, .completion]
        )
        XCTAssertEqual(AccountSetupStep.totalCount, 8)
    }

    func testWelcomeStepDoesNotShowSubtitleCopy() {
        XCTAssertTrue(AccountSetupStep.welcome.subtitle.isEmpty)
    }

    func testBirthDateCalendarBuildsTouchableDaysInStableTimezone() throws {
        let month = try XCTUnwrap(ProfileBirthDateCodec.date(from: "2000-01-01"))
        let days = AccountSetupBirthDateCalendarLogic.days(for: month)
        let actualDates = days.compactMap(\.date)

        XCTAssertEqual(days.first?.date, nil)
        XCTAssertEqual(ProfileBirthDateCodec.string(from: actualDates.first), "2000-01-01")
        XCTAssertEqual(ProfileBirthDateCodec.string(from: actualDates.last), "2000-01-31")
        XCTAssertEqual(AccountSetupBirthDateCalendarLogic.dayNumber(for: actualDates[0]), 1)
        XCTAssertEqual(AccountSetupBirthDateCalendarLogic.monthTitle(for: month), "2000年1月")
    }

    func testBirthDateCalendarYearNavigationKeepsMonthAndBounds() throws {
        let visibleMonth = try XCTUnwrap(ProfileBirthDateCodec.date(from: "1998-12-01"))
        let maxDate = try XCTUnwrap(ProfileBirthDateCodec.date(from: "2026-06-27"))

        let previousYear = try XCTUnwrap(
            AccountSetupBirthDateCalendarLogic.addYears(-1, to: visibleMonth, maxDate: maxDate)
        )
        let nextYear = try XCTUnwrap(
            AccountSetupBirthDateCalendarLogic.addYears(1, to: visibleMonth, maxDate: maxDate)
        )

        XCTAssertEqual(AccountSetupBirthDateCalendarLogic.monthTitle(for: previousYear), "1997年12月")
        XCTAssertEqual(AccountSetupBirthDateCalendarLogic.monthTitle(for: nextYear), "1999年12月")

        let minimumMonth = try XCTUnwrap(ProfileBirthDateCodec.date(from: "1900-01-01"))
        XCTAssertNil(AccountSetupBirthDateCalendarLogic.addYears(-1, to: minimumMonth, maxDate: maxDate))

        let futureMonth = try XCTUnwrap(ProfileBirthDateCodec.date(from: "2025-12-01"))
        XCTAssertNil(AccountSetupBirthDateCalendarLogic.addYears(1, to: futureMonth, maxDate: maxDate))
    }

    func testBirthDateCalendarPresentationStateTracksVisibleMonthNavigationAndSelection() throws {
        let selection = try XCTUnwrap(ProfileBirthDateCodec.date(from: "2000-02-14"))
        let maxDate = try XCTUnwrap(ProfileBirthDateCodec.date(from: "2026-06-27"))
        var state = AccountSetupBirthDateCalendarPresentationState(selection: selection)

        XCTAssertEqual(state.monthTitle, "2000年2月")
        XCTAssertTrue(state.canShowPreviousYear(maxDate: maxDate))
        XCTAssertTrue(state.canShowNextMonth(maxDate: maxDate))

        state.showPreviousMonth()
        XCTAssertEqual(state.monthTitle, "2000年1月")

        state.showNextYear(maxDate: maxDate)
        XCTAssertEqual(state.monthTitle, "2001年1月")

        state.syncSelection(try XCTUnwrap(ProfileBirthDateCodec.date(from: "1999-12-31")))
        XCTAssertEqual(state.monthTitle, "1999年12月")

        var maxMonthState = AccountSetupBirthDateCalendarPresentationState(
            selection: try XCTUnwrap(ProfileBirthDateCodec.date(from: "2026-06-01"))
        )
        XCTAssertFalse(maxMonthState.canShowNextMonth(maxDate: maxDate))

        maxMonthState.showNextMonth(maxDate: maxDate)
        XCTAssertEqual(maxMonthState.monthTitle, "2026年6月")
    }

    func testOshiPresentationStateFiltersGroupsByGenreAndAlias() {
        let idolGenreID = UUID(uuidString: "30000000-0000-0000-0000-000000000101")!
        let actorGenreID = UUID(uuidString: "30000000-0000-0000-0000-000000000102")!
        let groups = [
            OshiGroup(
                id: UUID(uuidString: "30000000-0000-0000-0000-000000000111")!,
                name: "BTS",
                aliases: ["防弾少年団"],
                genreID: idolGenreID
            ),
            OshiGroup(
                id: UUID(uuidString: "30000000-0000-0000-0000-000000000112")!,
                name: "俳優A",
                aliases: ["actor-a"],
                genreID: actorGenreID
            )
        ]

        let state = AccountSetupOshiPresentationState(
            groups: groups,
            genres: [
                OshiGenre(id: idolGenreID, name: "K-POP"),
                OshiGenre(id: actorGenreID, name: "俳優")
            ],
            selectedGenreID: idolGenreID,
            searchText: " 防弾 ",
            selectedGroups: [],
            selectedDrafts: []
        )

        XCTAssertEqual(state.filteredGroups.map(\.name), ["BTS"])
        XCTAssertEqual(state.categoryOptions.map(\.title), ["すべて", "K-POP", "俳優"])
        XCTAssertNil(state.categoryOptions.first?.id)
    }

    func testOshiPresentationStateBuildsMemberTargetsFromGroupsAndRequests() {
        let group = OshiGroup(
            id: UUID(uuidString: "30000000-0000-0000-0000-000000000121")!,
            name: "TWICE",
            kind: .group
        )
        let solo = OshiGroup(
            id: UUID(uuidString: "30000000-0000-0000-0000-000000000122")!,
            name: "ソロ",
            kind: .solo
        )
        let requestID = UUID(uuidString: "30000000-0000-0000-0000-000000000123")!

        let state = AccountSetupOshiPresentationState(
            groups: [],
            genres: [],
            selectedGenreID: nil,
            searchText: "",
            selectedGroups: [group, solo],
            selectedDrafts: [
                OnboardingOshiDraft(
                    oshiRequestID: requestID,
                    requestedName: "新しい作品",
                    requestedKind: .work
                )
            ]
        )

        XCTAssertEqual(state.selectedMemberGroups.map(\.name), ["TWICE"])
        XCTAssertEqual(state.selectedMemberTargets.map(\.name), ["TWICE", "新しい作品"])
        XCTAssertEqual(state.selectedMemberTargets.last?.requestContext.oshiRequestID, requestID)
    }

    private func validationMessage(
        displayName: String = "みち",
        handle: String = "michirion",
        prefecture: String? = "東京都",
        birthDate: Date? = Date(timeIntervalSince1970: 0),
        gender: UserGender? = .female,
        oshiSelections: [AccountSetupOshiInput]? = nil
    ) -> String? {
        AccountSetupDraftValidator.validationMessage(
            displayName: displayName,
            handle: handle,
            prefecture: prefecture,
            birthDate: birthDate,
            gender: gender,
            oshiSelections: oshiSelections ?? [makeOshiInput()]
        )
    }

    private func makeOshiInput() -> AccountSetupOshiInput {
        AccountSetupOshiInput(
            groupID: UUID(uuidString: "30000000-0000-0000-0000-000000000001")!,
            characterID: nil,
            kind: .box
        )
    }
}
