import MegrumDesign
import SwiftUI

/// ホーム候補行 v3「需要ファースト」のモックアップ（VisualQA: home-demand-first）。
/// 強タグ＋結論一文の代わりに「相手があなたの何を求めているか」を主役にする。
/// 本実装前の見た目確認用。
struct HomeDemandFirstPreview: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                sectionTitle("推し×シリーズでマッチ")

                HomeDemandFirstRow(
                    label: "ニンニン × #ネイル",
                    cardImages: ["aespa_ningning", "aespa_ningning_2"],
                    demand: .hotDemand(ownImage: "twice_sana_1", extraCount: 0),
                    logistics: "新宿で3/3に会えそう・郵送OK",
                    payment: nil
                )
                HomeDemandFirstRow(
                    label: "サナ × #キャンディボン",
                    cardImages: ["twice_sana_1", "twice_penlight"],
                    demand: .demand(ownImage: "twice_momo_1", extraCount: 2),
                    logistics: "東京で会えそう",
                    payment: nil
                )

                sectionTitle("推しでマッチ")

                HomeDemandFirstRow(
                    label: "ジミン",
                    cardImages: ["bts_jimin", "bts_v"],
                    demand: .cash(amount: 1_100),
                    logistics: "郵送OK・送料は相談",
                    payment: "PayPay・現金OK"
                )
                HomeDemandFirstRow(
                    label: "ジョングク",
                    cardImages: ["bts_jungkook"],
                    demand: .lookingFor(text: "サナのトレカを探し中"),
                    logistics: "郵送OK・送料込み",
                    payment: nil
                )
                HomeDemandFirstRow(
                    label: "ミンギュ",
                    cardImages: ["svt_mingyu", "svt_joshua"],
                    demand: .discuss,
                    logistics: "交換手段は相談",
                    payment: nil
                )
                HomeDemandFirstRow(
                    label: "モモ × #ラブリーズ",
                    cardImages: ["twice_momo_1", "twice_momo_2"],
                    demand: .cash(amount: nil),
                    logistics: "大阪で会えそう",
                    payment: "支払方法は要相談"
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 60)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("需要ファースト案 モック")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
            Text("激求 / 求 / 定価 / 探し中 / 相談 の5パターン")
                .font(.system(size: 12.5, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(MegrumTheme.ink)
            Spacer()
            HStack(spacing: 4) {
                Text("すべて見る")
                    .font(.system(size: 12.5, weight: .heavy))
                Image(systemName: "chevron.right")
                    .font(.system(size: 12.5, weight: .black))
            }
            .foregroundStyle(MegrumTheme.lavender)
        }
        .padding(.top, 6)
    }
}

/// 需要行の種別（仕様の優先順位どおり）。
enum HomeDemandFirstDemand {
    /// 相手があなたの具体グッズを指名
    case hotDemand(ownImage: String, extraCount: Int)
    /// あなたのグッズが相手の条件に一致
    case demand(ownImage: String, extraCount: Int)
    /// 定価交換選択肢あり
    case cash(amount: Int?)
    /// 合致なし：相手の探し物が分かる
    case lookingFor(text: String)
    /// 合致なし：相手の求めが不明
    case discuss
}

private struct HomeDemandFirstRow: View {
    var label: String
    var cardImages: [String]
    var demand: HomeDemandFirstDemand
    var logistics: String
    var payment: String?

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            fannedCard

            VStack(alignment: .leading, spacing: 6) {
                Text(label)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(MegrumTheme.ink.opacity(0.82))
                    .lineLimit(1)

                demandLine

                Text(logistics)
                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink.opacity(0.66))
                    .lineLimit(2)

                if let payment {
                    Text(payment)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink.opacity(0.52))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var fannedCard: some View {
        ZStack {
            ForEach(Array(cardImages.prefix(3).enumerated().reversed()), id: \.offset) { index, name in
                fixtureImage(name)
                    .frame(width: 92, height: 112)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [MegrumTheme.sky, MegrumTheme.lavender, MegrumTheme.pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    }
                    .rotationEffect(.degrees(Double(index) * 7 - 3))
                    .offset(x: CGFloat(index) * 18)
                    .shadow(color: MegrumTheme.ink.opacity(0.10), radius: 8, y: 4)
            }
        }
        .frame(width: 142, height: 112, alignment: .leading)
    }

    @ViewBuilder
    private var demandLine: some View {
        switch demand {
        case .hotDemand(let ownImage, let extraCount):
            demandText(
                prefix: "あなたの",
                image: ownImage,
                suffix: extraCount > 0 ? "他\(extraCount)点が激求！" : "が激求！",
                style: .hot
            )
        case .demand(let ownImage, let extraCount):
            demandText(
                prefix: "あなたの",
                image: ownImage,
                suffix: extraCount > 0 ? "他\(extraCount)点が求！" : "が求！",
                style: .normal
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
        case .lookingFor(let text):
            Text(text)
                .font(.system(size: 13.5, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink.opacity(0.62))
        case .discuss:
            Text("求めているものは打診で相談")
                .font(.system(size: 13.5, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink.opacity(0.62))
        }
    }

    private enum DemandStyle {
        case hot
        case normal
    }

    private func demandText(prefix: String, image: String, suffix: String, style: DemandStyle) -> some View {
        HStack(spacing: 4) {
            Text(prefix)
                .font(.system(size: 14.5, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink.opacity(0.88))

            fixtureImage(image)
                .frame(width: 22, height: 22)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(.white, lineWidth: 1.2)
                }
                .shadow(color: MegrumTheme.ink.opacity(0.16), radius: 3, y: 1)

            Text(suffix)
                .font(.system(size: 14.5, weight: .heavy, design: .rounded))
                .foregroundStyle(demandForeground(style))
        }
    }

    private func demandForeground(_ style: DemandStyle) -> AnyShapeStyle {
        switch style {
        case .hot:
            AnyShapeStyle(
                LinearGradient(
                    colors: [MegrumTheme.pink, Color(red: 0.94, green: 0.35, blue: 0.55)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        case .normal:
            AnyShapeStyle(MegrumTheme.lavender)
        }
    }

    @ViewBuilder
    private func fixtureImage(_ name: String) -> some View {
        if let url = HomeDiscoveryFixtures.imageURL(name)
            ?? HomeDiscoveryFixtures.imageURL(name, fileExtension: "jpg") {
            AsyncImage(url: url) { phase in
                if case .success(let image) = phase {
                    image.resizable().scaledToFill()
                } else {
                    MegrumTheme.lavender.opacity(0.16)
                }
            }
        } else {
            MegrumTheme.lavender.opacity(0.16)
        }
    }
}
