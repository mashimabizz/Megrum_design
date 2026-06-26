import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

enum TradeSummaryDetailRoute: String, Identifiable {
    case exchangeMethod
    case tradeContent

    var id: String { rawValue }

    var title: String {
        switch self {
        case .exchangeMethod:
            "交換手段"
        case .tradeContent:
            "交換内容"
        }
    }
}

struct TradeSummaryDetailSheet: View {
    @Environment(\.dismiss) private var dismiss

    var route: TradeSummaryDetailRoute
    var proposal: TradeProposal
    var requestedGoods: [GoodsItem]
    var offeredGoods: [GoodsItem]
    var requestedGoodsCount: Int
    var offeredGoodsCount: Int

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch route {
                    case .exchangeMethod:
                        TradeSummaryExchangeMethodContent(proposal: proposal)
                    case .tradeContent:
                        TradeSummaryTradeContent(
                            proposal: proposal,
                            requestedGoods: requestedGoods,
                            offeredGoods: offeredGoods,
                            requestedGoodsCount: requestedGoodsCount,
                            offeredGoodsCount: offeredGoodsCount
                        )
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
            .background(MegrumTheme.canvas.ignoresSafeArea())
            .navigationTitle(route.title)
            .megrumInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct TradeSummaryExchangeMethodContent: View {
    var proposal: TradeProposal

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if proposal.exchangeMethod.supportsHand {
                TradeSummarySheetSection(title: "現地交換の候補") {
                    if let meetupCandidates = proposal.meetupCandidates, !meetupCandidates.isEmpty {
                        VStack(spacing: 10) {
                            ForEach(Array(meetupCandidates.enumerated()), id: \.offset) { index, meetup in
                                TradeMeetupCandidateSummaryRow(index: index, meetup: meetup)
                            }
                        }
                    } else {
                        TradeSummaryEmptyText("候補は未設定です")
                    }
                }
            }

            if proposal.exchangeMethod.supportsMail {
                TradeSummarySheetSection(title: "郵送交換") {
                    Text("合意後、取引に必要な相手にだけ住所情報を表示します。")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

private struct TradeSummaryTradeContent: View {
    var proposal: TradeProposal
    var requestedGoods: [GoodsItem]
    var offeredGoods: [GoodsItem]
    var requestedGoodsCount: Int
    var offeredGoodsCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            TradeSummarySheetSection(title: "交換内容") {
                VStack(spacing: 12) {
                    TradeSummaryGoodsSection(
                        title: "受け取る",
                        items: requestedGoods,
                        expectedCount: requestedGoodsCount,
                        cashOffer: proposal.cashOffer,
                        cashAmount: proposal.cashAmount
                    )

                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(MegrumTheme.lavender)
                        .frame(maxWidth: .infinity)

                    TradeSummaryGoodsSection(
                        title: "出す",
                        items: offeredGoods,
                        expectedCount: offeredGoodsCount,
                        cashOffer: false,
                        cashAmount: nil
                    )
                }
            }
        }
    }
}
