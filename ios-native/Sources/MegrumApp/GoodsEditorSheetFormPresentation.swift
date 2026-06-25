import SwiftUI

extension GoodsEditorSheet {
    @ViewBuilder
    var formContent: some View {
        GoodsEditorFormContentView(
            draft: $draft,
            tagDraft: $tagDraft,
            isTagFieldFocused: $isTagFieldFocused,
            createMetas: $createMetas,
            navigationTitle: navigationTitle,
            headerDescription: headerDescription,
            usesInventoryCreateFlow: usesInventoryCreateFlow,
            isItemReadOnly: isItemReadOnly,
            createStep: createStep,
            createPhotos: createPhotos,
            groups: appState.oshiGroups,
            isLoadingOshiGroups: appState.isLoadingOshiGroups,
            members: scopedOshiCharacters,
            isLoadingOshiCharacters: appState.isLoadingOshiCharacters,
            goodsTypes: appState.goodsTypes,
            isLoadingGoodsTypes: appState.isLoadingGoodsTypes,
            selectedGroupName: selectedGroup?.name,
            selectedGroupSupportsMemberSelection: selectedGroupSupportsMemberSelection,
            selectedGoodsTypeName: selectedGoodsType?.name,
            createError: createError,
            canAdvanceFromCreateCommon: canAdvanceFromCreateCommon,
            isTradingCardType: isTradingCardType,
            isProcessingTradingCardBulk: isProcessingTradingCardBulk,
            tradingCardBulkStatusMessage: tradingCardBulkStatusMessage,
            canSaveInventoryCreateMetas: canSaveInventoryCreateMetas,
            isCreatingGoodsEntry: appState.isCreatingGoodsEntry,
            tagSuggestions: editorTagSuggestions,
            photoError: photoError,
            photoActionTitle: photoActionTitle,
            titlePreview: resolvedTitlePreview,
            wishImageHint: wishImageHint,
            isWishPhotoRemovalLocked: isWishPhotoRemovalLocked,
            onRemoveTag: removeTag,
            onAddTag: addCurrentTag,
            onAddSuggestedTag: addSuggestedTag,
            onOpenTagSheet: draft.entryKind == .wish ? { isShowingTagSelectionSheet = true } : nil,
            onShowCreateOshiPicker: showCreateOshiMasterSheet,
            onCommonNext: goToCreateShoot,
            onPickCamera: startInventoryCreateCamera,
            onPickPhotos: showInventoryCreatePhotoLibrary,
            onStartTradingCardBulk: showTradingCardBulkSourceDialog,
            onRemovePhoto: removeCreatePhoto,
            onCropPhoto: showCropForCreatePhoto,
            onShootBack: returnToCreateCommonStep,
            onShootNext: goToCreateMetaWithPhotos,
            onContinueWithoutPhoto: goToCreateMetaWithoutPhoto,
            onMetaBack: returnFromCreateMetaStep,
            onSaveMetas: startSaveInventoryCreateFlow,
            onShowPhotoSource: showDraftPhotoSourceDialog,
            onClearLocalPhoto: clearLocalPhotoSelection,
            onRemoveWishPhoto: removeWishPhoto
        )
    }

    var headerDescription: String {
        GoodsEditorPresentationText.headerDescription(
            usesInventoryCreateFlow: usesInventoryCreateFlow,
            entryKind: draft.entryKind
        )
    }

    var editorTagPreviewItemsByTag: [String: [TagPreviewItem]] {
        IndividualListingConditionTagBuilder(
            inventory: appState.inventory,
            wishes: appState.wishes,
            selectedGroupID: draft.groupID
        )
        .previewItemsByTag()
    }

    var saveButtonTitle: String {
        GoodsEditorPresentationText.saveButtonTitle(
            mode: draft.mode,
            entryKind: draft.entryKind,
            isMutatingCurrentItem: appState.mutatingGoodsItemID == draft.existingItemID,
            isCreatingGoodsEntry: appState.isCreatingGoodsEntry
        )
    }
}
