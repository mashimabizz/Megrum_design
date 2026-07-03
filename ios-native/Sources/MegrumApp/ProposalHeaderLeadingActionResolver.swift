import Foundation

enum ProposalHeaderLeadingAction: Equatable {
    case previousStep
    case dismiss
}

enum ProposalHeaderLeadingActionResolver {
    static func action(for step: ProposalCreateStep) -> ProposalHeaderLeadingAction {
        switch step {
        case .payment, .confirm:
            .previousStep
        case .give, .receive, .meetup, .shipping:
            .dismiss
        }
    }
}
