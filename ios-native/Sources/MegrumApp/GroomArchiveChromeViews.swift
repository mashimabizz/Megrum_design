import MegrumCore
import MegrumDesign
import SwiftUI

struct GroomArchiveHeader: View {
    var count: Int
    var isLoading: Bool
    var onClose: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onClose) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(MegrumTheme.ink)
                    .frame(width: 46, height: 46)
                    .background(.regularMaterial, in: Circle())
                    .overlay(Circle().stroke(.white.opacity(0.7), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("戻る")

            VStack(alignment: .leading, spacing: 2) {
                Text("グルームアーカイブ")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Text(isLoading ? "読み込み中" : "\(count)件")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            }

            Spacer()

            if isLoading {
                ProgressView()
                    .tint(MegrumTheme.lavender)
                    .frame(width: 42, height: 42)
                    .background(.regularMaterial, in: Circle())
            }
        }
    }
}

struct GroomArchiveEmptyState: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "archivebox")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(width: 64, height: 64)
                .background(.white.opacity(0.94), in: Circle())
                .shadow(color: MegrumTheme.ink.opacity(0.08), radius: 12, y: 7)

            Text("過去のグルームはまだありません")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Text("投稿したグルームがここに地図で残ります。")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .multilineTextAlignment(.center)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.65), lineWidth: 1)
        }
    }
}

struct GroomArchiveThumbnailRail: View {
    var grooms: [GroomPost]
    var selectedGroomID: UUID?
    var onSelect: (GroomPost) -> Void

    var body: some View {
        if !grooms.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(grooms) { groom in
                        Button {
                            onSelect(groom)
                        } label: {
                            GroomArchiveThumbnail(groom: groom, isSelected: groom.id == selectedGroomID)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
            }
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.66), lineWidth: 1))
            .shadow(color: MegrumTheme.ink.opacity(0.12), radius: 18, y: 10)
        }
    }
}

struct GroomArchiveThumbnailOverview: View {
    var grooms: [GroomPost]
    var selectedGroomID: UUID?
    var onSelect: (GroomPost) -> Void

    var body: some View {
        if !grooms.isEmpty {
            GeometryReader { proxy in
                let metrics = GroomArchiveOverviewGridMetrics.metrics(
                    itemCount: grooms.count,
                    availableWidth: proxy.size.width
                )
                LazyVGrid(columns: metrics.columns, spacing: metrics.spacing) {
                    ForEach(grooms) { groom in
                        Button {
                            onSelect(groom)
                        } label: {
                            GroomArchiveOverviewThumbnail(
                                groom: groom,
                                isSelected: groom.id == selectedGroomID,
                                size: metrics.thumbnailSize
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .center)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(.white.opacity(0.66), lineWidth: 1)
                }
                .shadow(color: MegrumTheme.ink.opacity(0.12), radius: 18, y: 10)
            }
            .frame(height: GroomArchiveOverviewGridMetrics.containerHeight(itemCount: grooms.count))
        }
    }
}

enum GroomArchiveOverviewGridMetrics {
    static func metrics(itemCount: Int, availableWidth: CGFloat) -> (columns: [GridItem], spacing: CGFloat, thumbnailSize: CGFloat) {
        let count = max(itemCount, 1)
        let maxRows: CGFloat = count <= 10 ? 2 : 3
        let columnCount = max(1, Int(ceil(CGFloat(count) / maxRows)))
        let spacing: CGFloat = columnCount > 5 ? 8 : 12
        let horizontalPadding: CGFloat = 24
        let usableWidth = max(availableWidth - horizontalPadding - CGFloat(columnCount - 1) * spacing, 48)
        let itemSize = min(58, max(34, usableWidth / CGFloat(columnCount)))
        let columns = Array(repeating: GridItem(.fixed(itemSize), spacing: spacing), count: columnCount)
        return (columns, spacing, itemSize)
    }

    static func containerHeight(itemCount: Int) -> CGFloat {
        if itemCount <= 5 {
            return 94
        }
        if itemCount <= 10 {
            return 150
        }
        return 190
    }
}

struct GroomArchiveLimitNotice: View {
    var onOpenMegrumPlus: () -> Void

    var body: some View {
        Button(action: onOpenMegrumPlus) {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text("無料プランは最新10件まで")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                    Text("\(SubscriptionCatalog.currentPremiumDisplayName)でアーカイブを無制限に残せます")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } icon: {
                Image(systemName: "lock.open.fill")
                    .foregroundStyle(MegrumTheme.lavender)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.66), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(SubscriptionCatalog.currentPremiumDisplayName)でグルームアーカイブを無制限にする")
    }
}

private struct GroomArchiveThumbnail: View {
    var groom: GroomPost
    var isSelected: Bool

    var body: some View {
        VStack(spacing: 6) {
            GroomThumbnailCircle(url: groom.imageURL, size: 54)
                .overlay {
                    Circle()
                        .stroke(isSelected ? MegrumTheme.lavender : .white, lineWidth: isSelected ? 3 : 2)
                }

            Text(groom.createdAt.formatted(date: .numeric, time: .omitted))
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink.opacity(0.78))
                .lineLimit(1)
        }
        .frame(width: 68)
    }
}

private struct GroomArchiveOverviewThumbnail: View {
    var groom: GroomPost
    var isSelected: Bool
    var size: CGFloat

    var body: some View {
        GroomThumbnailCircle(url: groom.imageURL, size: size)
            .overlay {
                Circle()
                    .stroke(isSelected ? MegrumTheme.lavender : .white, lineWidth: isSelected ? 3 : 2)
            }
            .contentShape(Circle())
    }
}
