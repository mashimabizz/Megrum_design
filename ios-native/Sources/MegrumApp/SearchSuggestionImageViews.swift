import MegrumDesign
import SwiftUI

struct SearchWishSuggestionImageRow: View {
    var items: [SearchSuggestionItem]
    var selectedActions: Set<SearchSuggestionAction>
    var tint: Color
    var onSelect: (SearchSuggestionAction) -> Void
    var onHorizontalDrag: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(items) { item in
                    SearchSuggestionImageChip(
                        item: item,
                        tint: tint,
                        isSelected: selectedActions.contains(item.action),
                        action: {
                            onSelect(item.action)
                        }
                    )
                }
            }
            .padding(.vertical, 2)
        }
        .simultaneousGesture(horizontalScrollSuppressionGesture, including: .gesture)
    }

    private var horizontalScrollSuppressionGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard SearchBackSwipeResolver.isNestedHorizontalScroll(translation: value.translation) else {
                    return
                }
                onHorizontalDrag()
            }
            .onEnded { value in
                guard SearchBackSwipeResolver.isNestedHorizontalScroll(translation: value.translation) else {
                    return
                }
                onHorizontalDrag()
            }
    }
}

private struct SearchSuggestionImageChip: View {
    var item: SearchSuggestionItem
    var tint: Color
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 7) {
                SearchSuggestionArtwork(
                    imageURL: item.imageURL,
                    systemImageName: item.systemImageName,
                    title: item.title,
                    tint: tint
                )
                .frame(width: 82, height: 82)

                Text(item.title)
                    .font(.system(size: 12.5, weight: .heavy, design: .rounded))
                    .foregroundStyle(isSelected ? MegrumTheme.lavender : MegrumTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
            }
            .frame(width: 88)
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(MegrumTheme.lavender, in: Circle())
                        .offset(x: 2, y: -2)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.title)
        .accessibilityHint("検索条件に追加します")
    }
}

private struct SearchSuggestionArtwork: View {
    var imageURL: URL?
    var systemImageName: String?
    var title: String
    var tint: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(tint.opacity(0.16))
            .overlay {
                if let imageURL {
                    GoodsRemoteImage(url: imageURL, cornerRadius: 22, placeholderIconSize: 24)
                } else {
                    VStack(spacing: 5) {
                        Image(systemName: systemImageName ?? "sparkles")
                            .font(.system(size: 26, weight: .heavy))
                        Text(String(title.prefix(1)))
                            .font(.system(size: 20, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(tint)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(.white.opacity(0.72), lineWidth: 1)
            }
    }
}
