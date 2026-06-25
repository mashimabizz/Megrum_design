import MegrumCore
import MegrumDesign
import SwiftUI

struct MeguriThreadListRow: View {
    var thread: BoardThread
    var grooms: [GroomPost]
    var replyCount: Int
    var index: Int

    var body: some View {
        normalBody
    }

    private var normalBody: some View {
        HStack(spacing: 14) {
            MeguriThreadThumbnail(
                thread: thread,
                imageURL: thread.thumbnailURL ?? primaryGroom?.imageURL,
                size: 58
            )

            VStack(alignment: .leading, spacing: 7) {
                Text(thread.title)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)
                Text(thread.body)
                    .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink.opacity(0.72))
                    .lineLimit(2)
            }

            Spacer()

            MeguriThreadListRowTrailingMeta(
                grooms: avatarGrooms,
                replyCount: replyCount,
                tagTitle: thread.listTagTitle
            )

            Image(systemName: "chevron.forward")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(MegrumTheme.ink.opacity(0.72))
        }
        .frame(height: 96)
    }

    private var expandedBody: some View {
        HStack(spacing: 14) {
            MeguriThreadThumbnail(
                thread: thread,
                imageURL: thread.thumbnailURL ?? primaryGroom?.imageURL,
                size: 60
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(thread.title)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)
                Text(thread.body)
                    .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink.opacity(0.72))
                    .lineLimit(2)
                MeguriBoardAvatarStack(grooms: avatarGrooms, size: 20)
            }

            Spacer()

            HStack(spacing: 7) {
                Image(systemName: "bubble")
                    .font(.system(size: 18, weight: .medium))
                Text("\(replyCount)")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .lineLimit(1)
            }
            .frame(width: 64, alignment: .leading)
            .foregroundStyle(MegrumTheme.ink.opacity(0.64))

            Image(systemName: "chevron.forward")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(MegrumTheme.ink.opacity(0.72))
        }
        .frame(height: 78)
    }

    private var primaryGroom: GroomPost? {
        guard !grooms.isEmpty else { return nil }
        return grooms[index % grooms.count]
    }

    private var avatarGrooms: [GroomPost] {
        guard !grooms.isEmpty else { return [] }
        return (0..<min(3, grooms.count)).map { offset in
            grooms[(index + offset) % grooms.count]
        }
    }
}

private struct MeguriThreadThumbnail: View {
    var thread: BoardThread
    var imageURL: URL?
    var size: CGFloat

    var body: some View {
        if let imageURL {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    fallback
                default:
                    ProgressView()
                        .tint(MegrumTheme.lavender)
                }
            }
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        } else {
            fallback
        }
    }

    private var fallback: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(MegrumTheme.lavender.opacity(0.14))
            .frame(width: size, height: size)
            .overlay {
                Text(thread.title.first.map(String.init) ?? "話")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
            }
    }
}

struct MeguriInlineEmptyState: View {
    var systemImage: String
    var title: String
    var message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(MegrumTheme.lavender)

            Text(title)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Text(message)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(MegrumTheme.lavender.opacity(0.12), lineWidth: 1)
        }
    }
}

private extension BoardThread {
    var listTagTitle: String {
        if title.contains("物販") {
            return "物販エリア"
        }
        if title.contains("終演") || title.contains("会場") {
            return "会場横"
        }
        if title.contains("開封") {
            return "めぐり広場"
        }
        if audience == .samePrefecture, let prefecture {
            return prefecture
        }
        return "同じ現場"
    }
}
