import SwiftUI

struct FlowLayout<Content: View>: View {
    var minimumItemWidth: CGFloat = 68
    var spacing: CGFloat = 8
    var rowSpacing: CGFloat = 8
    var content: Content

    init(
        minimumItemWidth: CGFloat = 68,
        spacing: CGFloat = 8,
        rowSpacing: CGFloat = 8,
        @ViewBuilder content: () -> Content
    ) {
        self.minimumItemWidth = minimumItemWidth
        self.spacing = spacing
        self.rowSpacing = rowSpacing
        self.content = content()
    }

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: minimumItemWidth), spacing: spacing)],
            alignment: .leading,
            spacing: rowSpacing
        ) {
            content
        }
    }
}
