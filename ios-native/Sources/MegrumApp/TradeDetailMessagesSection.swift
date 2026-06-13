import Foundation
import MegrumCore
import SwiftUI

struct TradeDetailMessagesSection: View {
    var proposal: TradeProposal
    var messages: [TradeMessage]
    var viewerID: UUID?
    var isLoading: Bool
    var isApprovingCancel: Bool
    var onOpenImage: (URL) -> Void
    var onOpenDispute: (TradeDisputeSummary) -> Void
    var onApproveCancel: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            if isLoading {
                ProgressView()
                    .controlSize(.small)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }

            ForEach(messages) { message in
                TradeMessageBubble(
                    message: message,
                    isMine: message.senderID == viewerID,
                    cancelApprovalPrompt: TradeCancelApprovalPrompt(
                        message: message,
                        proposal: proposal,
                        viewerID: viewerID,
                        messages: messages
                    ),
                    isApprovingCancel: isApprovingCancel,
                    onOpenImage: onOpenImage,
                    onOpenDispute: onOpenDispute,
                    onApproveCancel: onApproveCancel
                )
            }
        }
    }
}
