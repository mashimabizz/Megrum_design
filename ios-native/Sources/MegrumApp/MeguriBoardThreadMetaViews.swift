import MegrumCore
import MegrumDesign
import SwiftUI

struct MeguriThreadListRowTrailingMeta: View {
    var grooms: [GroomPost]
    var replyCount: Int
    var tagTitle: String

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            MeguriBoardAvatarStack(grooms: grooms, size: 20)

            HStack(spacing: 6) {
                Image(systemName: "bubble")
                    .font(.system(size: 16, weight: .medium))
                Text("\(replyCount)")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
            }
            .foregroundStyle(MegrumTheme.ink.opacity(0.64))

            Text(tagTitle)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .padding(.horizontal, 12)
                .frame(height: 23)
                .background(MegrumTheme.lavender.opacity(0.10), in: Capsule())
        }
    }
}

struct MeguriBoardAvatarStack: View {
    var grooms: [GroomPost]
    var size: CGFloat

    var body: some View {
        HStack(spacing: -5) {
            ForEach(grooms) { groom in
                GroomThumbnailCircle(url: groom.imageURL, size: size)
                    .overlay(Circle().stroke(.white, lineWidth: 1.4))
            }
            if grooms.isEmpty {
                Circle()
                    .fill(MegrumTheme.lavender.opacity(0.12))
                    .frame(width: size, height: size)
            }
        }
    }
}
