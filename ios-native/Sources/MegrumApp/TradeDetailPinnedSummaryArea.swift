import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct TradeDetailPinnedSummaryArea: View {
    var proposal: TradeProposal
    var viewerID: UUID?
    var latestDisputeSummary: TradeDisputeSummary?
    var tradeSummaryLine: String
    var requestedGoods: [GoodsItem]
    var offeredGoods: [GoodsItem]
    var requestedGoodsCount: Int
    var offeredGoodsCount: Int
    var paymentSummaryText: String?
    var isResponding: Bool
    var onOpenDispute: (TradeDisputeSummary) -> Void
    var onAgree: (ExchangeMethod?) -> Void
    var onReject: () -> Void
    var onCounterProposal: () -> Void
    @State private var detailRoute: TradeSummaryDetailRoute?

    private var visiblePaymentSummary: String? {
        guard proposal.cashOffer else {
            return nil
        }
        let trimmed = paymentSummaryText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "未設定" : trimmed
    }

    var body: some View {
        VStack(spacing: 8) {
            disputeBannerSection

            TradeCollapsedSummaryCard(
                label: "交換手段",
                summary: proposal.exchangeMethod.displayName,
                systemImage: "arrow.triangle.swap",
                action: {
                    detailRoute = .exchangeMethod
                }
            )

            TradeCollapsedSummaryCard(
                label: "交換内容",
                summary: tradeSummaryLine,
                systemImage: "gift",
                action: {
                    detailRoute = .tradeContent
                }
            )

            if let visiblePaymentSummary {
                TradePaymentSummaryCard(
                    summary: visiblePaymentSummary,
                    cashAmountText: proposal.cashAmount.map(TradeAmountFormatter.compactYen)
                )
            }

            proposalResponseSection
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.white.opacity(0.56))
        .sheet(item: $detailRoute) { route in
            TradeSummaryDetailSheet(
                route: route,
                proposal: proposal,
                requestedGoods: requestedGoods,
                offeredGoods: offeredGoods,
                requestedGoodsCount: requestedGoodsCount,
                offeredGoodsCount: offeredGoodsCount
            )
        }
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
}

private struct TradePaymentSummaryCard: View {
    var summary: String
    var cashAmountText: String?

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: "yensign.circle")
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(width: 22, height: 22)
                .background(MegrumTheme.lavender.opacity(0.12), in: RoundedRectangle(cornerRadius: 7, style: .continuous))

            Text("支払い手段")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .lineLimit(1)

            Text(summary)
                .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.68)

            Spacer(minLength: 4)

            if let cashAmountText {
                Text(cashAmountText)
                    .font(.system(size: 10.5, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ok)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(MegrumTheme.ok.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(MegrumTheme.ok.opacity(0.18), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}
