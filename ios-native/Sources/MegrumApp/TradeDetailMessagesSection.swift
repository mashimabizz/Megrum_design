import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct TradeDetailMessagesSection: View {
    var proposal: TradeProposal
    var messages: [TradeMessage]
    /// iter1226.463：表示ウィンドウより古いメッセージが残っているか（上端でページング）。
    var hasOlderMessages: Bool = false
    /// 上端に到達した時に呼ばれる（親が表示ウィンドウを1ページ分広げる）。
    var onLoadOlder: () -> Void = {}
    var viewerID: UUID?
    var evaluationState: TradeEvaluationPromptState
    var partnerLastReadAt: Date?
    var partnerPaymentMethods: [UserPaymentMethod]
    var partnerPaymentNote: String?
    var partnerMailingAddress: TradeMailingAddressSnapshot?
    var partnerPaymentSettings: TradePaymentSettingsSnapshot?
    var isLoading: Bool
    var isApprovingCancel: Bool
    var onOpenImage: (URL) -> Void
    var onReply: (TradeMessage) -> Void = { _ in }
    var onReportMessage: (TradeMessage) -> Void = { _ in }
    /// 引用の返信元が相手の時に出すアバターURL。
    var partnerAvatarURL: URL? = nil
    var onJumpToMessage: (UUID) -> Void = { _ in }
    var onOpenDispute: (TradeDisputeSummary) -> Void
    var onOpenMailingInfo: () -> Void
    var onOpenPaymentInfo: () -> Void
    var onOpenEvidenceList: () -> Void
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
            if showsAgreementSystemTimeline {
                TradeAgreementSystemTimeline(
                    proposal: proposal,
                    viewerID: viewerID,
                    partnerPaymentMethods: partnerPaymentMethods,
                    partnerPaymentNote: partnerPaymentNote,
                    partnerMailingAddress: partnerMailingAddress,
                    partnerPaymentSettings: partnerPaymentSettings,
                    onOpenMailingInfo: onOpenMailingInfo,
                    onOpenPaymentInfo: onOpenPaymentInfo
                )
            }

            if messages.isEmpty, !isLoading {
                TradeEmptyMessageCard()
            } else {
                // iter1226.463：上へ遡った時だけ古いページを足す（チャットの定石）。
                if hasOlderMessages {
                    ProgressView()
                        .controlSize(.small)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .onAppear(perform: onLoadOlder)
                }

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
                        onOpenEvidenceList: onOpenEvidenceList,
                        onApproveCancel: onApproveCancel,
                        quoteAvatarURL: partnerAvatarURL,
                        onJumpToMessage: onJumpToMessage
                    )
                    .id(row.message.id)
                    .chatMessageInteraction(
                        copyText: (row.message.body?.nilIfBlank).map(ChatReplyQuoteFormatter.copyText(of:)),
                        onReply: row.message.messageType != .system
                            && (row.message.body?.nilIfBlank != nil || row.message.photoURL != nil)
                            ? { onReply(row.message) }
                            : nil,
                        onReport: row.isMine ? nil : { onReportMessage(row.message) }
                    )
                }
                if evaluationState.shouldRevealEvaluations {
                    TradeEvaluationRevealCard(evaluations: evaluationState.revealedEvaluations)
                }
            }
        }
    }

    private var showsAgreementSystemTimeline: Bool {
        proposal.status == .agreed || proposal.status == .completed
    }
}

private struct TradeEvaluationRevealCard: View {
    var evaluations: [TradeCompletedEvaluationPresentation]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("お互いの評価", systemImage: "star.fill")
                .font(.system(size: 14.5, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            ForEach(evaluations) { evaluation in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(evaluation.roleTag)
                            .font(.system(size: 11.5, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(
                                evaluation.isMine ? MegrumTheme.lavender : MegrumTheme.sky,
                                in: Capsule()
                            )

                        Text(evaluation.displayName)
                            .font(.system(size: 13.5, weight: .heavy, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink)

                        Spacer(minLength: 6)

                        HStack(spacing: 1) {
                            ForEach(1...5, id: \.self) { index in
                                Image(systemName: index <= evaluation.stars ? "star.fill" : "star")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundStyle(MegrumTheme.lavender)
                            }
                        }
                    }

                    Text(evaluation.comment.nilIfBlank ?? "コメントなし")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(MegrumTheme.ink.opacity(0.06), lineWidth: 1)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: 330, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(MegrumTheme.lavender.opacity(0.18), lineWidth: 1)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .accessibilityLabel("お互いの評価が公開されました")
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
