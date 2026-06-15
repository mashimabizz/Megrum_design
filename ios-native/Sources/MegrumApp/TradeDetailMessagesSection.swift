import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct TradeDetailMessagesSection: View {
    var proposal: TradeProposal
    var messages: [TradeMessage]
    var viewerID: UUID?
    var partnerLastReadAt: Date?
    var isLoading: Bool
    var isApprovingCancel: Bool
    var onOpenImage: (URL) -> Void
    var onOpenDispute: (TradeDisputeSummary) -> Void
    var onApproveCancel: () -> Void

    private var timelineRows: [TradeChatTimelineRow] {
        TradeChatTimelineRows.make(
            messages: messages,
            viewerID: viewerID,
            partnerLastReadAt: partnerLastReadAt
        )
    }

    var body: some View {
        VStack(spacing: 10) {
            if isLoading {
                ProgressView()
                    .controlSize(.small)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }

            if messages.isEmpty, !isLoading {
                TradeEmptyMessageCard()
            } else {
                ForEach(timelineRows) { row in
                    if let dayDividerText = row.dayDividerText {
                        TradeChatTimestampDivider(text: dayDividerText)
                    }
                    TradeMessageBubble(
                        message: row.message,
                        isMine: row.isMine,
                        isReadByPartner: row.isReadByPartner,
                        cancelApprovalPrompt: TradeCancelApprovalPrompt(
                            message: row.message,
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
}

private struct TradeEmptyMessageCard: View {
    var body: some View {
        Text("まだメッセージがありません。挨拶から始めましょう")
            .font(.system(size: 12.5, weight: .heavy, design: .rounded))
            .foregroundStyle(MegrumTheme.muted)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(MegrumTheme.ink.opacity(0.06), lineWidth: 1)
            }
            .accessibilityLabel("まだメッセージがありません。挨拶から始めましょう")
    }
}
