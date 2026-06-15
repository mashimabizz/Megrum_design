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
    var requestedGoods: [GoodsItem]
    var offeredGoods: [GoodsItem]
    var requestedGoodsCount: Int
    var offeredGoodsCount: Int
    var paymentSummaryText: String?
    var evidencePhotos: [TradeEvidencePhoto]
    @Binding var selectedEvidencePhotoItem: PhotosPickerItem?
    var partnerLastReadAt: Date?
    var evaluationState: TradeEvaluationPromptState
    var isResponding: Bool
    var isLoadingMessages: Bool
    var isApprovingCancel: Bool
    var isAddingEvidence: Bool
    var isApprovingEvidence: Bool
    var canUseCamera: Bool
    var onOpenDispute: (TradeDisputeSummary) -> Void
    var onOpenPartnerProfile: () -> Void
    var onAgree: (ExchangeMethod?) -> Void
    var onReject: () -> Void
    var onCounterProposal: () -> Void
    var onOpenEvidenceCamera: () -> Void
    var onOpenImage: (URL) -> Void
    var onApproveEvidence: () -> Void
    var onRate: () -> Void
    var onApproveCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            TradeChatPartnerStrip(
                presentation: heroPresentation,
                onOpenProfile: onOpenPartnerProfile
            )
                .padding(.horizontal, 16)
                .padding(.top, 7)
                .padding(.bottom, 8)

            Divider()
                .overlay(MegrumTheme.ink.opacity(0.08))

            TradeDetailPinnedSummaryArea(
                proposal: proposal,
                viewerID: viewerID,
                latestDisputeSummary: latestDisputeSummary,
                tradeSummaryLine: tradeSummaryLine,
                requestedGoods: requestedGoods,
                offeredGoods: offeredGoods,
                requestedGoodsCount: requestedGoodsCount,
                offeredGoodsCount: offeredGoodsCount,
                paymentSummaryText: paymentSummaryText,
                isResponding: isResponding,
                onOpenDispute: onOpenDispute,
                onAgree: onAgree,
                onReject: onReject,
                onCounterProposal: onCounterProposal
            )

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 12) {
                        TradeDetailMessagesSection(
                            proposal: proposal,
                            messages: messages,
                            viewerID: viewerID,
                            partnerLastReadAt: partnerLastReadAt,
                            isLoading: isLoadingMessages,
                            isApprovingCancel: isApprovingCancel,
                            onOpenImage: onOpenImage,
                            onOpenDispute: onOpenDispute,
                            onApproveCancel: onApproveCancel
                        )
                        TradeDetailEvidenceSection(
                            proposal: proposal,
                            viewerID: viewerID,
                            evidencePhotos: evidencePhotos,
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
                        Color.clear
                            .frame(height: 1)
                            .id(Self.messageBottomAnchorID)
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 12)
                    .padding(.bottom, 118)
                }
                .onAppear {
                    scrollToLatestMessage(proxy, animated: false)
                }
                .onChange(of: messages.last?.id) { _, _ in
                    scrollToLatestMessage(proxy, animated: true)
                }
                .onChange(of: isLoadingMessages) { _, isLoading in
                    if !isLoading {
                        scrollToLatestMessage(proxy, animated: false)
                    }
                }
            }
        }
    }

    private static let messageBottomAnchorID = "trade-detail-message-bottom-anchor"

    private func scrollToLatestMessage(_ proxy: ScrollViewProxy, animated: Bool) {
        guard !messages.isEmpty else {
            return
        }
        let action = {
            proxy.scrollTo(Self.messageBottomAnchorID, anchor: .bottom)
        }
        if animated {
            withAnimation(.snappy(duration: 0.28)) {
                action()
            }
        } else {
            action()
        }
    }
}
