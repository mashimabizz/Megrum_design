import MegrumDesign
import SwiftUI

struct SearchSuggestionTagWrap: View {
    var items: [SearchSuggestionItem]
    var selectedActions: Set<SearchSuggestionAction>
    var tint: Color
    var onSelect: (SearchSuggestionAction) -> Void

    var body: some View {
        WrappingTagFlow(spacing: 8, rowSpacing: 9) {
            ForEach(items) { item in
                SearchSuggestionTagButton(
                    title: item.title,
                    tint: tint,
                    isSelected: selectedActions.contains(item.action),
                    action: {
                        onSelect(item.action)
                    }
                )
            }
        }
    }
}

private struct SearchSuggestionTagButton: View {
    var title: String
    var tint: Color
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14.5, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .foregroundStyle(isSelected ? .white : MegrumTheme.ink)
                .padding(.horizontal, 14)
                .frame(minHeight: 38)
                .background(isSelected ? tint : Color.white.opacity(0.90), in: Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(isSelected ? tint.opacity(0.68) : MegrumTheme.lavender.opacity(0.18), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint("検索条件に追加します")
    }
}
