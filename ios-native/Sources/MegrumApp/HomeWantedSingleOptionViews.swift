import MegrumDesign
import SwiftUI

/// 相手の希望（相手の個別募集の求めるもの）が1件だけのとき、選ぶカードではなく
/// 1行の文脈として見せるためのモデル。2件以上は従来どおり選択カードを出す。iter1226.372。
struct HomeWantedSingleOptionSummary: Equatable {
    enum Kind: Equatable {
        case condition
        case goods
        case cash
    }

    var kind: Kind
    var text: String
    var imageURL: URL?
    var isTentative: Bool
}

/// 単一選択肢の相手希望を1行で見せる文脈行。タップ選択はさせず、下の「譲るグッズを選ぶ」へ直行させる。
struct HomeWantedSingleOptionContextRow: View {
    var summary: HomeWantedSingleOptionSummary

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "person")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text("相手が求めるもの")
                    .font(.system(size: 11.5, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)

                HStack(alignment: .center, spacing: 8) {
                    leadingAccessory
                    Text(displayText)
                        .font(.system(size: 13.5, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("相手が求めるもの、" + displayText)
    }

    @ViewBuilder
    private var leadingAccessory: some View {
        switch summary.kind {
        case .goods:
            if let imageURL = summary.imageURL {
                ListingGoodsImage(url: imageURL, title: summary.text, cornerRadius: 8)
                    .frame(width: 36, height: 36)
            } else {
                tokenChip(systemName: "bookmark.fill", label: "指名")
            }
        case .condition:
            tokenChip(systemName: "slider.horizontal.3", label: summary.isTentative ? "条件（？）" : "条件")
        case .cash:
            tokenChip(systemName: "yensign", label: "定価")
        }
    }

    private func tokenChip(systemName: String, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemName)
                .font(.system(size: 10.5, weight: .heavy))
            Text(label)
                .font(.system(size: 11, weight: .black, design: .rounded))
        }
        .foregroundStyle(MegrumTheme.lavender)
        .padding(.horizontal, 8)
        .frame(height: 24)
        .background(MegrumTheme.lavender.opacity(0.1), in: Capsule())
    }

    private var displayText: String {
        summary.isTentative && summary.kind == .condition
            ? summary.text + "（シリーズ未確認）"
            : summary.text
    }
}
