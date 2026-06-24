import Foundation
import MegrumCore
import SwiftUI

struct GoodsEditorFormContentView: View {
    @Binding var draft: GoodsEditorDraft
    @Binding var tagDraft: String
    var isTagFieldFocused: FocusState<Bool>.Binding
    @Binding var createMetas: [GoodsCreateMetaDraft]

    var navigationTitle: String
    var headerDescription: String
    var usesInventoryCreateFlow: Bool
    var isItemReadOnly: Bool
    var createStep: GoodsCreateStep
    var createPhotos: [GoodsCreatePhotoDraft]
    var groups: [OshiGroup]
    var isLoadingOshiGroups: Bool
    var members: [OshiCharacter]
    var isLoadingOshiCharacters: Bool
    var goodsTypes: [GoodsType]
    var isLoadingGoodsTypes: Bool
    var selectedGroupName: String?
    var selectedGroupSupportsMemberSelection: Bool
    var selectedGoodsTypeName: String?
    var createError: String?
    var canAdvanceFromCreateCommon: Bool
    var isTradingCardType: Bool
    var isProcessingTradingCardBulk: Bool
    var tradingCardBulkStatusMessage: String?
    var canSaveInventoryCreateMetas: Bool
    var isCreatingGoodsEntry: Bool
    var tagSuggestions: [String]
    var photoError: String?
    var photoActionTitle: String
    var titlePreview: String
    var wishImageHint: String
    var isWishPhotoRemovalLocked: Bool
    var onRemoveTag: (String) -> Void
    var onAddTag: () -> Void
    var onAddSuggestedTag: (String) -> Void
    var onOpenTagSheet: (() -> Void)?
    var onShowCreateOshiPicker: () -> Void
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
    var onShowPhotoSource: () -> Void
    var onClearLocalPhoto: () -> Void
    var onRemoveWishPhoto: () -> Void

    var body: some View {
        if draft.mode == .create && !usesInventoryCreateFlow {
            GoodsEditorHeaderCard(
                entryKind: draft.entryKind,
                title: navigationTitle,
                badgeTitle: draft.mode.badgeTitle,
                description: headerDescription
            )
        }

        if isItemReadOnly {
            GoodsEditorReadOnlyNotice()
        }

        if usesInventoryCreateFlow {
            GoodsInventoryCreateFlowView(
                draft: $draft,
                tagDraft: $tagDraft,
                isTagFieldFocused: isTagFieldFocused,
                createMetas: $createMetas,
                createStep: createStep,
                createPhotos: createPhotos,
                groups: groups,
                isLoadingOshiGroups: isLoadingOshiGroups,
                goodsTypes: goodsTypes,
                isLoadingGoodsTypes: isLoadingGoodsTypes,
                oshiCharacters: members,
                allowsMemberSelection: selectedGroupSupportsMemberSelection,
                selectedGroupName: selectedGroupName,
                selectedGoodsTypeName: selectedGoodsTypeName,
                createError: createError,
                canAdvanceFromCommon: canAdvanceFromCreateCommon,
                isTradingCardType: isTradingCardType,
                isProcessingTradingCardBulk: isProcessingTradingCardBulk,
                tradingCardBulkStatusMessage: tradingCardBulkStatusMessage,
                canSaveMetas: canSaveInventoryCreateMetas,
                isItemReadOnly: isItemReadOnly,
                isCreatingGoodsEntry: isCreatingGoodsEntry,
                tagSuggestions: tagSuggestions,
                onRemoveTag: onRemoveTag,
                onAddTag: onAddTag,
                onAddSuggestedTag: onAddSuggestedTag,
                onShowOshiPicker: onShowCreateOshiPicker,
                onCommonNext: onCommonNext,
                onPickCamera: onPickCamera,
                onPickPhotos: onPickPhotos,
                onStartTradingCardBulk: onStartTradingCardBulk,
                onRemovePhoto: onRemovePhoto,
                onCropPhoto: onCropPhoto,
                onShootBack: onShootBack,
                onShootNext: onShootNext,
                onContinueWithoutPhoto: onContinueWithoutPhoto,
                onMetaBack: onMetaBack,
                onSaveMetas: onSaveMetas
            )
        } else {
            GoodsEditorStandardSectionsView(
                draft: $draft,
                tagDraft: $tagDraft,
                isTagFieldFocused: isTagFieldFocused,
                groups: groups,
                isLoadingOshiGroups: isLoadingOshiGroups,
                members: members,
                isLoadingOshiCharacters: isLoadingOshiCharacters,
                goodsTypes: goodsTypes,
                isLoadingGoodsTypes: isLoadingGoodsTypes,
                selectedGroupSupportsMemberSelection: selectedGroupSupportsMemberSelection,
                includesStatus: draft.mode == .create && draft.entryKind == .inventory,
                tagSuggestions: tagSuggestions,
                photoError: photoError,
                photoActionTitle: photoActionTitle,
                titlePreview: titlePreview,
                wishImageHint: wishImageHint,
                isItemReadOnly: isItemReadOnly,
                isWishPhotoRemovalLocked: isWishPhotoRemovalLocked,
                onShowOshiPicker: onShowCreateOshiPicker,
                onShowPhotoSource: onShowPhotoSource,
                onClearLocalPhoto: onClearLocalPhoto,
                onRemoveWishPhoto: onRemoveWishPhoto,
                onRemoveTag: onRemoveTag,
                onAddTag: onAddTag,
                onAddSuggestedTag: onAddSuggestedTag,
                onOpenTagSheet: onOpenTagSheet
            )
        }
    }
}
