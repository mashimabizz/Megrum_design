import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct GoodsCropPreviewStrip: View {
    var imageData: Data
    var frames: [TradingCardCropFrame]
    @Binding var selectedFrameID: UUID?
    var onDelete: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("切り取りプレビュー")
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(MegrumTheme.ink)
                Spacer()
                Text("\(frames.count)件")
                    .font(.caption.weight(.black))
                    .foregroundStyle(MegrumTheme.lavender)
            }

            if frames.isEmpty {
                Text("「枠を追加」を押すか、写真の上をドラッグして枠を作れます。")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(MegrumTheme.muted)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.70), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(frames) { frame in
                            GoodsCropPreviewTile(
                                imageData: imageData,
                                frame: frame,
                                isSelected: selectedFrameID == frame.id,
                                onSelect: { selectedFrameID = frame.id },
                                onDelete: { onDelete(frame.id) }
                            )
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.48), lineWidth: 1)
        }
    }
}

private struct GoodsCropPreviewTile: View {
    var imageData: Data
    var frame: TradingCardCropFrame
    var isSelected: Bool
    var onSelect: () -> Void
    var onDelete: () -> Void

    private var previewData: Data? {
        guard let result = try? TradingCardBulkRecognizer.cropFramesSynchronously([frame], in: imageData),
              let first = result.first
        else {
            return nil
        }
        return first.data
    }

    var body: some View {
        Button(action: onSelect) {
            ZStack(alignment: .topTrailing) {
                if let previewData {
                    GoodsCreatePhotoPreview(data: previewData)
                } else {
                    GoodsCreatePhotoPreviewPlaceholder()
                }
            }
            .frame(width: 86, height: 112)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isSelected ? Color.yellow : .white.opacity(0.60), lineWidth: isSelected ? 3 : 1)
            }
            .overlay(alignment: .topTrailing) {
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(.black.opacity(0.45), in: Circle())
                }
                .buttonStyle(.plain)
                .padding(6)
            }
        }
        .buttonStyle(.plain)
    }
}
