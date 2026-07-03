@testable import MegrumApp
import MegrumCore
import XCTest

final class ScheduleStateReducerTests: XCTestCase {
    func testScheduleEditorDraftStateValidatesDatesAndBuildsInput() {
        let start = Date(timeIntervalSince1970: 1_780_160_000)
        var state = ScheduleEditorDraftState(defaultDate: start)

        state.title = " \n "
        XCTAssertFalse(state.canSave(isCreatingSchedule: false))

        state.title = " 物販列 "
        state.placeName = " 北口 "
        state.note = " 早めに並ぶ "
        XCTAssertTrue(state.canSave(isCreatingSchedule: false))
        XCTAssertFalse(state.canSave(isCreatingSchedule: true))

        state.startAt = state.endAt
        state.adjustEndAfterStartChange()
        XCTAssertEqual(state.endAt, state.startAt.addingTimeInterval(3_600))

        let input = state.makeInput()
        XCTAssertEqual(input.title, " 物販列 ")
        XCTAssertEqual(input.placeName, " 北口 ")
        XCTAssertEqual(input.note, " 早めに並ぶ ")
        XCTAssertFalse(input.allDay)
    }

    func testScheduleEditorDraftStateAllDaySnapsToDateRange() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let start = calendar.date(from: DateComponents(year: 2026, month: 7, day: 4, hour: 18, minute: 30))!
        var state = ScheduleEditorDraftState(defaultDate: start)

        state.startAt = start
        state.setAllDay(true, calendar: calendar)

        let expectedStart = calendar.startOfDay(for: start)
        XCTAssertTrue(state.allDay)
        XCTAssertEqual(state.startAt, expectedStart)
        XCTAssertEqual(state.endAt, calendar.date(byAdding: .day, value: 1, to: expectedStart))
    }

    func testReplacingProposalSchedulesKeepsOtherProposalBuckets() {
        let targetProposalID = UUID(uuidString: "00000000-0000-0000-0000-000000000701")!
        let otherProposalID = UUID(uuidString: "00000000-0000-0000-0000-000000000702")!
        let replacement = makeSchedule(idSuffix: "711", startAt: 300)
        let otherSchedule = makeSchedule(idSuffix: "712", startAt: 100)
        let schedulesByProposalID = [
            targetProposalID: [makeSchedule(idSuffix: "713", startAt: 200)],
            otherProposalID: [otherSchedule],
        ]

        let updated = ScheduleStateReducer.replacingProposalSchedules(
            in: schedulesByProposalID,
            proposalID: targetProposalID,
            schedules: [replacement]
        )

        XCTAssertEqual(updated[targetProposalID], [replacement])
        XCTAssertEqual(updated[otherProposalID], [otherSchedule])
    }

    func testAppendingProposalScheduleCreatesBucketAndSortsByStartAt() {
        let proposalID = UUID(uuidString: "00000000-0000-0000-0000-000000000703")!
        let late = makeSchedule(idSuffix: "721", startAt: 300)
        let early = makeSchedule(idSuffix: "722", startAt: 100)

        let created = ScheduleStateReducer.appendingProposalSchedule(
            late,
            to: [:],
            proposalID: proposalID
        )
        let appended = ScheduleStateReducer.appendingProposalSchedule(
            early,
            to: created,
            proposalID: proposalID
        )

        XCTAssertEqual(appended[proposalID], [early, late])
    }

    func testAppendingPersonalScheduleSortsByStartAt() {
        let middle = makeSchedule(idSuffix: "731", startAt: 200)
        let late = makeSchedule(idSuffix: "732", startAt: 300)
        let early = makeSchedule(idSuffix: "733", startAt: 100)

        let updated = ScheduleStateReducer.appendingPersonalSchedule(
            early,
            to: [middle, late]
        )

        XCTAssertEqual(updated, [early, middle, late])
    }

    private func makeSchedule(idSuffix: String, startAt: TimeInterval) -> PersonalSchedule {
        PersonalSchedule(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000\(idSuffix)")!,
            userID: UUID(uuidString: "00000000-0000-0000-0000-000000000799")!,
            title: "予定\(idSuffix)",
            startAt: Date(timeIntervalSince1970: startAt),
            endAt: Date(timeIntervalSince1970: startAt + 3_600)
        )
    }
}
