import MegrumDesign
import SwiftUI

struct GoodsInventoryCreateMetaSelectionHeader: View {
    var selectedCount: Int
    var totalCount: Int
    var onSelectAll: () -> Void
    var onClearSelection: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("\(selectedCount)/\(totalCount)件を選択中")
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(MegrumTheme.ink)
            }
            Spacer(minLength: 8)
            Button(selectedCount == totalCount ? "すべて解除" : "すべて選択") {
                if selectedCount == totalCount {
                    onClearSelection()
                } else {
                    onSelectAll()
                }
            }
            .font(.caption.weight(.black))
            .foregroundStyle(MegrumTheme.lavender)
            .padding(.horizontal, 11)
            .frame(height: 32)
            .background(.white.opacity(0.86), in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(MegrumTheme.lavender.opacity(0.18), lineWidth: 1)
            }
        }
    }
}

struct GoodsInventoryCreateMetaTile: View {
    @Binding var meta: GoodsCreateMetaDraft

    var photo: GoodsCreatePhotoDraft?
    var allowsMemberSelection: Bool
    var memberName: String?
    var isSelected: Bool
    var onToggleSelection: () -> Void

    var body: some View {
        Button(action: onToggleSelection) {
            thumbnail
                .contentShape(RoundedRectangle(cornerRadius: GoodsGridLayout.tileCornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("登録する画像")
        .accessibilityValue(accessibilityValue)
    }

    private var thumbnail: some View {
        RoundedRectangle(cornerRadius: GoodsGridLayout.tileCornerRadius, style: .continuous)
            .fill(MegrumTheme.lavender.opacity(0.10))
            .aspectRatio(GoodsGridLayout.tileAspectRatio, contentMode: .fit)
            .overlay {
                photoContent
            }
            .overlay(alignment: .topLeading) {
                setupStatusBadge
                    .padding(6)
            }
            .overlay(alignment: .topTrailing) {
                if let tagLine {
                    GoodsInventoryCreateMetaTagPlate(text: tagLine)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if let memberName {
                    GoodsInventoryCreateMetaMemberPlate(text: memberName)
                        .padding(6)
                }
            }
            .overlay {
                selectionBorder
            }
            .clipShape(RoundedRectangle(cornerRadius: GoodsGridLayout.tileCornerRadius, style: .continuous))
            .shadow(
                color: MegrumTheme.ink.opacity(GoodsTileCollectionCardMetrics.shadowOpacity),
                radius: GoodsTileCollectionCardMetrics.shadowRadius,
                x: GoodsTileCollectionCardMetrics.shadowX,
                y: GoodsTileCollectionCardMetrics.shadowY
            )
    }

    @ViewBuilder
    private var selectionBorder: some View {
        let shape = RoundedRectangle(cornerRadius: GoodsGridLayout.tileCornerRadius, style: .continuous)
        if isSelected {
            shape
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            MegrumTheme.sky,
                            MegrumTheme.lavender,
                            MegrumTheme.sky.opacity(0.92)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 5
                )
                .shadow(color: MegrumTheme.sky.opacity(0.46), radius: 8, x: 0, y: 0)
        } else {
            shape
                .strokeBorder(
                    MegrumTheme.ink.opacity(GoodsTileCollectionCardMetrics.borderOpacity),
                    lineWidth: 1
                )
        }
    }

    @ViewBuilder
    private var photoContent: some View {
        if let photo {
            GoodsCreatePhotoPreview(data: photo.upload.data)
        } else {
            GoodsCreatePhotoPreviewPlaceholder()
        }
    }

    private var setupStatusBadge: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: isSetupComplete ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 20, weight: .black))
                .foregroundStyle(isSetupComplete ? MegrumTheme.ok : MegrumTheme.conditionPossible)
                .frame(width: 32, height: 32)
                .background(.white.opacity(0.92), in: Circle())
                .shadow(color: .black.opacity(0.12), radius: 5, y: 2)

            if missingSetupCount > 0 {
                Text("\(missingSetupCount)")
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .frame(width: 16, height: 16)
                    .background(MegrumTheme.conditionExact, in: Circle())
                    .overlay {
                        Circle()
                            .strokeBorder(.white.opacity(0.92), lineWidth: 1.4)
                    }
                    .offset(x: 5, y: -5)
            }
        }
        .accessibilityHidden(true)
    }

    private var tagLine: String? {
        GoodsInventoryCreateMetaTilePresentation.tagLine(for: meta.tagNames)
    }

    private var missingSetupCount: Int {
        GoodsInventoryCreateMetaTilePresentation.missingSetupCount(
            for: meta,
            allowsMemberSelection: allowsMemberSelection,
            memberName: memberName
        )
    }

    private var isSetupComplete: Bool {
        missingSetupCount == 0
    }

    private var accessibilityValue: Text {
        var parts = [isSelected ? "選択中" : "未選択"]
        if isSetupComplete {
            parts.append("メンバーとシリーズを登録済み")
        } else {
            parts.append("未設定項目あり")
        }
        return Text(parts.joined(separator: "、"))
    }
}

private struct GoodsInventoryCreateMetaTagPlate: View {
    var text: String

    var body: some View {
        GeometryReader { proxy in
            GoodsTagTextPill(
                text: text,
                fontSize: GoodsTileCollectionCardMetrics.tagFontSize,
                horizontalPadding: GoodsTileCollectionCardMetrics.tagHorizontalPadding,
                verticalPadding: GoodsTileCollectionCardMetrics.tagVerticalPadding
            )
            .frame(maxWidth: proxy.size.width * GoodsTileCollectionCardMetrics.tagMaxWidthRatio, alignment: .trailing)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(GoodsTileCollectionCardMetrics.tagInset)
        }
        .accessibilityHidden(true)
    }
}

private struct GoodsInventoryCreateMetaMemberPlate: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .heavy, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(MegrumTheme.ink.opacity(0.58), in: Capsule())
            .accessibilityHidden(true)
    }
}
