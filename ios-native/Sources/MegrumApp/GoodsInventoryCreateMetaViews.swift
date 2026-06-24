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
    var oshiCharacters: [OshiCharacter]
    var allowsMemberSelection: Bool
    var draftGroupID: UUID?
    var selectedGroupName: String?
    var selectedGoodsTypeName: String?
    var createError: String?
    var canSaveMetas: Bool
    var isCreatingGoodsEntry: Bool
    var onBack: () -> Void
    var onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                ForEach($createMetas) { $meta in
                    GoodsInventoryCreateMetaCard(
                        meta: $meta,
                        index: index(for: meta.id),
                        photo: photo(for: meta.photoID),
                        oshiCharacters: oshiCharacters,
                        allowsMemberSelection: allowsMemberSelection,
                        draftGroupID: draftGroupID
                    )
                }
            }

            if let createError {
                GoodsCreateErrorNotice(message: createError)
            }

            HStack(spacing: 10) {
                GoodsCreateSecondaryButton(
                    title: "戻る",
                    isCreatingGoodsEntry: isCreatingGoodsEntry,
                    action: onBack
                )
                GoodsCreatePrimaryButton(
                    title: "\(createMetas.count)件まとめて登録",
                    isDisabled: !canSaveMetas,
                    isCreatingGoodsEntry: isCreatingGoodsEntry,
                    showsProgress: true,
                    action: onSave
                )
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

private struct GoodsInventoryCreateMetaCard: View {
    @Binding var meta: GoodsCreateMetaDraft

    var index: Int
    var photo: GoodsCreatePhotoDraft?
    var oshiCharacters: [OshiCharacter]
    var allowsMemberSelection: Bool
    var draftGroupID: UUID?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            thumbnail

            VStack(alignment: .leading, spacing: 12) {
                if allowsMemberSelection {
                    GoodsEditorFlowLayout(spacing: 8) {
                        GoodsEditorSelectionChip(
                            title: "指定なし",
                            isSelected: meta.memberID == nil,
                            isCompact: true
                        ) {
                            meta.memberID = nil
                        }
                        ForEach(oshiCharacters) { member in
                            GoodsEditorSelectionChip(
                                title: member.name,
                                isSelected: meta.memberID == member.id,
                                isDisabled: draftGroupID == nil,
                                isCompact: true
                            ) {
                                meta.memberID = member.id
                            }
                        }
                    }
                }

                quantityStepper
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.48), lineWidth: 1)
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
        .frame(width: 78, height: 98)
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
}
