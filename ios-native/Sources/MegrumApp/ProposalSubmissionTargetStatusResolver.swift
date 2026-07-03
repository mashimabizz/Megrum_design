import MegrumCore

enum ProposalSubmissionTargetStatusResolver {
    static func status(
        canSubmit: Bool,
        defaultTargetStatus: ProposalStatus?,
        override: ProposalStatus?
    ) -> ProposalStatus? {
        guard canSubmit, let defaultTargetStatus else {
            return nil
        }
        return override ?? defaultTargetStatus
    }
}
