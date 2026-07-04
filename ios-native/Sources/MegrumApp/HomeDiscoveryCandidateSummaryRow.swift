import MegrumDesign
import SwiftUI

enum HomeDiscoveryCandidateSummaryRowMetrics {
    static let rotaryWidth: CGFloat = 142
    static let rotaryHeight: CGFloat = 112
    static let labeledColumnWidth: CGFloat = rotaryWidth + 24
}

/// ホーム候補の1行表示（案2）：塊ラベル（画像上の中央）＋扇状カードと、
/// 強タグ1個＋結論一文を横並びにする。`mirrored` で左右反転
/// （「推しでマッチ」用。タグと文は画像側へ寄せる）。
/// ロータリーを回すとタグ・一文も選択中グッズのものに切り替わる。
struct HomeDiscoveryCandidateSummaryRow: View {
    var candidate: HomeDiscoveryCandidate
    var titleStyle: HomeDiscoveryCardTitleStyle
    var mirrored: Bool
    var onSelect: (HomeDiscoverySheet) -> Void
    var onSearch: (HomeDiscoveryCandidate, HomeMockGoods?) -> Void

    @State private var presentationState = HomeDiscoveryCandidateButtonPresentationState()

    private var orderedGoods: [HomeMockGoods] {
        HomeCandidateSummaryPolicy.orderedGoodsByRank(of: candidate)
    }

    private var selectedSignals: HomeCandidateConditionSignals {
        candidate.conditionSignals(for: presentationState.resolvedSelectedGoods(in: orderedGoods))
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            if mirrored {
                infoColumn
                labeledRotaryCard
            } else {
                labeledRotaryCard
                infoColumn
            }
        }
        .onAppear {
            presentationState.hydrateIfNeeded(goods: orderedGoods)
        }
        .onChange(of: candidate.goods.map(\.id)) { _, _ in
            presentationState.resetSelection(goods: orderedGoods)
        }
    }

    private var labeledRotaryCard: some View {
        VStack(spacing: 4) {
            Button {
                onSearch(candidate, presentationState.resolvedSelectedGoods(in: orderedGoods))
            } label: {
                Text(cardTitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(MegrumTheme.ink.opacity(0.82))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(cardTitle)で検索")

            HomeDiscoveryRotaryCard(
                goods: orderedGoods,
                goodsCondition: candidate.goodsCondition,
                exchangeCondition: candidate.exchangeCondition,
                paymentCondition: candidate.paymentCondition,
                conditionTagsForGoods: { goods in
                    candidate.conditionTags(for: goods)
                },
                showsConditionOverlay: false,
                onSelectionChange: { goods in
                    presentationState.select(goods)
                },
                onActivate: { goods in
                    onSelect(candidate.sheet(selectedGoods: goods))
                }
            )
            .frame(
                width: HomeDiscoveryCandidateSummaryRowMetrics.rotaryWidth,
                height: HomeDiscoveryCandidateSummaryRowMetrics.rotaryHeight
            )
        }
        .frame(width: HomeDiscoveryCandidateSummaryRowMetrics.labeledColumnWidth)
    }

    private var infoColumn: some View {
        let signals = selectedSignals
        let strongTag = HomeCandidateSummaryPolicy.strongTag(for: signals)
        let summary = HomeCandidateSummaryPolicy.summaryText(for: signals)

        return VStack(alignment: mirrored ? .trailing : .leading, spacing: 7) {
            HomeCandidateStrongTagBadge(tag: strongTag)
            Text(summary)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink.opacity(0.8))
                .multilineTextAlignment(mirrored ? .trailing : .leading)
                .lineLimit(3)
                .minimumScaleFactor(0.88)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: mirrored ? .trailing : .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(strongTag.title)、\(summary)")
    }

    private var cardTitle: String {
        presentationState.cardTitle(
            candidateTitle: candidate.title,
            titleStyle: titleStyle,
            goods: orderedGoods
        )
    }
}

/// 案2の強タグ（1個だけ表示するバッジ）。トーンは従来3タグの視覚言語を
/// 踏襲し、「要相談」だけはグレー（無効に見える）を避けて淡いスカイ系。
struct HomeCandidateStrongTagBadge: View {
    var tag: HomeCandidateStrongTag

    var body: some View {
        switch tag.tone {
        case .exact:
            baseText
                .foregroundStyle(.white)
                .background(megrumGradient, in: Capsule())
                .overlay {
                    Capsule().strokeBorder(.white.opacity(0.42), lineWidth: 0.8)
                }
                .shadow(color: MegrumTheme.lavender.opacity(0.18), radius: 8, y: 4)
        case .possible:
            baseText
                .foregroundStyle(megrumGradient)
                .background(.white.opacity(0.96), in: Capsule())
                .overlay {
                    Capsule().strokeBorder(megrumGradient, lineWidth: 1.15)
                }
        case .discuss:
            baseText
                .foregroundStyle(MegrumTheme.ink.opacity(0.68))
                .background(MegrumTheme.sky.opacity(0.22), in: Capsule())
                .overlay {
                    Capsule().strokeBorder(MegrumTheme.sky.opacity(0.55), lineWidth: 1)
                }
        }
    }

    private var baseText: some View {
        Text(tag.title)
            .font(.system(size: 12.6, weight: .black, design: .rounded))
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 4.8)
    }

    private var megrumGradient: LinearGradient {
        LinearGradient(
            colors: [MegrumTheme.sky, MegrumTheme.lavender, MegrumTheme.pink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
