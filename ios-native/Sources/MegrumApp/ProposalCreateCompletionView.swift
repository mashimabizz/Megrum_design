import MegrumDesign
import SwiftUI

struct ProposalCreateCompletionView: View {
    var summary: ProposalSubmittedSummary
    var onSearchMore: () -> Void
    var onOpenTrades: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            ProposalCompletionCard(summary: summary)

            ProposalCompletionButtonStack(onAction: perform)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.top, 28)
        .padding(.bottom, 18)
    }

    private func perform(_ action: ProposalCompletionAction) {
        switch action {
        case .searchMore:
            onSearchMore()
        case .openTrades:
            onOpenTrades()
        }
    }
}
