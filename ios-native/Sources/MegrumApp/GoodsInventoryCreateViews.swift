import MegrumCore
import MegrumDesign
import SwiftUI

struct GoodsCreateStepProgressView: View {
    var currentStep: GoodsCreateStep

    var body: some View {
        HStack(spacing: 8) {
            ForEach(GoodsCreateStep.allCases) { step in
                HStack(spacing: 6) {
                    Text("\(step.index)")
                        .font(.caption.weight(.black))
                        .foregroundStyle(currentStep.index >= step.index ? .white : MegrumTheme.lavender)
                        .frame(width: 22, height: 22)
                        .background(
                            currentStep.index >= step.index ? MegrumTheme.lavender : MegrumTheme.lavender.opacity(0.12),
                            in: Circle()
                        )
                    Text(step.title)
                        .font(.caption.weight(.black))
                        .foregroundStyle(currentStep == step ? MegrumTheme.ink : MegrumTheme.muted)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(.regularMaterial, in: Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(currentStep == step ? MegrumTheme.lavender.opacity(0.28) : .white.opacity(0.42), lineWidth: 1)
                }
            }
        }
    }
}

struct GoodsInventoryCreateCommonStepView: View {
    var groups: [OshiGroup]
    var isLoadingOshiGroups: Bool
    @Binding var selectedGroupID: UUID?
    var selectedGroupName: String?
    var goodsTypes: [GoodsType]
    var isLoadingGoodsTypes: Bool
    @Binding var selectedGoodsTypeID: UUID?
    var tagSuggestions: [String]
    var tagNames: [String]
    @Binding var tagDraft: String
    var isTagFieldFocused: FocusState<Bool>.Binding
    var createError: String?
    var canAdvance: Bool
    var isItemReadOnly: Bool
    var isCreatingGoodsEntry: Bool
    var onRemoveTag: (String) -> Void
    var onAddTag: () -> Void
    var onAddSuggestedTag: (String) -> Void
    var onShowOshiPicker: () -> Void
    var onNext: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GoodsCreateOshiPickerRow(
                isLoading: isLoadingOshiGroups,
                selectedGroupName: selectedGroupName,
                isItemReadOnly: isItemReadOnly,
                action: onShowOshiPicker
            )
            GoodsEditorGoodsTypeSelectionSection(
                goodsTypes: goodsTypes,
                isLoading: isLoadingGoodsTypes,
                selectedGoodsTypeID: $selectedGoodsTypeID,
                isItemReadOnly: isItemReadOnly
            )
            GoodsEditorTagsSection(
                tagNames: tagNames,
                suggestedTagNames: tagSuggestions,
                tagDraft: $tagDraft,
                isTagFieldFocused: isTagFieldFocused,
                isItemReadOnly: isItemReadOnly,
                onAddSuggestedTag: onAddSuggestedTag,
                onRemoveTag: onRemoveTag,
                onAddTag: onAddTag
            )

            if let createError {
                GoodsCreateErrorNotice(message: createError)
            }

            GoodsCreatePrimaryButton(
                title: "次へ：写真を撮る",
                isDisabled: !canAdvance,
                isCreatingGoodsEntry: isCreatingGoodsEntry,
                action: onNext
            )
        }
    }
}

struct GoodsInventoryCreateShootStepView: View {
    var createPhotos: [GoodsCreatePhotoDraft]
    var isTradingCardType: Bool
    var isProcessingTradingCardBulk: Bool
    var tradingCardBulkStatusMessage: String?
    var createError: String?
    var isCreatingGoodsEntry: Bool
    var onPickCamera: () -> Void
    var onPickPhotos: () -> Void
    var onStartTradingCardBulk: () -> Void
    var onRemovePhoto: (UUID) -> Void
    var onCropPhoto: (UUID) -> Void
    var onBack: () -> Void
    var onNext: () -> Void
    var onContinueWithoutPhoto: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                GoodsCreatePhotoPickButton(title: "カメラ", systemImage: "camera.fill", action: onPickCamera)
                GoodsCreatePhotoPickButton(title: "写真を選ぶ（複数可）", systemImage: "photo.on.rectangle.angled", action: onPickPhotos)
            }

            if isTradingCardType {
                tradingCardBulkButton
            }

            if isProcessingTradingCardBulk {
                GoodsTradingCardBulkProcessingCard()
            } else if let tradingCardBulkStatusMessage {
                GoodsTradingCardBulkStatusCard(message: tradingCardBulkStatusMessage)
            }

            if !createPhotos.isEmpty {
                GoodsCreatePhotoSelectionGrid(
                    photos: createPhotos,
                    onRemovePhoto: onRemovePhoto,
                    onCropPhoto: onCropPhoto
                )
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
                    title: "次へ：詳細設定へ",
                    isDisabled: createPhotos.isEmpty,
                    isCreatingGoodsEntry: isCreatingGoodsEntry,
                    action: onNext
                )
            }

            Button(action: onContinueWithoutPhoto) {
                Text("写真なしで登録する →")
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(MegrumTheme.lavender)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
        }
    }

    private var tradingCardBulkButton: some View {
        Button(action: onStartTradingCardBulk) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(MegrumTheme.lavender)
                        .frame(width: 36, height: 36)
                    if isProcessingTradingCardBulk {
                        ProgressView()
                            .tint(.white)
                            .controlSize(.small)
                    } else {
                        Text("AI")
                            .font(.caption.weight(.black))
                            .foregroundStyle(.white)
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("トレカ専用 AIで一括登録")
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(MegrumTheme.ink)
                    Text("検出した枠を黄色で確認してから、必要な分だけ追加します。")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(MegrumTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(MegrumTheme.lavender.opacity(0.20), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(isProcessingTradingCardBulk)
    }
}

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

struct GoodsInventoryCreateMetaCard: View {
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

struct GoodsCreateHintCard: View {
    var title: String
    var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.subheadline.weight(.black))
                .foregroundStyle(MegrumTheme.ink)
            Text(text)
                .font(.caption.weight(.semibold))
                .foregroundStyle(MegrumTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MegrumTheme.lavender.opacity(0.10), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(MegrumTheme.lavender.opacity(0.20), lineWidth: 1)
        }
    }
}

struct GoodsCreateErrorNotice: View {
    var message: String

    var body: some View {
        Text(message)
            .font(.caption.weight(.bold))
            .foregroundStyle(.red)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MegrumTheme.pink.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct GoodsTradingCardBulkProcessingCard: View {
    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(MegrumTheme.lavender)
            VStack(alignment: .leading, spacing: 4) {
                Text("AIでカード枠を検出中")
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(MegrumTheme.ink)
                Text("検出後、黄色い枠と切り取りプレビューを確認できます。")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MegrumTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MegrumTheme.sky.opacity(0.16), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(MegrumTheme.lavender.opacity(0.16), lineWidth: 1)
        }
    }
}

struct GoodsTradingCardBulkStatusCard: View {
    var message: String

    var body: some View {
        Label {
            Text(message)
                .font(.caption.weight(.semibold))
                .foregroundStyle(MegrumTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "sparkles")
                .foregroundStyle(MegrumTheme.lavender)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(MegrumTheme.lavender.opacity(0.16), lineWidth: 1)
        }
    }
}

struct GoodsCreatePhotoPickButton: View {
    var title: String
    var systemImage: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(MegrumTheme.lavender)
                    .frame(width: 48, height: 48)
                    .background(.white.opacity(0.82), in: Circle())
                Text(title)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(MegrumTheme.ink)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 132)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(MegrumTheme.lavender.opacity(0.18), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

struct GoodsCreatePrimaryButton: View {
    var title: String
    var isDisabled: Bool = false
    var isCreatingGoodsEntry: Bool
    var showsProgress: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if showsProgress && isCreatingGoodsEntry {
                    ProgressView()
                        .tint(.white)
                }
                Text(title)
                    .font(.headline.weight(.black))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(MegrumTheme.lavender, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isDisabled || isCreatingGoodsEntry)
        .opacity(isDisabled || isCreatingGoodsEntry ? 0.46 : 1)
    }
}

struct GoodsCreateSecondaryButton: View {
    var title: String
    var isCreatingGoodsEntry: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline.weight(.black))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(MegrumTheme.lavender.opacity(0.20), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .disabled(isCreatingGoodsEntry)
    }
}

struct GoodsEditorSelectionChip: View {
    var title: String
    var isSelected: Bool
    var isDisabled: Bool = false
    var isCompact: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: isCompact ? 12 : 13, weight: .black, design: .rounded))
                .foregroundStyle(isSelected ? .white : MegrumTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .padding(.horizontal, isCompact ? 10 : 13)
                .padding(.vertical, isCompact ? 7 : 10)
                .frame(maxWidth: isCompact ? nil : .infinity)
                .background(
                    isSelected ? MegrumTheme.lavender : Color.white.opacity(0.82),
                    in: RoundedRectangle(cornerRadius: isCompact ? 11 : 13, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: isCompact ? 11 : 13, style: .continuous)
                        .strokeBorder(
                            isSelected ? MegrumTheme.lavender.opacity(0.25) : MegrumTheme.lavender.opacity(0.18),
                            lineWidth: 1
                        )
                }
                .opacity(isDisabled ? 0.48 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

struct GoodsEditorQuantityButton: View {
    var systemImage: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(width: 46, height: 46)
                .background(.white.opacity(0.88), in: Circle())
                .overlay {
                    Circle()
                        .strokeBorder(MegrumTheme.lavender.opacity(0.16), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}
