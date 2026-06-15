import Foundation
import MegrumCore

public enum ScheduleStateReducer {
    public static func replacingProposalSchedules(
        in schedulesByProposalID: [UUID: [PersonalSchedule]],
        proposalID: UUID,
        schedules: [PersonalSchedule]
    ) -> [UUID: [PersonalSchedule]] {
        var next = schedulesByProposalID
        next[proposalID] = schedules
        return next
    }

    public static func appendingProposalSchedule(
        _ schedule: PersonalSchedule,
        to schedulesByProposalID: [UUID: [PersonalSchedule]],
        proposalID: UUID
    ) -> [UUID: [PersonalSchedule]] {
        var next = schedulesByProposalID
        next[proposalID] = sortedByStartAt((next[proposalID] ?? []) + [schedule])
        return next
    }

    public static func appendingPersonalSchedule(
        _ schedule: PersonalSchedule,
        to personalSchedules: [PersonalSchedule]
    ) -> [PersonalSchedule] {
        sortedByStartAt(personalSchedules + [schedule])
    }

    private static func sortedByStartAt(_ schedules: [PersonalSchedule]) -> [PersonalSchedule] {
        schedules.sorted { $0.startAt < $1.startAt }
    }
}
