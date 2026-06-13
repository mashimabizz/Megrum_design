import MegrumDesign
import SwiftUI

struct HomeLocalStatusBadge: View {
    var status: HomeLocalActivityStatus

    var body: some View {
        Label {
            Text(status.label)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
        } icon: {
            Image(systemName: status.isLive ? "location.circle.fill" : "location.circle")
                .font(.system(size: 13, weight: .heavy))
        }
        .labelStyle(.titleAndIcon)
        .foregroundStyle(status.isLive ? Color.white : MegrumTheme.lavender)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(status.isLive ? MegrumTheme.lavender : MegrumTheme.lavender.opacity(0.12), in: Capsule())
    }
}

struct HomeLocalPublicPreviewRow: View {
    var preview: HomeLocalPublicPreview

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: preview.isVisible ? "eye.fill" : "eye.slash")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(preview.isVisible ? MegrumTheme.lavender : MegrumTheme.muted)
                .frame(width: 22, height: 22)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(preview.badgeText)
                        .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                        .foregroundStyle(preview.isVisible ? MegrumTheme.lavender : MegrumTheme.muted)

                    Text(preview.title)
                        .font(.system(size: 12.5, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineLimit(1)
                }

                Text(preview.detail)
                    .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(Color.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct HomeLocalPublicPreviewListRow: View {
    var preview: HomeLocalPublicPreview

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 3) {
                Text(preview.title)
                    .font(.body.weight(.semibold))
                Text(preview.detail)
                    .font(.caption)
                    .foregroundStyle(MegrumTheme.muted)
            }
        } icon: {
            Image(systemName: preview.isVisible ? "eye.fill" : "eye.slash")
                .foregroundStyle(preview.isVisible ? MegrumTheme.lavender : MegrumTheme.muted)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(preview.badgeText)、\(preview.title)、\(preview.detail)")
    }
}

struct HomeLocalSyncStatusRow: View {
    var isLoading: Bool
    var isSaving: Bool

    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.72)
            Text(isSaving ? "現地交換モードを保存中" : "現地交換モードを読み込み中")
                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.5), in: Capsule())
    }
}

struct HomeLocalMetricChip: View {
    var systemImage: String
    var text: String

    var body: some View {
        Label {
            Text(text)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        } icon: {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(MegrumTheme.ink.opacity(0.82))
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.68), in: Capsule())
    }
}
