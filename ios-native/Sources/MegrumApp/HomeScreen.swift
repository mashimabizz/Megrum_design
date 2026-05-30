import MegrumCore
import MegrumDesign
import SwiftUI

struct HomeScreen: View {
    @Binding var showsSearch: Bool

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    HomeHeader()

                    MatchSection(
                        title: "マッチしてるよ！",
                        count: NativePreviewData.inventory.count,
                        items: NativePreviewData.inventory
                    )

                    MatchSection(
                        title: "交換できるかも？",
                        count: NativePreviewData.wishes.count,
                        items: NativePreviewData.inventory.reversed()
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 104)
            }
            .background(MegrumTheme.canvas.ignoresSafeArea())
            .megrumHiddenNavigationBar()

            LiquidGlassSearchButton {
                showsSearch = true
            }
            .padding(.leading, 24)
            .padding(.bottom, 22)
        }
    }
}

private struct HomeHeader: View {
    var body: some View {
        HStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [MegrumTheme.lavender, MegrumTheme.pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
                .overlay(
                    Text("M")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                )
                .accessibilityLabel("自分のアイコン")

            Spacer()

            Text("Megrum")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Spacer()

            Circle()
                .fill(Color.clear)
                .frame(width: 44, height: 44)
        }
    }
}

private struct MatchSection<Items: RandomAccessCollection>: View where Items.Element == GoodsItem, Items.Index == Int {
    var title: String
    var count: Int
    var items: Items

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.system(size: 25, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)

                Spacer()

                Text("\(count)件")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            }

            GoodsGrid(items: Array(items))
        }
    }
}
