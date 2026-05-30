import MegrumCore
import MegrumDesign
import SwiftUI

struct GoodsCollectionScreen: View {
    var title: String
    var subtitle: String
    var items: [GoodsItem]
    var showsAddButton: Bool = false
    @State private var columns = 3
    @State private var isShowingAddPlaceholder = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    CollectionHeader(title: title, subtitle: subtitle, columns: $columns)
                    GoodsGrid(items: items, columns: columns)
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, showsAddButton ? 118 : 92)
            }
            .background(MegrumTheme.canvas.ignoresSafeArea())
            .megrumHiddenNavigationBar()

            if showsAddButton {
                AddGoodsButton {
                    isShowingAddPlaceholder = true
                }
                .padding(.leading, 24)
                .padding(.bottom, 22)
            }
        }
        .alert("追加画面は準備中です", isPresented: $isShowingAddPlaceholder) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\(title)の追加・編集フォームは次のSwift移行スライスで接続します。")
        }
    }
}

struct WishCollectionScreen: View {
    var items: [WishItem]

    private var goodsLikeItems: [GoodsItem] {
        items.map {
            GoodsItem(
                id: $0.id,
                ownerID: $0.ownerID,
                groupID: $0.groupID,
                memberID: $0.memberID,
                goodsTypeID: $0.goodsTypeID,
                title: $0.title,
                tags: $0.tags
            )
        }
    }

    var body: some View {
        GoodsCollectionScreen(
            title: "Wish",
            subtitle: "ほしいグッズ",
            items: goodsLikeItems,
            showsAddButton: true
        )
    }
}

private struct CollectionHeader: View {
    var title: String
    var subtitle: String
    @Binding var columns: Int

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)

                Text(subtitle)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            }

            Spacer()

            ColumnToggleButton(columns: $columns)
                .padding(.top, 3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ColumnToggleButton: View {
    @Binding var columns: Int

    var body: some View {
        Button {
            columns = columns >= 5 ? 3 : columns + 1
        } label: {
            HStack(spacing: 3) {
                ForEach(0..<columns, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .strokeBorder(MegrumTheme.ink, lineWidth: 2)
                        .frame(width: 9, height: 14)
                }
            }
            .frame(width: 54, height: 44)
            .background(.regularMaterial, in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(.white.opacity(0.58), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("表示列数を変更")
        .accessibilityValue("\(columns)列")
    }
}

private struct AddGoodsButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 68, height: 68)
                .background(
                    LinearGradient(
                        colors: [MegrumTheme.lavender, MegrumTheme.pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: Circle()
                )
                .overlay {
                    Circle()
                        .strokeBorder(.white.opacity(0.65), lineWidth: 1)
                }
                .shadow(color: MegrumTheme.ink.opacity(0.16), radius: 18, y: 10)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("追加")
    }
}

struct ScreenTitle: View {
    var title: String
    var subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 42, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Text(subtitle)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
