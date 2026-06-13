import Foundation
import SwiftUI

enum ProposalMeetupCalendarCandidateEditAction {
    case move
    case resizeEnd
}

struct ProposalMeetupCalendarCandidateEdit: Equatable {
    var index: Int
    var dayIndex: Int
    var startSlot: Int
    var endSlot: Int
}

enum ProposalMeetupCalendarBoardTouchMode {
    case pending
    case swiping
    case creating
    case movingCandidate
}

struct ProposalMeetupCalendarBoardTouchState {
    var startTime: Date
    var startLocation: CGPoint
    var dayIndex: Int
    var startSlot: Int
    var mode: ProposalMeetupCalendarBoardTouchMode
    var candidateIndex: Int?
    var originalDayIndex: Int?
    var originalStartSlot: Int?
    var originalEndSlot: Int?
    var pointerStartOffsetSlots: Int?
}

enum ProposalMeetupCalendarCandidateTouchMode {
    case pending
    case editing
}

struct ProposalMeetupCalendarCandidateTouchState {
    var startTime: Date
    var startLocation: CGPoint
    var draftIndex: Int
    var action: ProposalMeetupCalendarCandidateEditAction
    var originalDayIndex: Int
    var originalStartSlot: Int
    var originalEndSlot: Int
    var pointerStartOffsetSlots: Int
    var mode: ProposalMeetupCalendarCandidateTouchMode
}
