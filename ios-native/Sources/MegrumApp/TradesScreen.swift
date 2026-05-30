import MegrumCore
import MegrumDesign
import SwiftUI

struct TradesScreen: View {
    var proposals: [TradeProposal]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ScreenTitle(title: "やりとり", subtitle: "進行中の取引")

                ForEach(proposals) { proposal in
                    TradeCard(proposal: proposal)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 92)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .megrumHiddenNavigationBar()
    }
}

private struct TradeCard: View {
    var proposal: TradeProposal

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(statusText)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(MegrumTheme.sky.opacity(0.28), in: Capsule())

                Spacer()

                Text(proposal.exchangeMethod.displayName)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
            }

            HStack {
                TradePreviewColumn(title: "受け取る", symbol: "arrow.down.left")
                Spacer()
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(MegrumTheme.lavender)
                Spacer()
                TradePreviewColumn(title: "私が出す", symbol: "arrow.up.right")
            }

            if !proposal.conditionTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(proposal.conditionTags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(MegrumTheme.ink)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.white.opacity(0.72), in: Capsule())
                        }
                    }
                }
            }
        }
        .padding(18)
        .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(.black.opacity(0.05), lineWidth: 1))
        .shadow(color: MegrumTheme.ink.opacity(0.06), radius: 16, y: 8)
    }

    private var statusText: String {
        switch proposal.status {
        case .draft:
            "下書き"
        case .sent:
            "打診中"
        case .negotiating:
            "調整中"
        case .agreementOneSide:
            "合意待ち"
        case .agreed:
            "進行中"
        case .rejected:
            "拒否済"
        case .expired:
            "期限切れ"
        }
    }
}

private struct TradePreviewColumn: View {
    var title: String
    var symbol: String

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(MegrumTheme.sky.opacity(0.18))
                .frame(width: 74, height: 74)
                .overlay {
                    Image(systemName: symbol)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(MegrumTheme.lavender)
                }
        }
    }
}
