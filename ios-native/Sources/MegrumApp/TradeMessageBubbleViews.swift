import Foundation
import MegrumCore
import SwiftUI

struct TradeMessageBubble: View {
    var message: TradeMessage
    var isMine: Bool
    var isReadByPartner: Bool = false
    var cancelApprovalPrompt: TradeCancelApprovalPrompt?
    var isApprovingCancel: Bool = false
    var onOpenImage: (URL) -> Void
    var onOpenDispute: (TradeDisputeSummary) -> Void = { _ in }
    var onOpenEvidenceList: () -> Void = {}
    var onApproveCancel: () -> Void = {}
    var quoteAvatarURL: URL? = nil
    var onJumpToMessage: (UUID) -> Void = { _ in }

    var body: some View {
        if message.messageType == .system {
            TradeSystemMessageBubble(
                message: message,
                isMine: isMine,
                cancelApprovalPrompt: cancelApprovalPrompt,
                isApprovingCancel: isApprovingCancel,
                onOpenDispute: onOpenDispute,
                onOpenEvidenceList: onOpenEvidenceList,
                onApproveCancel: onApproveCancel
            )
        } else {
            userMessage
        }
    }

    private var userMessage: some View {
        TradeUserMessageStack(
            message: message,
            isMine: isMine,
            isReadByPartner: isReadByPartner,
            onOpenImage: onOpenImage,
            quoteAvatarURL: quoteAvatarURL,
            onJumpToMessage: onJumpToMessage
        )
        .frame(maxWidth: .infinity, alignment: isMine ? .trailing : .leading)
    }
}
