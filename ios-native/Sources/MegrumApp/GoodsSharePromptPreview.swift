import MegrumCore
import MegrumDesign
import SwiftUI

struct GoodsSharePromptPreview: View {
    var items: [GoodsItem]

    private var previewItems: [GoodsItem] {
        Array(items.prefix(4))
    }

    var body: some View {
        HStack(spacing: -10) {
            ForEach(previewItems) { item in
                GoodsSharePromptThumbnail(url: item.imageURL)
                    .overlay(Circle().stroke(.white, lineWidth: 3))
                    .shadow(color: MegrumTheme.ink.opacity(0.10), radius: 10, y: 5)
            }

            if items.count > previewItems.count {
                Text("+\(items.count - previewItems.count)")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white)
                    .frame(width: 58, height: 58)
                    .background(MegrumTheme.lavender, in: Circle())
                    .overlay(Circle().stroke(.white, lineWidth: 3))
                    .shadow(color: MegrumTheme.ink.opacity(0.10), radius: 10, y: 5)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel("\(items.count)件のマイグッズ")
    }
}
