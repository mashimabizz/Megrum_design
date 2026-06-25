import MegrumCore
import MegrumDesign
import SwiftUI

struct SearchResultGridCard: View {
    var item: GoodsItem
    var goods: HomeMockGoods
    var conditionTags: HomeConditionTagSet
    var viewerID: UUID?
    var onOpen: () -> Void
    var onReport: () -> Void

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: 7) {
                HomeGoodsArtwork(goods: goods)
                    .aspectRatio(0.82, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: MegrumTheme.ink.opacity(0.11), radius: 11, y: 7)

                SearchResultConditionTags(tags: conditionTags)
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            if item.ownerID != viewerID {
                Button(role: .destructive) {
                    onReport()
                } label: {
                    Label("通報する", systemImage: "exclamationmark.bubble")
                }
            }
        }
        .accessibilityLabel(item.title)
        .accessibilityHint("詳細を開きます")
    }
}

struct SearchResultConditionTags: View {
    var tags: HomeConditionTagSet

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                SearchResultMiniConditionPill(title: tags.goods.floatingTagTitle, color: tags.goods.accent)
                if tags.homeCandidateShowsExchangeTag {
                    SearchResultMiniConditionPill(title: tags.exchange.floatingTagTitle, color: tags.exchange.accent)
                }
            }
            SearchResultMiniConditionPill(title: tags.payment.floatingTagTitle, color: tags.payment.accent)
        }
        .accessibilityLabel(tags.homeCandidateAccessibilityText)
    }
}

struct SearchResultMiniConditionPill: View {
    var title: String
    var color: Color

    var body: some View {
        Text(title)
            .font(.system(size: 9.5, weight: .black, design: .rounded))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(.white.opacity(0.86), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(color.opacity(0.24), lineWidth: 1)
            }
    }
}
