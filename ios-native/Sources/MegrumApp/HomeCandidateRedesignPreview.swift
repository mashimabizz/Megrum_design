import MegrumDesign
import SwiftUI

/// ホーム候補カード「案2」（結論一文＋強タグ1個）の検討用モックアップ。
/// 実ホームのヘッダー・セクション構成をなぞり、候補は扇状カード＋強タグ＋
/// 結論一文の横並び行で見せる。各セクションは成立しやすい候補を多く含む
/// 塊が上に来る想定の並びで上位3件まで表示し、見出し横の「すべて見る」で
/// 全件一覧へ飛ぶ想定。「推しでマッチ」は見出しごと右寄せのミラー配置。
/// 実ホームには影響しない比較専用画面（VisualQA `home-card-redesign`）。
struct HomeCandidateRedesignPreview: View {
    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    sectionHeader("推し×シリーズでマッチ", mirrored: false)

                    ForEach(HomeCandidateRedesignRow.memberSeriesRows) { row in
                        HomeCandidateRedesignRowView(row: row, mirrored: false)
                    }

                    sectionHeader("推しでマッチ", mirrored: true)
                        .padding(.top, 6)

                    ForEach(HomeCandidateRedesignRow.memberRows) { row in
                        HomeCandidateRedesignRowView(row: row, mirrored: true)
                    }

                    havesRail
                        .padding(.top, 6)
                }
                .padding(.horizontal, 20)
                .padding(.top, 82)
                .padding(.bottom, 60)
            }

            pinnedHeader
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
    }

    /// 見出し＋「すべて見る」。見出し行はミラーせず常に「タイトル左・
    /// すべて見る右」で統一する（行のみミラー）。
    private func sectionHeader(_ title: String, mirrored _: Bool) -> some View {
        HStack(alignment: .firstTextBaseline) {
            headerTitle(title)
            Spacer()
            seeAllButton
        }
    }

    private func headerTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 18, weight: .heavy))
            .foregroundStyle(MegrumTheme.ink)
    }

    private var seeAllButton: some View {
        HStack(spacing: 3) {
            Text("すべて見る")
                .font(.system(size: 12.5, weight: .heavy))
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .black))
        }
        .foregroundStyle(MegrumTheme.lavender)
    }

    private var pinnedHeader: some View {
        VStack(spacing: 0) {
            HStack {
                Circle()
                    .fill(MegrumTheme.lavender.opacity(0.18))
                    .frame(width: 44, height: 44)
                    .overlay {
                        Text("m")
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                            .foregroundStyle(MegrumTheme.lavender)
                    }

                Spacer()
                MegrumWordmark(width: 116)
                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(MegrumTheme.lavender)
                        .frame(width: 44, height: 44)
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(MegrumTheme.lavender)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .padding(.top, 10)
        .frame(maxWidth: .infinity)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.72)
                .ignoresSafeArea(edges: .top)
        }
    }

    private var havesRail: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("求められているグッズ")
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(MegrumTheme.ink)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(HomeDiscoveryFixtures.havesRailGoods, id: \.id) { goods in
                        VStack(spacing: 6) {
                            HomeGoodsArtwork(goods: goods)
                                .frame(width: 94, height: 94)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                            Text("3件")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 3)
                                .background(MegrumTheme.lavender, in: Capsule())
                        }
                        .frame(width: 94)
                    }
                }
                .padding(.trailing, 20)
            }
        }
    }
}

private enum HomeCandidateRedesignRowMetrics {
    static let rotaryWidth: CGFloat = 142
    static let rotaryHeight: CGFloat = 112
}

/// 1候補分の行。「ラベル（画像上の中央）＋扇状カード」と「強タグ＋結論一文」
/// を横並びにする。`mirrored` で左右反転（推しでマッチ用）。ミラー時は
/// 強タグと文を画像側（右）へ寄せる。
private struct HomeCandidateRedesignRowView: View {
    var row: HomeCandidateRedesignRow
    var mirrored: Bool

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
    }

    private var labeledRotaryCard: some View {
        VStack(spacing: 4) {
            Text(row.subtitle)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(MegrumTheme.ink.opacity(0.82))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            HomeDiscoveryRotaryCard(
                goods: row.goods,
                goodsCondition: row.conditionTags.goods,
                exchangeCondition: row.conditionTags.exchange,
                paymentCondition: row.conditionTags.payment,
                showsConditionOverlay: false
            )
            .frame(
                width: HomeCandidateRedesignRowMetrics.rotaryWidth,
                height: HomeCandidateRedesignRowMetrics.rotaryHeight
            )
        }
        .frame(width: HomeCandidateRedesignRowMetrics.rotaryWidth + 24)
    }

    private var infoColumn: some View {
        VStack(alignment: mirrored ? .trailing : .leading, spacing: 7) {
            HomeCandidateRedesignBadge(title: row.badgeTitle, tone: row.badgeTone)
            Text(row.summaryText)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink.opacity(0.8))
                .multilineTextAlignment(mirrored ? .trailing : .leading)
                .lineLimit(3)
                .minimumScaleFactor(0.88)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: mirrored ? .trailing : .leading)
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

private struct HomeCandidateRedesignRow: Identifiable {
    var id: String { subtitle + summaryText }
    var subtitle: String
    var goods: [HomeMockGoods]
    var conditionTags: HomeConditionTagSet
    var badgeTitle: String
    var badgeTone: HomeCandidateRedesignBadge.Tone
    var summaryText: String

    /// 上位3件。塊（推し×シリーズ）内に成立しやすいグッズを多く含むものが
    /// 上に来る並びを想定した順。
    static let memberSeriesRows: [HomeCandidateRedesignRow] = [
        HomeCandidateRedesignRow(
            subtitle: "サナ × トレカ",
            goods: [
                HomeDiscoveryFixtures.sanaLavender,
                HomeDiscoveryFixtures.sanaBadge,
                HomeDiscoveryFixtures.sanaStand
            ],
            conditionTags: HomeConditionTagSet(goods: .direct, exchange: .exact, payment: .exact),
            badgeTitle: "ぴったり",
            badgeTone: .exact,
            summaryText: "あなたのグッズを指名中・大阪で7/12に会えそう"
        ),
        HomeCandidateRedesignRow(
            subtitle: "サナ × アクスタ",
            goods: [
                HomeDiscoveryFixtures.sanaStand,
                HomeDiscoveryFixtures.sanaLavender
            ],
            conditionTags: HomeConditionTagSet(goods: .wish, exchange: .exact, payment: .compatible),
            badgeTitle: "会えそう",
            badgeTone: .possible,
            summaryText: "横浜アリーナで7/2に交換できそう"
        ),
        HomeCandidateRedesignRow(
            subtitle: "サナ × キーホルダー",
            goods: [
                HomeDiscoveryFixtures.sanaKeychain,
                HomeDiscoveryFixtures.plush
            ],
            conditionTags: HomeConditionTagSet(goods: .none, exchange: .warning, payment: .unknown),
            badgeTitle: "要相談",
            badgeTone: .discuss,
            summaryText: "日程は相談（相手: 週末なら可）"
        )
    ]

    static let memberRows: [HomeCandidateRedesignRow] = [
        HomeCandidateRedesignRow(
            subtitle: "モモ",
            goods: [
                HomeDiscoveryFixtures.momoFanmi,
                HomeDiscoveryFixtures.momoFanmiAlt
            ],
            conditionTags: HomeConditionTagSet(goods: .direct, exchange: .warning, payment: .compatible),
            badgeTitle: "指名あり",
            badgeTone: .exact,
            summaryText: "あなたのグッズを指名中・場所は相談（相手: 東京）"
        ),
        HomeCandidateRedesignRow(
            subtitle: "モモ",
            goods: [
                HomeDiscoveryFixtures.momoFanmiAlt,
                HomeDiscoveryFixtures.momoFanmiStand
            ],
            conditionTags: HomeConditionTagSet(goods: .wish, exchange: .possible, payment: .unknown),
            badgeTitle: "wish一致",
            badgeTone: .possible,
            summaryText: "あなたのウィッシュと一致・郵送OK"
        ),
        HomeCandidateRedesignRow(
            subtitle: "ダヒョン",
            goods: [
                HomeDiscoveryFixtures.plush,
                HomeDiscoveryFixtures.sanaKeychain
            ],
            conditionTags: HomeConditionTagSet(goods: .none, exchange: .warning, payment: .unknown),
            badgeTitle: "要相談",
            badgeTone: .discuss,
            summaryText: "場所は相談（相手: 福岡）"
        )
    ]
}

extension HomeDiscoveryFixtures {
    fileprivate static var havesRailGoods: [HomeMockGoods] {
        [sanaLavender, sanaBadge, momoFanmi, momoFanmiAlt]
    }
}
