import MegrumCore
import MegrumDesign
import SwiftUI

struct TradeEvidenceApprovalChip: View {
    var title: String
    var isApproved: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isApproved ? "checkmark.circle.fill" : "clock")
            Text(isApproved ? "\(title) 承認済み" : "\(title) 未承認")
        }
        .font(.system(size: 12, weight: .heavy, design: .rounded))
        .foregroundStyle(isApproved ? MegrumTheme.ok : MegrumTheme.muted)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.white.opacity(0.72), in: Capsule())
    }
}

struct TradeEvidencePhotoCarousel: View {
    var photos: [TradeEvidencePhoto]
    var viewerID: UUID?
    var onOpenImage: (URL) -> Void

    var body: some View {
        GeometryReader { proxy in
            let cardWidth = max(246, proxy.size.width - 48)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                        TradeEvidencePhotoCard(
                            photo: photo,
                            index: index,
                            count: photos.count,
                            viewerID: viewerID,
                            onOpenImage: onOpenImage
                        )
                        .frame(width: cardWidth)
                    }
                }
                .padding(.trailing, 46)
            }
        }
        .frame(height: 178)
    }
}

private struct TradeEvidencePhotoCard: View {
    var photo: TradeEvidencePhoto
    var index: Int
    var count: Int
    var viewerID: UUID?
    var onOpenImage: (URL) -> Void

    private var uploaderText: String {
        photo.isUploadedBy(viewerID) ? "あなたがアップロード" : "相手がアップロード"
    }

    var body: some View {
        Button {
            onOpenImage(photo.photoURL)
        } label: {
            AsyncImage(url: photo.photoURL) { phase in
                ZStack {
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        MegrumTheme.sky.opacity(0.18)
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(MegrumTheme.muted)
                            }
                    case .empty:
                        MegrumTheme.sky.opacity(0.12)
                            .overlay {
                                ProgressView()
                            }
                    @unknown default:
                        Color.clear
                    }

                    VStack {
                        HStack(spacing: 7) {
                            Text(uploaderText)
                            Text("\(index + 1)/\(count)")
                        }
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.white.opacity(0.88), in: Capsule())
                        .padding(10)

                        Spacer()
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(uploaderText)した証跡写真 \(index + 1)枚目を拡大表示")
        .frame(height: 178)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.7), lineWidth: 1)
        }
    }
}
