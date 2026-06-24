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
    var route: TradeSummaryDetailRoute
    var proposal: TradeProposal
    var requestedGoods: [GoodsItem]
    var offeredGoods: [GoodsItem]
    var requestedGoodsCount: Int
    var offeredGoodsCount: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch route {
                    case .exchangeMethod:
                        exchangeMethodContent
                    case .tradeContent:
                        tradeContent
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

    private var exchangeMethodContent: some View {
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

    private var tradeContent: some View {
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

private struct TradeSummarySheetSection<Content: View>: View {
    var title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(MegrumTheme.ink.opacity(0.07), lineWidth: 1)
        }
    }
}

private struct TradeMeetupCandidateSummaryRow: View {
    var index: Int
    var meetup: ProposalMeetupInput

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(index + 1)")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(MegrumTheme.lavender, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(meetup.placeName)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Text(timeText)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            }
        }
    }

    private var timeText: String {
        "\(meetup.startAt.formatted(.dateTime.month().day().hour().minute())) - \(meetup.endAt.formatted(.dateTime.hour().minute()))"
    }
}

private struct TradeSummaryGoodsSection: View {
    var title: String
    var items: [GoodsItem]
    var expectedCount: Int
    var cashOffer: Bool
    var cashAmount: Int?

    private var displayCount: Int {
        max(items.count, expectedCount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                Spacer()
                Text(countText)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
            }

            if cashOffer && items.isEmpty {
                TradeCashAmountPanel(cashAmount: cashAmount)
            } else if items.isEmpty && displayCount > 0 {
                TradeSummaryEmptyText("\(displayCount)点（詳細を読み込み中）")
            } else if items.isEmpty {
                TradeSummaryEmptyText("未設定")
            } else {
                VStack(spacing: 9) {
                    ForEach(items) { item in
                        TradeSummaryGoodsRow(item: item)
                    }
                }

                if cashOffer {
                    TradeCashAmountPanel(cashAmount: cashAmount)
                }
            }
        }
        .padding(12)
        .background(MegrumTheme.lavender.opacity(0.06), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
    }

    private var countText: String {
        if cashOffer && items.isEmpty && displayCount == 0 {
            return "定価"
        }
        return "\(displayCount)点"
    }
}

private struct TradeSummaryGoodsRow: View {
    var item: GoodsItem

    var body: some View {
        HStack(spacing: 10) {
            TradeSummaryGoodsThumb(item: item)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)
                Text(item.tags.first?.name ?? "グッズ")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            if item.quantity > 1 {
                Text("×\(item.quantity)")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
            }
        }
    }
}

private struct TradeSummaryGoodsThumb: View {
    var item: GoodsItem

    var body: some View {
        ZStack {
            if let imageURL = item.imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        fallback
                    case .empty:
                        MegrumTheme.lavender.opacity(0.08)
                    @unknown default:
                        fallback
                    }
                }
            } else {
                fallback
            }
        }
        .frame(width: 46, height: 46)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var fallback: some View {
        ZStack {
            LinearGradient(
                colors: [MegrumTheme.lavender.opacity(0.56), MegrumTheme.sky.opacity(0.42)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Text(item.title.first.map(String.init) ?? "M")
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
    }
}

private struct TradeCashAmountPanel: View {
    var cashAmount: Int?

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "yensign")
                .font(.system(size: 12, weight: .black))
            Text(cashText)
                .font(.system(size: 13, weight: .black, design: .rounded))
        }
        .foregroundStyle(MegrumTheme.ok)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(MegrumTheme.ok.opacity(0.11), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }

    private var cashText: String {
        TradeAmountFormatter.fixedPrice(amount: cashAmount, fallback: "定価交換")
    }
}

private struct TradeSummaryEmptyText: View {
    var text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(MegrumTheme.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension ExchangeMethod {
    var supportsHand: Bool {
        self == .hand || self == .both
    }

    var supportsMail: Bool {
        self == .mail || self == .both
    }
}
