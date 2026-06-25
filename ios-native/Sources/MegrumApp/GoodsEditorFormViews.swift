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
    var selectedCreateMetaIDs: Set<UUID>
    var groups: [OshiGroup]
    var isLoadingOshiGroups: Bool
    var members: [OshiCharacter]
    var isLoadingOshiCharacters: Bool
    var goodsTypes: [GoodsType]
    var isLoadingGoodsTypes: Bool
    var selectedGroupName: String?
    var selectedGroupSupportsMemberSelection: Bool
    var inventoryCreateAllowsMemberAssignment: Bool
    var createError: String?
    var canAdvanceFromCreateCommon: Bool
    var isTradingCardType: Bool
    var isProcessingTradingCardBulk: Bool
    var tradingCardBulkStatusMessage: String?
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
    var onMetaBack: () -> Void
    var onToggleMetaSelection: (UUID) -> Void
    var onSelectAllMetas: () -> Void
    var onClearMetaSelection: () -> Void
    var onRemoveMetaTag: (UUID, String) -> Void
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
                createMetas: $createMetas,
                createStep: createStep,
                createPhotos: createPhotos,
                selectedCreateMetaIDs: selectedCreateMetaIDs,
                groups: groups,
                isLoadingOshiGroups: isLoadingOshiGroups,
                goodsTypes: goodsTypes,
                isLoadingGoodsTypes: isLoadingGoodsTypes,
                oshiCharacters: members,
                allowsMemberSelection: inventoryCreateAllowsMemberAssignment,
                selectedGroupName: selectedGroupName,
                createError: createError,
                canAdvanceFromCommon: canAdvanceFromCreateCommon,
                isTradingCardType: isTradingCardType,
                isProcessingTradingCardBulk: isProcessingTradingCardBulk,
                tradingCardBulkStatusMessage: tradingCardBulkStatusMessage,
                isItemReadOnly: isItemReadOnly,
                isCreatingGoodsEntry: isCreatingGoodsEntry,
                onShowOshiPicker: onShowCreateOshiPicker,
                onCommonNext: onCommonNext,
                onPickCamera: onPickCamera,
                onPickPhotos: onPickPhotos,
                onStartTradingCardBulk: onStartTradingCardBulk,
                onRemovePhoto: onRemovePhoto,
                onCropPhoto: onCropPhoto,
                onShootBack: onShootBack,
                onShootNext: onShootNext,
                onMetaBack: onMetaBack,
                onToggleMetaSelection: onToggleMetaSelection,
                onSelectAllMetas: onSelectAllMetas,
                onClearMetaSelection: onClearMetaSelection,
                onRemoveMetaTag: onRemoveMetaTag
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
