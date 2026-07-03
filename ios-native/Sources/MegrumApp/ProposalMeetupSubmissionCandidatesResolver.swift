import MegrumCore

enum ProposalMeetupSubmissionCandidatesResolver {
    static func candidates(
        requiresMeetupBeforeSubmit: Bool,
        meetupInputs: [ProposalMeetupInput]
    ) -> [ProposalMeetupInput]? {
        guard requiresMeetupBeforeSubmit else {
            return []
        }
        return meetupInputs.first == nil ? nil : meetupInputs
    }
}
