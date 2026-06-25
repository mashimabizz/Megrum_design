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
    var onRemoveTag: (UUID, String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GoodsCreateHintCard(
                title: "画像を選んでまとめて設定",
                text: allowsMemberSelection
                    ? "登録したい画像を選んで、下の固定ボタンからメンバーやタグをまとめて割り当てます。"
                    : "この推しはメンバー登録が不要です。登録したい画像を選んで、タグをまとめて割り当てます。"
            )

            GoodsInventoryCreateMetaSelectionHeader(
                selectedCount: selectedCreateMetaIDs.count,
                totalCount: createMetas.count,
                onSelectAll: onSelectAll,
                onClearSelection: onClearSelection
            )

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 142), spacing: 12)], spacing: 12) {
                ForEach($createMetas) { $meta in
                    GoodsInventoryCreateMetaTile(
                        meta: $meta,
                        index: index(for: meta.id),
                        photo: photo(for: meta.photoID),
                        allowsMemberSelection: allowsMemberSelection,
                        memberName: memberName(for: meta.memberID),
                        isSelected: selectedCreateMetaIDs.contains(meta.id),
                        onToggleSelection: {
                            onToggleSelection(meta.id)
                        },
                        onRemoveTag: { tag in
                            onRemoveTag(meta.id, tag)
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

    private func index(for metaID: UUID) -> Int {
        createMetas.firstIndex { $0.id == metaID }.map { $0 + 1 } ?? 1
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
                Text("画像をタップして選択を切り替え")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MegrumTheme.muted)
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

    var index: Int
    var photo: GoodsCreatePhotoDraft?
    var allowsMemberSelection: Bool
    var memberName: String?
    var isSelected: Bool
    var onToggleSelection: () -> Void
    var onRemoveTag: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: onToggleSelection) {
                VStack(alignment: .leading, spacing: 8) {
                    thumbnail
                    statusLabels
                }
                .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("画像\(index)を選択")
            .accessibilityValue(isSelected ? "選択中" : "未選択")

            VStack(alignment: .leading, spacing: 9) {
                quantityStepper
                tagChips
            }
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(isSelected ? MegrumTheme.lavender.opacity(0.72) : .white.opacity(0.48), lineWidth: isSelected ? 2 : 1)
        }
    }

    private var thumbnail: some View {
        ZStack {
            if let photo {
                GoodsCreatePhotoPreview(data: photo.upload.data)
            } else {
                GoodsCreatePhotoPreviewPlaceholder()
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(alignment: .topLeading) {
            Text("#\(index)")
                .font(.caption2.weight(.black))
                .foregroundStyle(MegrumTheme.ink)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(.white.opacity(0.82), in: Capsule())
                .padding(7)
        }
        .overlay(alignment: .topTrailing) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 24, weight: .black))
                .foregroundStyle(isSelected ? MegrumTheme.lavender : .white.opacity(0.92))
                .padding(7)
                .shadow(color: .black.opacity(0.12), radius: 5, y: 2)
        }
    }

    private var statusLabels: some View {
        VStack(alignment: .leading, spacing: 5) {
            if allowsMemberSelection {
                Label(memberName ?? "メンバー未設定", systemImage: memberName == nil ? "person.crop.circle.badge.exclamationmark" : "person.crop.circle.fill")
                    .foregroundStyle(memberName == nil ? MegrumTheme.pink : MegrumTheme.ink)
            }
            Label(meta.tagNames.isEmpty ? "タグ未設定" : "\(meta.tagNames.count)タグ", systemImage: meta.tagNames.isEmpty ? "tag.slash" : "tag.fill")
                .foregroundStyle(meta.tagNames.isEmpty ? MegrumTheme.muted : MegrumTheme.lavender)
        }
        .font(.caption.weight(.black))
    }

    private var quantityStepper: some View {
        HStack(spacing: 10) {
            GoodsEditorQuantityButton(systemImage: "minus") {
                meta.quantity = max(1, meta.quantity - 1)
            }
            .disabled(meta.normalizedQuantity <= 1)

            let quantityBinding = Binding<Int>(
                get: { meta.quantity },
                set: { meta.quantity = max(1, min($0, 999)) }
            )
            let field = TextField("数量", value: quantityBinding, format: .number)
                .multilineTextAlignment(.center)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .monospacedDigit()
                .frame(height: 42)
                .background(Color.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            #if os(iOS)
            field.keyboardType(.numberPad)
            #else
            field
            #endif

            GoodsEditorQuantityButton(systemImage: "plus") {
                meta.quantity = min(999, meta.quantity + 1)
            }
            .disabled(meta.normalizedQuantity >= 999)
        }
    }

    @ViewBuilder
    private var tagChips: some View {
        if meta.tagNames.isEmpty {
            Text("タグ登録で検索されやすくなります")
                .font(.caption2.weight(.bold))
                .foregroundStyle(MegrumTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            WrappingTagFlow(spacing: 6, rowSpacing: 6) {
                ForEach(meta.tagNames, id: \.self) { tag in
                    Button {
                        onRemoveTag(tag)
                    } label: {
                        HStack(spacing: 4) {
                            Text("#\(tag)")
                            Image(systemName: "xmark")
                                .font(.system(size: 8, weight: .black))
                        }
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                        .padding(.horizontal, 7)
                        .frame(height: 24)
                        .background(MegrumTheme.lavender.opacity(0.10), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("タグ #\(tag) を外す")
                }
            }
        }
    }
}
