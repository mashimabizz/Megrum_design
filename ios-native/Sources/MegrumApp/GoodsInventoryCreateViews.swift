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
    var createError: String?
    var canAdvance: Bool
    var isItemReadOnly: Bool
    var isCreatingGoodsEntry: Bool
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
    var onAddPhoto: () -> Void
    var onStartTradingCardBulk: () -> Void
    var onRemovePhoto: (UUID) -> Void
    var onCropPhoto: (UUID) -> Void
    var onBack: () -> Void
    var onNext: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GoodsCreateAddPhotoHeroTile(action: onAddPhoto)

            if createPhotos.isEmpty {
                Text("追加した写真はトリミングで整えてから登録されます。")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MegrumTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if isTradingCardType {
                GoodsTradingCardBulkStartButton(
                    isProcessing: isProcessingTradingCardBulk,
                    action: onStartTradingCardBulk
                )
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
                    onCropPhoto: onCropPhoto,
                    onAddPhoto: onAddPhoto
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
        }
    }
}
