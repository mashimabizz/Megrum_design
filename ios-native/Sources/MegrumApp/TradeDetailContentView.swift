import Foundation
import MegrumCore
import MegrumDesign
import PhotosUI
import SwiftUI

struct TradeDetailContent: View {
    var proposal: TradeProposal
    var messages: [TradeMessage]
    var viewerID: UUID?
    var heroPresentation: TradeDetailHeroPresentation
    var latestDisputeSummary: TradeDisputeSummary?
    var tradeSummaryLine: String
    var chatDateDividerText: String
    @Binding var selectedOutfitPhotoItem: PhotosPickerItem?
    @Binding var selectedEvidencePhotoItem: PhotosPickerItem?
    var evaluationState: TradeEvaluationPromptState
    var isResponding: Bool
    var isSendingDayOfMessage: Bool
    var isLoadingMessages: Bool
    var isApprovingCancel: Bool
    var isAddingEvidence: Bool
    var isApprovingEvidence: Bool
    var canUseCamera: Bool
    var onOpenDispute: (TradeDisputeSummary) -> Void
    var onAgree: (ExchangeMethod?) -> Void
    var onReject: () -> Void
    var onCounterProposal: () -> Void
    var onOpenOutfitCamera: () -> Void
    var onMarkArrived: () -> Void
    var onShareLocation: () -> Void
    var onOpenEvidenceCamera: () -> Void
    var onOpenImage: (URL) -> Void
    var onApproveEvidence: () -> Void
    var onRate: () -> Void
    var onApproveCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            TradeChatPartnerStrip(presentation: heroPresentation)
                .padding(.horizontal, 16)
                .padding(.top, 7)
                .padding(.bottom, 8)

            Divider()
                .overlay(MegrumTheme.ink.opacity(0.08))

            TradeDetailPinnedSummaryArea(
                proposal: proposal,
                messages: messages,
                viewerID: viewerID,
                latestDisputeSummary: latestDisputeSummary,
                tradeSummaryLine: tradeSummaryLine,
                selectedOutfitPhotoItem: $selectedOutfitPhotoItem,
                isResponding: isResponding,
                isSendingDayOfMessage: isSendingDayOfMessage,
                canUseCamera: canUseCamera,
                onOpenDispute: onOpenDispute,
                onAgree: onAgree,
                onReject: onReject,
                onCounterProposal: onCounterProposal,
                onOpenOutfitCamera: onOpenOutfitCamera,
                onMarkArrived: onMarkArrived,
                onShareLocation: onShareLocation
            )

            ScrollView {
                VStack(spacing: 12) {
                    TradeChatTimestampDivider(text: chatDateDividerText)
                    TradeDetailMessagesSection(
                        proposal: proposal,
                        messages: messages,
                        viewerID: viewerID,
                        isLoading: isLoadingMessages,
                        isApprovingCancel: isApprovingCancel,
                        onOpenImage: onOpenImage,
                        onOpenDispute: onOpenDispute,
                        onApproveCancel: onApproveCancel
                    )
                    TradeDetailEvidenceSection(
                        proposal: proposal,
                        viewerID: viewerID,
                        selectedPhotoItem: $selectedEvidencePhotoItem,
                        evaluationState: evaluationState,
                        isAddingEvidence: isAddingEvidence,
                        isApproving: isApprovingEvidence,
                        canUseCamera: canUseCamera,
                        onOpenCamera: onOpenEvidenceCamera,
                        onOpenImage: onOpenImage,
                        onApprove: onApproveEvidence,
                        onRate: onRate
                    )
                }
                .padding(.horizontal, 10)
                .padding(.top, 12)
                .padding(.bottom, 118)
            }
        }
    }
}
