import MegrumCore
import MegrumDesign
import SwiftUI

struct GoodsCreateOshiPickerRow: View {
    var title: String = "推し"
    var isLoading: Bool
    var selectedGroupName: String?
    var isItemReadOnly: Bool
    var action: () -> Void

    var body: some View {
        GoodsEditorSectionContainer(title: title, systemImage: "person.2", required: true) {
            Button(action: action) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("推し（グループ・作品）")
                            .font(.subheadline.weight(.black))
                            .foregroundStyle(MegrumTheme.ink)
                        if isLoading {
                            Text("読み込み中")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(MegrumTheme.muted)
                        }
                    }
                    Spacer(minLength: 12)
                    Text(selectedGroupName ?? "選択")
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(selectedGroupName == nil ? MegrumTheme.muted : MegrumTheme.lavender)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.black))
                        .foregroundStyle(MegrumTheme.muted)
                }
                .padding(.horizontal, 14)
                .frame(height: 64)
                .background(.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(MegrumTheme.lavender.opacity(0.18), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
            .disabled(isItemReadOnly || isLoading)
        }
    }
}

struct GoodsInventoryCreateMetaStepView: View {
    @Binding var createMetas: [GoodsCreateMetaDraft]

    var createPhotos: [GoodsCreatePhotoDraft]
    var selectedCreateMetaIDs: Set<UUID>
    var oshiCharacters: [OshiCharacter]
    var allowsMemberSelection: Bool
    var createError: String?
    var onToggleSelection: (UUID) -> Void
    var onSelectAll: () -> Void
    var onClearSelection: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GoodsInventoryCreateMetaSelectionHeader(
                selectedCount: selectedCreateMetaIDs.count,
                totalCount: createMetas.count,
                onSelectAll: onSelectAll,
                onClearSelection: onClearSelection
            )

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 10)], spacing: 10) {
                ForEach($createMetas) { $meta in
                    GoodsInventoryCreateMetaTile(
                        meta: $meta,
                        photo: photo(for: meta.photoID),
                        allowsMemberSelection: allowsMemberSelection,
                        memberName: memberName(for: meta.memberID),
                        isSelected: selectedCreateMetaIDs.contains(meta.id),
                        onToggleSelection: {
                            onToggleSelection(meta.id)
                        }
                    )
                }
            }

            if allowsMemberSelection, oshiCharacters.isEmpty {
                GoodsCreateMemberRequestInfo()
            }

            if let createError {
                GoodsCreateErrorNotice(message: createError)
            }
        }
    }

    private func photo(for photoID: UUID?) -> GoodsCreatePhotoDraft? {
        guard let photoID else {
            return nil
        }
        return createPhotos.first { $0.id == photoID }
    }

    private func memberName(for memberID: UUID?) -> String? {
        guard let memberID else {
            return nil
        }
        return oshiCharacters.first { $0.id == memberID }?.name
    }
}

struct GoodsCreateMemberRequestInfo: View {
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(width: 32, height: 32)
                .background(MegrumTheme.lavender.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text("メンバーが見つからない場合")
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(MegrumTheme.ink)
                Text("Swift版では推し設定の追加リクエストから仮登録できます。登録画面では、追加済みメンバーだけを選べます。")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MegrumTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(MegrumTheme.sky.opacity(0.16), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct GoodsInventoryCreateMetaSelectionHeader: View {
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

private struct GoodsInventoryCreateMetaTile: View {
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
            .overlay(alignment: .topTrailing) {
                setupStatusBadge
                    .padding(6)
            }
            .overlay {
                RoundedRectangle(cornerRadius: GoodsGridLayout.tileCornerRadius, style: .continuous)
                    .strokeBorder(
                        isSelected ? MegrumTheme.lavender.opacity(0.88) : MegrumTheme.ink.opacity(GoodsTileCollectionCardMetrics.borderOpacity),
                        lineWidth: isSelected ? 2 : 1
                    )
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
    private var photoContent: some View {
        if let photo {
            GoodsCreatePhotoPreview(data: photo.upload.data)
        } else {
            GoodsCreatePhotoPreviewPlaceholder()
        }
    }

    private var setupStatusBadge: some View {
        Image(systemName: isSetupComplete ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
            .font(.system(size: 21, weight: .black))
            .foregroundStyle(isSetupComplete ? MegrumTheme.ok : MegrumTheme.conditionPossible)
            .padding(5)
            .background(.white.opacity(0.90), in: Circle())
            .shadow(color: .black.opacity(0.12), radius: 5, y: 2)
            .accessibilityHidden(true)
    }

    private var isSetupComplete: Bool {
        isMemberComplete && !meta.tagNames.isEmpty
    }

    private var isMemberComplete: Bool {
        !allowsMemberSelection || memberName != nil
    }

    private var accessibilityValue: Text {
        var parts = [isSelected ? "選択中" : "未選択"]
        if isSetupComplete {
            parts.append("メンバーとタグを登録済み")
        } else {
            parts.append("未設定項目あり")
        }
        return Text(parts.joined(separator: "、"))
    }
}
