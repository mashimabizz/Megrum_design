import MegrumCore
import MegrumDesign
import SwiftUI

struct HomeScreen: View {
    var viewer: UserProfile?
    var matchedItems: [GoodsItem]
    var possibleItems: [GoodsItem]
    var isLoading: Bool
    @Binding var showsSearch: Bool
    var onRefresh: () async -> Void

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    HomeHeader(viewer: viewer)

                    MatchSection(
                        title: "マッチしてるよ！",
                        count: matchedItems.count,
                        items: matchedItems,
                        isLoading: isLoading
                    )

                    MatchSection(
                        title: "交換できるかも？",
                        count: possibleItems.count,
                        items: possibleItems,
                        isLoading: isLoading
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 104)
            }
            .refreshable {
                await onRefresh()
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
    var viewer: UserProfile?

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
                    Text(initial)
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

    private var initial: String {
        guard let first = viewer?.displayName.first else {
            return "M"
        }
        return String(first)
    }
}

private struct MatchSection<Items: RandomAccessCollection>: View where Items.Element == GoodsItem, Items.Index == Int {
    var title: String
    var count: Int
    var items: Items
    var isLoading: Bool

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

            if isLoading && items.isEmpty {
                GoodsGridSkeleton()
            } else {
                GoodsGrid(items: Array(items))
            }
        }
    }
}

private struct GoodsGridSkeleton: View {
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(0..<6, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.white.opacity(0.72))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(.white.opacity(0.76), lineWidth: 1)
                    )
                    .aspectRatio(0.78, contentMode: .fit)
                    .redacted(reason: .placeholder)
            }
        }
    }
}
