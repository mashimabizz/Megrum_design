import MegrumApp
import MegrumCore
import XCTest

final class ScheduleStateReducerTests: XCTestCase {
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
