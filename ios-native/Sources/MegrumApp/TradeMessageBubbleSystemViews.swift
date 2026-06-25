import MegrumCore
import MegrumDesign
import SwiftUI

struct TradeSystemMessageBubble: View {
    var message: TradeMessage
    var isMine: Bool
    var cancelApprovalPrompt: TradeCancelApprovalPrompt?
    var isApprovingCancel: Bool
    var onOpenDispute: (TradeDisputeSummary) -> Void
    var onOpenEvidenceList: () -> Void
    var onApproveCancel: () -> Void

    var body: some View {
        let presentation = TradeSystemMessagePresentation(message: message, isMine: isMine)
        if let disputeSummary = TradeDisputeSummary(message: message) {
            Button {
                onOpenDispute(disputeSummary)
            } label: {
                TradeSystemMessageContent(presentation: presentation, showsDisclosure: true)
            }
            .buttonStyle(.plain)
        } else if TradeEvidenceSystemMessage.isEvidenceNotice(message) {
            Button(action: onOpenEvidenceList) {
                TradeSystemMessageContent(presentation: presentation, showsDisclosure: true)
            }
            .buttonStyle(.plain)
        } else {
            VStack(spacing: 8) {
                TradeSystemMessageContent(presentation: presentation, showsDisclosure: false)
                if cancelApprovalPrompt?.canApprove == true {
                    TradeCancelApprovalButton(
                        isApprovingCancel: isApprovingCancel,
                        action: onApproveCancel
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

private struct TradeSystemMessageContent: View {
    var presentation: TradeSystemMessagePresentation
    var showsDisclosure: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: presentation.systemImage)
                .font(.system(size: 13, weight: .bold))
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 3) {
                Text(presentation.title)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                Text(presentation.body)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .fixedSize(horizontal: false, vertical: true)
                if let detail = presentation.detail {
                    Text(detail)
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                }
            }
            if showsDisclosure {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .heavy))
                    .padding(.top, 2)
            }
        }
        .foregroundStyle(MegrumTheme.muted)
        .padding(.horizontal, 13)
        .padding(.vertical, 9)
        .frame(maxWidth: 320, alignment: .leading)
        .background(.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .frame(maxWidth: .infinity, alignment: .center)
        .accessibilityLabel(presentation.accessibilityLabel)
    }
}

private struct TradeCancelApprovalButton: View {
    var isApprovingCancel: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isApprovingCancel {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                }
                Text("キャンセルに同意する")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(MegrumTheme.lavender, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isApprovingCancel)
        .accessibilityLabel("キャンセル申請に同意する")
    }
}
