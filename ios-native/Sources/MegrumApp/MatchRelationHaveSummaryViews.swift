import MegrumCore
import MegrumDesign
import SwiftUI

struct MatchRelationHaveList: View {
    var detail: MatchRelationListingDetail
    var highlightedItemID: UUID
    var selectedHaveIDs: Set<UUID>
    var onToggleHave: (UUID) -> Void

    private var isInteractive: Bool {
        (detail.listing.haveLogic == .one || detail.listing.haveLogic == .atLeast) && detail.haves.count >= 2
    }

    private var visibleHaves: [MatchRelationHave] {
        let matched = detail.haves.filter { $0.matched || $0.item.id == highlightedItemID }
        return matched.isEmpty ? detail.haves : matched
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            MatchRelationFlowLayout(spacing: 8, rowSpacing: 8) {
                ForEach(visibleHaves) { have in
                    if isInteractive {
                        MatchRelationHaveButton(
                            have: have,
                            isSelected: selectedHaveIDs.contains(have.item.id),
                            isHighlighted: have.item.id == highlightedItemID,
                            onTap: {
                                onToggleHave(have.item.id)
                            }
                        )
                    } else {
                        MatchRelationHaveChip(
                            have: have,
                            isHighlighted: have.item.id == highlightedItemID
                        )
                    }
                }
            }

            if detail.haves.count > 1 {
                Text(logicHint)
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            }
        }
    }

    private var logicHint: String {
        switch detail.listing.haveLogic {
        case .all:
            return "全部まとめて"
        case .one:
            return "どれかを選択"
        case .atLeast:
            return "\(ListingLogic.minimumCountTitle(detail.listing.haveMinimumCount))を選択"
        }
    }
}

private struct MatchRelationHaveButton: View {
    var have: MatchRelationHave
    var isSelected: Bool
    var isHighlighted: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            MatchRelationHaveContent(
                have: have,
                isSelected: isSelected,
                isHighlighted: isHighlighted
            )
        }
        .buttonStyle(.plain)
    }
}

private struct MatchRelationHaveChip: View {
    var have: MatchRelationHave
    var isHighlighted: Bool

    var body: some View {
        MatchRelationHaveContent(
            have: have,
            isSelected: true,
            isHighlighted: isHighlighted
        )
    }
}

private struct MatchRelationHaveContent: View {
    var have: MatchRelationHave
    var isSelected: Bool
    var isHighlighted: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            MatchRelationGoodsThumbnail(item: have.item, size: 54)
                .overlay(alignment: .topTrailing) {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundStyle(MegrumTheme.ok)
                            .background(.white, in: Circle())
                            .offset(x: 4, y: -4)
                    }
                }
            Text(have.item.title)
                .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .lineLimit(2)
            if have.quantity > 1 {
                Text("×\(have.quantity)")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? MegrumTheme.lavender.opacity(0.12) : .white.opacity(0.62), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(isHighlighted ? MegrumTheme.pink.opacity(0.86) : .white.opacity(0.5), lineWidth: 1.2)
        }
    }
}

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

struct MatchRelationSimplePanel: View {
    var targetItem: GoodsItem
    var senderItems: [GoodsItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("譲る候補とWishのマッチ")
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

private struct MatchRelationFlowLayout<Content: View>: View {
    var spacing: CGFloat = 8
    var rowSpacing: CGFloat = 8
    var content: Content

    init(spacing: CGFloat = 8, rowSpacing: CGFloat = 8, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.rowSpacing = rowSpacing
        self.content = content()
    }

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 86), spacing: spacing)],
            alignment: .leading,
            spacing: rowSpacing
        ) {
            content
        }
    }
}

struct MatchRelationGoodsThumbnail: View {
    var item: GoodsItem
    var size: CGFloat?

    var body: some View {
        Group {
            if let imageURL = item.imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .empty:
                        ProgressView()
                            .tint(MegrumTheme.lavender)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case .failure:
                        fallback
                    @unknown default:
                        fallback
                    }
                }
            } else {
                fallback
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .background(MegrumTheme.lavender.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var fallback: some View {
        ZStack {
            LinearGradient(
                colors: [MegrumTheme.lavender.opacity(0.72), MegrumTheme.pink.opacity(0.48)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Text(String(item.title.prefix(1)))
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
        }
    }
}
