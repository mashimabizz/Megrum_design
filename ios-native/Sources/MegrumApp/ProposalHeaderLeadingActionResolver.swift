import Foundation

enum ProposalHeaderLeadingAction: Equatable {
    case previousStep
    case dismiss
}

enum ProposalHeaderLeadingActionResolver {
    static func action(for step: ProposalCreateStep) -> ProposalHeaderLeadingAction {
        switch step {
        // 個別募集エディタ準拠：1/3以外は戻るで前のステップへ（iter1226.344）。
        case .receive, .conditions, .payment, .confirm:
            .previousStep
        case .give, .meetup, .shipping:
            .dismiss
        }
    }
}
