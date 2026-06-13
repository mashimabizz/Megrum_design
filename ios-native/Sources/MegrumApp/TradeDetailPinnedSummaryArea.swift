import Foundation
import MegrumCore
import MegrumDesign
import PhotosUI
import SwiftUI

struct TradeDetailPinnedSummaryArea: View {
    var proposal: TradeProposal
    var messages: [TradeMessage]
    var viewerID: UUID?
    var latestDisputeSummary: TradeDisputeSummary?
    var tradeSummaryLine: String
    @Binding var selectedOutfitPhotoItem: PhotosPickerItem?
    var isResponding: Bool
    var isSendingDayOfMessage: Bool
    var canUseCamera: Bool
    var onOpenDispute: (TradeDisputeSummary) -> Void
    var onAgree: (ExchangeMethod?) -> Void
    var onReject: () -> Void
    var onCounterProposal: () -> Void
    var onOpenOutfitCamera: () -> Void
    var onMarkArrived: () -> Void
    var onShareLocation: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            disputeBannerSection

            TradeCollapsedSummaryCard(
                label: "交換手段",
                summary: proposal.exchangeMethod.displayName,
                systemImage: "arrow.triangle.swap"
            )

            TradeCollapsedSummaryCard(
                label: "交換内容",
                summary: tradeSummaryLine,
                systemImage: "gift"
            )

            conditionTagRow
            proposalResponseSection
            dayOfBannerSection
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.white.opacity(0.56))
    }

    @ViewBuilder
    private var disputeBannerSection: some View {
        if let latestDisputeSummary {
            TradeDisputeBanner(summary: latestDisputeSummary) {
                onOpenDispute(latestDisputeSummary)
            }
        }
    }

    @ViewBuilder
    private var conditionTagRow: some View {
        if !proposal.conditionTags.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(proposal.conditionTags, id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundStyle(MegrumTheme.lavender)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(MegrumTheme.lavender.opacity(0.1), in: Capsule())
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    @ViewBuilder
    private var proposalResponseSection: some View {
        if proposal.isProposalResponsePending {
            TradeAgreementCompactBar(
                proposal: proposal,
                viewerID: viewerID,
                isResponding: isResponding,
                onAgree: onAgree,
                onReject: onReject,
                onCounterProposal: onCounterProposal
            )
        }
    }

    @ViewBuilder
    private var dayOfBannerSection: some View {
        if let dayOfPresentation = TradeDayOfBannerPresentation(
            proposal: proposal,
            messages: messages,
            viewerID: viewerID
        ) {
            TradeDayOfBanner(
                presentation: dayOfPresentation,
                selectedOutfitPhotoItem: $selectedOutfitPhotoItem,
                isSending: isSendingDayOfMessage,
                canUseCamera: canUseCamera,
                onOpenOutfitCamera: onOpenOutfitCamera,
                onMarkArrived: onMarkArrived,
                onShareLocation: onShareLocation
            )
        }
    }
}
