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

struct TradeEvidencePhotoList: View {
    var proposal: TradeProposal
    var photos: [TradeEvidencePhoto]
    var viewerID: UUID?
    var showsApprovalControls = false
    var isApproving = false
    var deletingPhotoID: UUID?
    var onOpenImage: (TradeEvidencePhoto) -> Void
    var onApprove: (TradeEvidencePhoto) -> Void = { _ in }
    var onDelete: (TradeEvidencePhoto) -> Void = { _ in }

    var body: some View {
        LazyVGrid(columns: gridItems, spacing: 6) {
            ForEach(photos) { photo in
                TradeEvidencePhotoTile(
                    proposal: proposal,
                    photo: photo,
                    viewerID: viewerID,
                    showsApprovalControls: showsApprovalControls,
                    isApproving: isApproving,
                    isDeleting: deletingPhotoID == photo.id,
                    onOpenImage: onOpenImage,
                    onApprove: onApprove,
                    onDelete: onDelete
                )
            }
        }
    }

    private var gridItems: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 6), count: 4)
    }
}

private struct TradeEvidencePhotoTile: View {
    var proposal: TradeProposal
    var photo: TradeEvidencePhoto
    var viewerID: UUID?
    var showsApprovalControls: Bool
    var isApproving: Bool
    var isDeleting: Bool
    var onOpenImage: (TradeEvidencePhoto) -> Void
    var onApprove: (TradeEvidencePhoto) -> Void
    var onDelete: (TradeEvidencePhoto) -> Void

    private var isApproved: Bool {
        photo.isApproved(by: viewerID, in: proposal)
    }

    private var canApprove: Bool {
        showsApprovalControls
            && proposal.status == .agreed
            && !isApproved
    }

    private var canDelete: Bool {
        proposal.status == .agreed && photo.isUploadedBy(viewerID)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topTrailing) {
                Button {
                    onOpenImage(photo)
                } label: {
                    TradeEvidencePhotoThumbnail(url: photo.photoURL)
                        .frame(width: proxy.size.width, height: proxy.size.width)
                        .clipped()
                }
                .buttonStyle(.plain)

                if isApproved {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 17, weight: .black))
                        .foregroundStyle(.white, MegrumTheme.ok)
                        .padding(5)
                        .shadow(color: .black.opacity(0.18), radius: 4, y: 1)
                }

                if canApprove {
                    Button {
                        onApprove(photo)
                    } label: {
                        Group {
                            if isApproving {
                                ProgressView()
                                    .controlSize(.mini)
                            } else {
                                Text("承認")
                            }
                        }
                        .font(.system(size: 10.5, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(MegrumTheme.lavender, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(isApproving)
                    .padding(5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .accessibilityLabel("この取引証跡を承認")
                }

                if isDeleting {
                    ProgressView()
                        .controlSize(.small)
                        .padding(5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .background(.black.opacity(0.18))
                }
            }
            .contextMenu {
                if canDelete {
                    Button(role: .destructive) {
                        onDelete(photo)
                    } label: {
                        Label("削除", systemImage: "trash")
                    }
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var accessibilityLabel: String {
        let uploader = photo.isUploadedBy(viewerID) ? "あなた" : "相手"
        let approval = isApproved ? "承認済み" : "未承認"
        return "\(uploader)がアップロードした取引証跡、\(approval)"
    }
}

struct TradeEvidencePhotoThumbnail: View {
    var url: URL

    var body: some View {
        GeometryReader { proxy in
            Rectangle()
                .fill(MegrumTheme.sky.opacity(0.18))
                .overlay {
                    Group {
                        if url.isFileURL {
                            LocalURLImage(url: url, contentMode: .fill) {
                                placeholderContent
                            }
                        } else {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                case .failure:
                                    placeholderContent
                                case .empty:
                                    MegrumTheme.sky.opacity(0.12)
                                        .overlay {
                                            ProgressView()
                                        }
                                @unknown default:
                                    Color.clear
                                }
                            }
                        }
                    }
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                }
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .strokeBorder(.white.opacity(0.7), lineWidth: 1)
                }
        }
    }

    private var placeholderContent: some View {
        MegrumTheme.sky.opacity(0.18)
            .overlay {
                Image(systemName: "photo")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(MegrumTheme.muted)
            }
    }
}
