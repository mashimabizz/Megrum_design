import Foundation

enum ProposalMeetupEndDateResolver {
    static let defaultMinimumDuration: TimeInterval = 30 * 60

    static func adjustedEnd(
        startAt: Date,
        currentEndAt: Date,
        minimumDuration: TimeInterval = defaultMinimumDuration
    ) -> Date {
        currentEndAt <= startAt ? startAt.addingTimeInterval(minimumDuration) : currentEndAt
    }
}
