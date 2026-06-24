import SwiftUI

struct WrappingTagFlow<Content: View>: View {
    var spacing: CGFloat = 8
    var rowSpacing: CGFloat = 8
    var content: Content

    init(spacing: CGFloat = 8, rowSpacing: CGFloat = 8, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.rowSpacing = rowSpacing
        self.content = content()
    }

    var body: some View {
        WrappingTagLayout(spacing: spacing, rowSpacing: rowSpacing) {
            content
        }
    }
}

private struct WrappingTagLayout: Layout {
    var spacing: CGFloat
    var rowSpacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let rows = rows(for: subviews, maxWidth: proposal.width)
        let width = proposal.width ?? rows.map(\.width).max() ?? 0
        return CGSize(width: width, height: totalHeight(for: rows))
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let rows = rows(for: subviews, maxWidth: bounds.width)
        var y = bounds.minY

        for row in rows {
            var x = bounds.minX

            for item in row.items {
                subviews[item.index].place(
                    at: CGPoint(x: x, y: y + (row.height - item.size.height) / 2),
                    proposal: ProposedViewSize(width: item.size.width, height: item.size.height)
                )
                x += item.size.width + spacing
            }

            y += row.height + rowSpacing
        }
    }

    private func rows(for subviews: Subviews, maxWidth proposedMaxWidth: CGFloat?) -> [WrappingTagRow] {
        let maxWidth = max(0, proposedMaxWidth ?? .greatestFiniteMagnitude)
        var rows: [WrappingTagRow] = []
        var currentItems: [WrappingTagItem] = []
        var currentWidth: CGFloat = 0
        var currentHeight: CGFloat = 0

        for index in subviews.indices {
            let idealSize = subviews[index].sizeThatFits(.unspecified)
            let itemWidth = min(idealSize.width, maxWidth)
            let fittedSize = subviews[index].sizeThatFits(ProposedViewSize(width: itemWidth, height: nil))
            let item = WrappingTagItem(
                index: index,
                size: CGSize(width: itemWidth, height: fittedSize.height)
            )
            let nextWidth = currentItems.isEmpty ? item.size.width : currentWidth + spacing + item.size.width

            if !currentItems.isEmpty, nextWidth > maxWidth {
                rows.append(WrappingTagRow(items: currentItems, width: currentWidth, height: currentHeight))
                currentItems = [item]
                currentWidth = item.size.width
                currentHeight = item.size.height
            } else {
                currentItems.append(item)
                currentWidth = nextWidth
                currentHeight = max(currentHeight, item.size.height)
            }
        }

        if !currentItems.isEmpty {
            rows.append(WrappingTagRow(items: currentItems, width: currentWidth, height: currentHeight))
        }

        return rows
    }

    private func totalHeight(for rows: [WrappingTagRow]) -> CGFloat {
        guard !rows.isEmpty else {
            return 0
        }
        return rows.map(\.height).reduce(0, +) + rowSpacing * CGFloat(rows.count - 1)
    }
}

private struct WrappingTagRow {
    var items: [WrappingTagItem]
    var width: CGFloat
    var height: CGFloat
}

private struct WrappingTagItem {
    var index: Int
    var size: CGSize
}
