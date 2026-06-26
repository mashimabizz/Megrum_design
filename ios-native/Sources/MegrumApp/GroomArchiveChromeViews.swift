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

struct GroomArchiveLimitNotice: View {
    var onOpenMegrumPlus: () -> Void

    var body: some View {
        Button(action: onOpenMegrumPlus) {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text("無料プランは最新10件まで")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                    Text("メグルムプラスでアーカイブを無制限に残せます")
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
        .accessibilityLabel("メグルムプラスでグルームアーカイブを無制限にする")
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
