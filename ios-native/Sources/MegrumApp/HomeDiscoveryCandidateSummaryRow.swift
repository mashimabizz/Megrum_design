import MegrumDesign
import SwiftUI

enum HomeDiscoveryCandidateSummaryRowMetrics {
    static let rotaryWidth: CGFloat = 142
    static let rotaryHeight: CGFloat = 112
    static let partnerAvatarSize: CGFloat = 20
    static let demandThumbnailSize: CGFloat = 22
}

/// ホーム候補の1行表示（v3 需要ファースト・iter1226.294 モック確定版）：
/// 塊ラベルを画像上（左寄せ）に置き、右カラムは
/// 相手ユーザー行 → 需要行（激求/求/定価/探し中/相談）→ 物流行 → 支払行（定価絡みのみ）。
/// ロータリーを回すと右カラムも選択中グッズのものに切り替わる。
struct HomeDiscoveryCandidateSummaryRow: View {
    var candidate: HomeDiscoveryCandidate
    var titleStyle: HomeDiscoveryCardTitleStyle
    /// 需要行のサムネイル用：自分のグッズID→画像URL。
    var viewerGoodsImageURLByID: [UUID: URL] = [:]
    var onSelect: (HomeDiscoverySheet) -> Void
    var onSearch: (HomeDiscoveryCandidate, HomeMockGoods?) -> Void

    @State private var presentationState = HomeDiscoveryCandidateButtonPresentationState()
    /// 行タップの押下ハイライト（指を離す・スクロールで自動解除）。
    @GestureState private var isRowPressed = false

    private var orderedGoods: [HomeMockGoods] {
        HomeCandidateDemandPolicy.orderedGoodsByDemand(of: candidate)
    }

    private var selectedGoods: HomeMockGoods? {
        presentationState.resolvedSelectedGoods(in: orderedGoods)
    }

    private var selectedSignals: HomeCandidateConditionSignals {
        candidate.conditionSignals(for: selectedGoods)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                labelButton
                rotaryCard
            }
            infoColumn
        }
        .contentShape(Rectangle())
        .overlay {
            // 行のどこを押しても「押した」ことが分かるよう、押下中は薄いグレーを重ねる。
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(isRowPressed ? 0.06 : 0))
                .padding(.horizontal, -6)
                .allowsHitTesting(false)
        }
        .animation(.easeOut(duration: isRowPressed ? 0.08 : 0.24), value: isRowPressed)
        .simultaneousGesture(rowPressHighlightGesture)
        .onTapGesture {
            MegrumHaptics.buttonTap()
            onSelect(candidate.sheet(selectedGoods: selectedGoods))
        }
        .onAppear {
            presentationState.hydrateIfNeeded(goods: orderedGoods)
        }
        .onChange(of: candidate.goods.map(\.id)) { _, _ in
            presentationState.resetSelection(goods: orderedGoods)
        }
    }

    /// 押下ハイライト専用（タップ判定には関与しない）。大きく動いたら＝スクロールとみなして消す。
    private var rowPressHighlightGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($isRowPressed) { value, state, _ in
                let moved = abs(value.translation.width) > 12 || abs(value.translation.height) > 12
                state = !moved
            }
    }

    private var labelButton: some View {
        Button {
            onSearch(candidate, selectedGoods)
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
    }

    private var rotaryCard: some View {
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

    private var infoColumn: some View {
        let signals = selectedSignals
        let demand = HomeCandidateDemandPolicy.demandLine(for: signals)
        let logistics = HomeCandidateDemandPolicy.logisticsText(for: signals)
        let payment = HomeCandidateDemandPolicy.paymentText(for: signals)

        return VStack(alignment: .leading, spacing: 5) {
            partnerLine

            HomeCandidateDemandLineView(
                demand: demand,
                viewerGoodsImageURLByID: viewerGoodsImageURLByID
            )

            Text(logistics)
                .font(.system(size: 12.5, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink.opacity(0.66))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            if let payment {
                Text(payment)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink.opacity(0.52))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(cardTitle)、\(partnerName)、\(demandAccessibilityText(demand))、\(logistics)")
    }

    private var partnerLine: some View {
        HStack(spacing: 6) {
            HomeCandidatePartnerAvatar(url: selectedGoods?.ownerAvatarURL)

            Text(partnerName)
                .font(.system(size: 12.5, weight: .regular, design: .rounded))
                .foregroundStyle(MegrumTheme.ink.opacity(0.86))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
    }

    private var partnerName: String {
        selectedGoods?.ownerDisplayName?.nilIfBlank
            ?? selectedGoods?.ownerHandle?.nilIfBlank
            ?? "ユーザー"
    }

    private var cardTitle: String {
        presentationState.cardTitle(
            candidateTitle: candidate.title,
            titleStyle: titleStyle,
            goods: orderedGoods
        )
    }

    private func demandAccessibilityText(_ demand: HomeCandidateDemandLine) -> String {
        switch demand {
        case .hotDemand(let ids):
            ids.count > 1 ? "あなたのグッズ他\(ids.count - 1)点が激求" : "あなたのグッズが激求"
        case .demand(let ids):
            ids.count > 1 ? "あなたのグッズ他\(ids.count - 1)点が求" : "あなたのグッズが求"
        case .cash(let amount):
            amount.map { "定価（¥\($0.formatted())）と交換OK" } ?? "定価と交換OK"
        case .lookingFor(let text):
            "\(text)を探し中"
        case .discuss:
            "求めているものは打診で相談"
        }
    }
}

/// 需要行の表示。激求＝ピンクグラデ／求＝ラベンダー／定価＝スカイ→ラベンダーグラデ。
struct HomeCandidateDemandLineView: View {
    var demand: HomeCandidateDemandLine
    var viewerGoodsImageURLByID: [UUID: URL]

    var body: some View {
        switch demand {
        case .hotDemand(let goodsIDs):
            demandText(
                goodsIDs: goodsIDs,
                suffixBase: "が激求！",
                suffixStyle: AnyShapeStyle(
                    LinearGradient(
                        colors: [MegrumTheme.pink, Color(red: 0.94, green: 0.35, blue: 0.55)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            )
        case .demand(let goodsIDs):
            demandText(
                goodsIDs: goodsIDs,
                suffixBase: "が求！",
                suffixStyle: AnyShapeStyle(MegrumTheme.lavender)
            )
        case .cash(let amount):
            Text(amount.map { "定価（¥\($0.formatted())）と交換OK" } ?? "定価と交換OK")
                .font(.system(size: 14.5, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [MegrumTheme.sky, MegrumTheme.lavender],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        case .lookingFor(let text):
            Text("\(text)を探し中")
                .font(.system(size: 13.5, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink.opacity(0.62))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        case .discuss:
            Text("求めているものは打診で相談")
                .font(.system(size: 13.5, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink.opacity(0.62))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    private func demandText(
        goodsIDs: [UUID],
        suffixBase: String,
        suffixStyle: AnyShapeStyle
    ) -> some View {
        let extraCount = max(0, goodsIDs.count - 1)
        let suffix = extraCount > 0 ? "他\(extraCount)点\(suffixBase)" : suffixBase
        return HStack(spacing: 4) {
            Text("あなたの")
                .font(.system(size: 14.5, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink.opacity(0.88))

            HomeCandidateDemandThumbnail(url: goodsIDs.first.flatMap { viewerGoodsImageURLByID[$0] })

            Text(suffix)
                .font(.system(size: 14.5, weight: .heavy, design: .rounded))
                .foregroundStyle(suffixStyle)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

private struct HomeCandidateDemandThumbnail: View {
    var url: URL?

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image.resizable().scaledToFill()
                    } else {
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(
            width: HomeDiscoveryCandidateSummaryRowMetrics.demandThumbnailSize,
            height: HomeDiscoveryCandidateSummaryRowMetrics.demandThumbnailSize
        )
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(.white, lineWidth: 1.2)
        }
        .shadow(color: MegrumTheme.ink.opacity(0.16), radius: 3, y: 1)
    }

    private var placeholder: some View {
        MegrumTheme.lavender.opacity(0.16)
    }
}

private struct HomeCandidatePartnerAvatar: View {
    var url: URL?

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image.resizable().scaledToFill()
                    } else {
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(
            width: HomeDiscoveryCandidateSummaryRowMetrics.partnerAvatarSize,
            height: HomeDiscoveryCandidateSummaryRowMetrics.partnerAvatarSize
        )
        .clipShape(Circle())
        .overlay {
            Circle().strokeBorder(.white, lineWidth: 1.2)
        }
        .shadow(color: MegrumTheme.ink.opacity(0.14), radius: 3, y: 1)
    }

    private var placeholder: some View {
        ZStack {
            MegrumTheme.lavender.opacity(0.18)
            Image(systemName: "person.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(MegrumTheme.lavender.opacity(0.7))
        }
    }
}
