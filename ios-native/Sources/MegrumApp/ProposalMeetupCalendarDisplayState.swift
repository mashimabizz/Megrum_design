import Foundation

struct ProposalMeetupCalendarDisplayState: Equatable {
    var displayMode: ProposalMeetupCalendarDisplayMode

    init(displayMode: ProposalMeetupCalendarDisplayMode) {
        self.displayMode = displayMode
    }

    init(environment: [String: String] = ProcessInfo.processInfo.environment) {
        displayMode = Self.initialDisplayMode(environment: environment)
    }

    var showsWeekTitle: Bool {
        displayMode == .week
    }

    mutating func showWeek() {
        displayMode = .week
    }

    private static func initialDisplayMode(
        environment: [String: String]
    ) -> ProposalMeetupCalendarDisplayMode {
        VisualQAPreviewMode.initialScreen(environment: environment) == .proposalMeetupMonth ? .month : .week
    }
}
