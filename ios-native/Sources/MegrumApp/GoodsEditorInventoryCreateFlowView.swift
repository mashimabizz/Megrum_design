import Foundation
import MegrumCore
import SwiftUI

struct GoodsInventoryCreateFlowView: View {
    @Binding var draft: GoodsEditorDraft
    @Binding var tagDraft: String
    var isTagFieldFocused: FocusState<Bool>.Binding
    @Binding var createMetas: [GoodsCreateMetaDraft]

    var createStep: GoodsCreateStep
    var createPhotos: [GoodsCreatePhotoDraft]
    var groups: [OshiGroup]
    var isLoadingOshiGroups: Bool
    var goodsTypes: [GoodsType]
    var isLoadingGoodsTypes: Bool
    var oshiCharacters: [OshiCharacter]
    var allowsMemberSelection: Bool
    var selectedGroupName: String?
    var selectedGoodsTypeName: String?
    var createError: String?
    var canAdvanceFromCommon: Bool
    var isTradingCardType: Bool
    var isProcessingTradingCardBulk: Bool
    var tradingCardBulkStatusMessage: String?
    var canSaveMetas: Bool
    var isItemReadOnly: Bool
    var isCreatingGoodsEntry: Bool
    var tagSuggestions: [String]
    var onRemoveTag: (String) -> Void
    var onAddTag: () -> Void
    var onAddSuggestedTag: (String) -> Void
    var onShowOshiPicker: () -> Void
    var onCommonNext: () -> Void
    var onPickCamera: () -> Void
    var onPickPhotos: () -> Void
    var onStartTradingCardBulk: () -> Void
    var onRemovePhoto: (UUID) -> Void
    var onCropPhoto: (UUID) -> Void
    var onShootBack: () -> Void
    var onShootNext: () -> Void
    var onContinueWithoutPhoto: () -> Void
    var onMetaBack: () -> Void
    var onSaveMetas: () -> Void

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
                    tagSuggestions: tagSuggestions,
                    tagNames: draft.tagNames,
                    tagDraft: $tagDraft,
                    isTagFieldFocused: isTagFieldFocused,
                    createError: createError,
                    canAdvance: canAdvanceFromCommon,
                    isItemReadOnly: isItemReadOnly,
                    isCreatingGoodsEntry: isCreatingGoodsEntry,
                    onRemoveTag: onRemoveTag,
                    onAddTag: onAddTag,
                    onAddSuggestedTag: onAddSuggestedTag,
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
                    onPickCamera: onPickCamera,
                    onPickPhotos: onPickPhotos,
                    onStartTradingCardBulk: onStartTradingCardBulk,
                    onRemovePhoto: onRemovePhoto,
                    onCropPhoto: onCropPhoto,
                    onBack: onShootBack,
                    onNext: onShootNext,
                    onContinueWithoutPhoto: onContinueWithoutPhoto
                )
            case .meta:
                GoodsInventoryCreateMetaStepView(
                    createMetas: $createMetas,
                    createPhotos: createPhotos,
                    oshiCharacters: oshiCharacters,
                    allowsMemberSelection: allowsMemberSelection,
                    draftGroupID: draft.groupID,
                    selectedGroupName: selectedGroupName,
                    selectedGoodsTypeName: selectedGoodsTypeName,
                    createError: createError,
                    canSaveMetas: canSaveMetas,
                    isCreatingGoodsEntry: isCreatingGoodsEntry,
                    onBack: onMetaBack,
                    onSave: onSaveMetas
                )
            }
        }
    }
}
