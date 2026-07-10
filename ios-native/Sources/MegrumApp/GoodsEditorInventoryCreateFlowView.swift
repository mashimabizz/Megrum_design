import Foundation
import MegrumCore
import SwiftUI

struct GoodsInventoryCreateFlowView: View {
    @Binding var draft: GoodsEditorDraft
    @Binding var createMetas: [GoodsCreateMetaDraft]

    var createStep: GoodsCreateStep
    var createPhotos: [GoodsCreatePhotoDraft]
    var selectedCreateMetaIDs: Set<UUID>
    var groups: [OshiGroup]
    var isLoadingOshiGroups: Bool
    var goodsTypes: [GoodsType]
    var isLoadingGoodsTypes: Bool
    var oshiCharacters: [OshiCharacter]
    var allowsMemberSelection: Bool
    var selectedGroupName: String?
    var createError: String?
    var canAdvanceFromCommon: Bool
    var isTradingCardType: Bool
    var isProcessingTradingCardBulk: Bool
    var tradingCardBulkStatusMessage: String?
    var isItemReadOnly: Bool
    var isCreatingGoodsEntry: Bool
    var onShowOshiPicker: () -> Void
    var onCommonNext: () -> Void
    var onAddPhoto: () -> Void
    var onStartTradingCardBulk: () -> Void
    var onRemovePhoto: (UUID) -> Void
    var onCropPhoto: (UUID) -> Void
    var onShootBack: () -> Void
    var onShootNext: () -> Void
    var onMetaBack: () -> Void
    var onToggleMetaSelection: (UUID) -> Void
    var onSelectAllMetas: () -> Void
    var onClearMetaSelection: () -> Void
    var onRemoveMetaTag: (UUID, String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            GoodsCreateStepProgressView(currentStep: createStep)

            switch createStep {
            case .common:
                GoodsInventoryCreateCommonStepView(
                    groups: groups,
                    isLoadingOshiGroups: isLoadingOshiGroups,
                    selectedGroupID: $draft.groupID,
                    selectedGroupName: selectedGroupName,
                    goodsTypes: goodsTypes,
                    isLoadingGoodsTypes: isLoadingGoodsTypes,
                    selectedGoodsTypeID: $draft.goodsTypeID,
                    createError: createError,
                    canAdvance: canAdvanceFromCommon,
                    isItemReadOnly: isItemReadOnly,
                    isCreatingGoodsEntry: isCreatingGoodsEntry,
                    onShowOshiPicker: onShowOshiPicker,
                    onNext: onCommonNext
                )
            case .shoot:
                GoodsInventoryCreateShootStepView(
                    createPhotos: createPhotos,
                    isTradingCardType: isTradingCardType,
                    isProcessingTradingCardBulk: isProcessingTradingCardBulk,
                    tradingCardBulkStatusMessage: tradingCardBulkStatusMessage,
                    createError: createError,
                    isCreatingGoodsEntry: isCreatingGoodsEntry,
                    onAddPhoto: onAddPhoto,
                    onStartTradingCardBulk: onStartTradingCardBulk,
                    onRemovePhoto: onRemovePhoto,
                    onCropPhoto: onCropPhoto,
                    onBack: onShootBack,
                    onNext: onShootNext
                )
            case .meta:
                GoodsInventoryCreateMetaStepView(
                    createMetas: $createMetas,
                    createPhotos: createPhotos,
                    selectedCreateMetaIDs: selectedCreateMetaIDs,
                    oshiCharacters: oshiCharacters,
                    allowsMemberSelection: allowsMemberSelection,
                    createError: createError,
                    onToggleSelection: onToggleMetaSelection,
                    onSelectAll: onSelectAllMetas,
                    onClearSelection: onClearMetaSelection
                )
            }
        }
    }
}
