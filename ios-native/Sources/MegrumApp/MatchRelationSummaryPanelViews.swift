import MegrumCore
import MegrumDesign
import SwiftUI

struct MatchRelationSummaryPanel: View {
    var senderItems: [GoodsItem]
    var receiverItems: [GoodsItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("📋 結論：この交換")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(0.4)
                .foregroundStyle(MegrumTheme.lavender)
            HStack(spacing: 8) {
                MatchRelationSummarySide(title: "あなたが受", color: MegrumTheme.pink, items: receiverItems)
                Text("⇄")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                MatchRelationSummarySide(title: "あなたが譲", color: MegrumTheme.lavender, items: senderItems)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(MegrumTheme.lavender.opacity(0.04), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(MegrumTheme.lavender.opacity(0.34), lineWidth: 1)
        }
    }
}

struct MatchRelationSimplePanel: View {
    var targetItem: GoodsItem
    var senderItems: [GoodsItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("譲る候補とほしいもののマッチ")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
            HStack(spacing: 12) {
                MatchRelationSummarySide(title: "あなたが譲", color: MegrumTheme.lavender, items: senderItems)
                Text("⇄")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                MatchRelationSummarySide(title: "あなたが受", color: MegrumTheme.pink, items: [targetItem])
            }
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
        }
    }
}

private struct MatchRelationSummarySide: View {
    var title: String
    var color: Color
    var items: [GoodsItem]

    var body: some View {
        HStack(spacing: 5) {
            Text(title)
                .font(.system(size: 8.5, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .frame(height: 18)
                .background(color, in: Capsule())
            HStack(spacing: -8) {
                ForEach(items.prefix(4)) { item in
                    MatchRelationGoodsThumbnail(item: item, size: 28)
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(.white, lineWidth: 1.5)
                        }
                }
                if items.count > 4 {
                    Text("+\(items.count - 4)")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .padding(.horizontal, 8)
                        .frame(height: 24)
                        .background(.white.opacity(0.82), in: Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
