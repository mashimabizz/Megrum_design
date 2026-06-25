import MegrumDesign
import SwiftUI

struct HomeMutualMatchConditionHelpPopover: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("タグの見方")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    Text("相互マッチはグッズ条件で候補に残し、交換条件・支払条件は相談が必要な点だけをタグで出します。")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 10) {
                    helpRow(
                        tag: "交換条件不一致",
                        detail: "片方が現地交換のみ、もう片方が郵送交換のみなど、共通の交換手段がない場合。"
                    )
                    helpRow(
                        tag: "要相談",
                        detail: "双方が現地交換・郵送OKなど、交換手段が一意に決まらない場合。片方が現地/郵送を指定していればその手段で決まります。"
                    )
                    helpRow(
                        tag: "交換場所要相談 / 都道府県未設定",
                        detail: "現地交換で都道府県が違う、または片方の都道府県が未設定の場合。"
                    )
                    helpRow(
                        tag: "日程要相談",
                        detail: "片方でも日程が相談になっている、日程が合わない、または1日に決まらない場合。"
                    )
                    helpRow(
                        tag: "送料要相談",
                        detail: "郵送交換で、どちらかの送料負担が要相談になっている場合。"
                    )
                    helpRow(
                        tag: "金額込み候補 / 金額不足",
                        detail: "定価・金額指定を含む候補です。提示金額が足りない場合は金額不足になります。"
                    )
                    helpRow(
                        tag: "支払条件のタグ",
                        detail: "金額条件がある時だけ確認します。共通手段がない、未設定、その他のみの場合に相談タグが出ます。"
                    )
                }
            }
            .padding(18)
        }
        .frame(width: 320, height: 430)
        .background(MegrumTheme.canvas)
    }

    private func helpRow(tag: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(tag)
                .font(.system(size: 12.5, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
            Text(detail)
                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
