import MegrumDesign
import SwiftUI

/// ホーム候補カードの見せ方「案2（結論一文＋強タグ1個）」の検討用モックアップ。
/// 実際のホーム画面には影響しない比較専用画面。VisualQA の
/// `home-card-redesign` で直接起動する。左＝現行（3タグ）、右＝案2。
struct HomeCandidateRedesignPreview: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header

                ForEach(HomeCandidateRedesignState.allCases) { state in
                    stateSection(state)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 60)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ホーム候補カード 案2 モック")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
            Text("左＝現行（グッズ/交換/支払の3タグ）、右＝案2（強タグ1個＋結論一文）。文言・階層の検討用。")
                .font(.system(size: 12.5, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
    }

    private func stateSection(_ state: HomeCandidateRedesignState) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(state.sectionTitle)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Text(state.sectionCaption)
                    .font(.system(size: 11.5, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            }

            HStack(alignment: .top, spacing: 14) {
                currentStyleCard(state)
                    .frame(maxWidth: .infinity)
                redesignCard(state)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func currentStyleCard(_ state: HomeCandidateRedesignState) -> some View {
        VStack(spacing: 0) {
            cardTitle(state)
            rotaryCard(state)
            HomeDiscoveryCandidateConditionTags(conditionTags: state.conditionTags)
                .padding(.top, 2)
        }
    }

    private func redesignCard(_ state: HomeCandidateRedesignState) -> some View {
        VStack(spacing: 0) {
            cardTitle(state)
            rotaryCard(state)
            HomeCandidateRedesignBadge(title: state.badgeTitle, tone: state.badgeTone)
                .padding(.top, 4)
            Text(state.summaryText)
                .font(.system(size: 12.2, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink.opacity(0.76))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity)
                .padding(.top, 5)
        }
    }

    private func cardTitle(_ state: HomeCandidateRedesignState) -> some View {
        Text(state.cardTitle)
            .font(.system(size: 14.5, weight: .regular))
            .foregroundStyle(MegrumTheme.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.68)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, 10)
    }

    private func rotaryCard(_ state: HomeCandidateRedesignState) -> some View {
        HomeDiscoveryRotaryCard(
            goods: state.goods,
            goodsCondition: state.conditionTags.goods,
            exchangeCondition: state.conditionTags.exchange,
            paymentCondition: state.conditionTags.payment,
            showsConditionOverlay: false
        )
        .frame(height: 150)
    }
}

/// 案2の強タグ（1個だけ表示するバッジ）。トーンは現行3タグの視覚言語を踏襲し、
/// 「要相談」だけはグレー（死んだ候補に見える）を避けて淡いスカイ系にする。
private struct HomeCandidateRedesignBadge: View {
    enum Tone {
        case exact
        case possible
        case discuss
    }

    var title: String
    var tone: Tone

    var body: some View {
        switch tone {
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
        Text(title)
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

private enum HomeCandidateRedesignState: String, CaseIterable, Identifiable {
    case perfect
    case designated
    case meetable
    case wishMatch
    case discuss

    var id: String { rawValue }

    var sectionTitle: String {
        switch self {
        case .perfect: "① ぴったり（全条件一致）"
        case .designated: "② 指名あり（グッズ◎・交換は要相談）"
        case .meetable: "③ 会えそう（現地条件が一致）"
        case .wishMatch: "④ wish一致（郵送OK）"
        case .discuss: "⑤ 要相談（従来の▲/?相当）"
        }
    }

    var sectionCaption: String {
        switch self {
        case .perfect: "現行: グッズ◎ 交換◎ 支払◎"
        case .designated: "現行: グッズ◎ 交換▲ 支払○"
        case .meetable: "現行: グッズ○ 交換◎ 支払○"
        case .wishMatch: "現行: グッズ○ 交換○ 支払?"
        case .discuss: "現行: グッズ▲ 交換▲ 支払? — 相手の実値を見せて判断を委ねる"
        }
    }

    var cardTitle: String {
        switch self {
        case .perfect: "サナ × トレカ"
        case .designated: "モモ × 缶バッジ"
        case .meetable: "サナ × アクスタ"
        case .wishMatch: "モモ × トレカ"
        case .discuss: "サナ × キーホルダー"
        }
    }

    var goods: [HomeMockGoods] {
        switch self {
        case .perfect:
            [HomeDiscoveryFixtures.sanaLavender, HomeDiscoveryFixtures.sanaBadge, HomeDiscoveryFixtures.sanaStand]
        case .designated:
            [HomeDiscoveryFixtures.momoFanmi, HomeDiscoveryFixtures.momoFanmiAlt]
        case .meetable:
            [HomeDiscoveryFixtures.sanaStand, HomeDiscoveryFixtures.sanaLavender]
        case .wishMatch:
            [HomeDiscoveryFixtures.momoFanmiAlt, HomeDiscoveryFixtures.momoFanmiStand]
        case .discuss:
            [HomeDiscoveryFixtures.sanaKeychain, HomeDiscoveryFixtures.plush]
        }
    }

    var conditionTags: HomeConditionTagSet {
        switch self {
        case .perfect:
            HomeConditionTagSet(goods: .direct, exchange: .exact, payment: .exact)
        case .designated:
            HomeConditionTagSet(goods: .direct, exchange: .warning, payment: .compatible)
        case .meetable:
            HomeConditionTagSet(goods: .wish, exchange: .exact, payment: .compatible)
        case .wishMatch:
            HomeConditionTagSet(goods: .wish, exchange: .possible, payment: .unknown)
        case .discuss:
            HomeConditionTagSet(goods: .none, exchange: .warning, payment: .unknown)
        }
    }

    var badgeTitle: String {
        switch self {
        case .perfect: "ぴったり"
        case .designated: "指名あり"
        case .meetable: "会えそう"
        case .wishMatch: "wish一致"
        case .discuss: "要相談"
        }
    }

    var badgeTone: HomeCandidateRedesignBadge.Tone {
        switch self {
        case .perfect, .designated: .exact
        case .meetable, .wishMatch: .possible
        case .discuss: .discuss
        }
    }

    var summaryText: String {
        switch self {
        case .perfect:
            "あなたのグッズを指名中・大阪で7/12に会えそう"
        case .designated:
            "あなたのグッズを指名中・場所は相談（相手: 東京）"
        case .meetable:
            "横浜アリーナで7/2に交換できそう"
        case .wishMatch:
            "あなたのウィッシュと一致・郵送OK"
        case .discuss:
            "日程は相談（相手: 週末なら可）"
        }
    }
}
