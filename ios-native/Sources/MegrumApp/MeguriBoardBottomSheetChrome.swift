import MegrumCore
import MegrumDesign
import SwiftUI

struct MeguriBoardSheetGrabber: View {
    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: 34)
            .overlay(alignment: .top) {
                Capsule()
                    .fill(MegrumTheme.muted.opacity(0.38))
                    .frame(width: 38, height: 5)
                    .padding(.top, 12)
            }
            .contentShape(Rectangle())
            .accessibilityHidden(true)
    }
}

struct MeguriBoardSheetTopSurface: View {
    var groomCount: Int
    var threadCount: Int
    var onOpenGroomComposer: () -> Void
    var onOpenThreadComposer: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            MeguriBoardQuickActionRow(
                title: "グルーム",
                subtitle: "\(groomCount)件の近くの投稿",
                systemImage: "camera",
                actionTitle: "投稿",
                action: onOpenGroomComposer
            )

            MeguriBoardQuickActionRow(
                title: "チャットルーム",
                subtitle: "\(threadCount)件の現地トピック",
                systemImage: "pencil",
                actionTitle: "作成",
                action: onOpenThreadComposer
            )
        }
    }
}

private struct MeguriBoardQuickActionRow: View {
    var title: String
    var subtitle: String
    var systemImage: String
    var actionTitle: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Label(title, systemImage: systemImage)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .labelStyle(.titleAndIcon)

                Spacer(minLength: 8)

                Text(subtitle)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text(actionTitle)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .padding(.horizontal, 12)
                    .frame(height: 28)
                    .background(MegrumTheme.lavender.opacity(0.10), in: Capsule())
            }
            .padding(.horizontal, 14)
            .frame(height: 54)
            .background(.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
