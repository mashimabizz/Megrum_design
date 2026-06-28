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
            selectedCreateMetaIDs: selectedCreateMetaIDs,
            groups: appState.oshiGroups,
            isLoadingOshiGroups: appState.isLoadingOshiGroups,
            members: scopedOshiCharacters,
            isLoadingOshiCharacters: appState.isLoadingOshiCharacters,
            goodsTypes: appState.goodsTypes,
            isLoadingGoodsTypes: appState.isLoadingGoodsTypes,
            selectedGroupName: selectedGroup?.name,
            selectedGroupSupportsMemberSelection: selectedGroupSupportsMemberSelection,
            inventoryCreateAllowsMemberAssignment: inventoryCreateAllowsMemberAssignment,
            createError: createError,
            canAdvanceFromCreateCommon: canAdvanceFromCreateCommon,
            isTradingCardType: isTradingCardType,
            isProcessingTradingCardBulk: isProcessingTradingCardBulk,
            tradingCardBulkStatusMessage: tradingCardBulkStatusMessage,
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
            onOpenTagSheet: draft.entryKind == .wish ? { showDraftTagSheet() } : nil,
            onShowCreateOshiPicker: showCreateOshiMasterSheet,
            onCommonNext: goToCreateShoot,
            onPickCamera: startInventoryCreateCamera,
            onPickPhotos: showInventoryCreatePhotoLibrary,
            onStartTradingCardBulk: showTradingCardBulkSourceDialog,
            onRemovePhoto: removeCreatePhoto,
            onCropPhoto: showCropForCreatePhoto,
            onShootBack: returnToCreateCommonStep,
            onShootNext: goToCreateMetaWithPhotos,
            onMetaBack: returnFromCreateMetaStep,
            onToggleMetaSelection: toggleCreateMetaSelection,
            onSelectAllMetas: selectAllCreateMetas,
            onClearMetaSelection: clearCreateMetaSelection,
            onRemoveMetaTag: removeCreateMetaTag,
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

    var createBulkTagSuggestions: [String] {
        GoodsEditorTagSuggestionBuilder.suggestions(
            groupID: draft.groupID,
            selectedTags: selectedCreateMetas.flatMap(\.tagNames),
            inventory: appState.inventory,
            wishes: appState.wishes
        )
    }

    var fixedInventoryCreateFooter: AnyView? {
        guard usesInventoryCreateFlow, createStep == .meta else {
            return nil
        }
        return AnyView(
            GoodsInventoryCreateMetaFooterView(
                selectedCount: selectedCreateMetaIDs.count,
                totalCount: createMetas.count,
                memberOptions: scopedOshiCharacters,
                allowsMemberSelection: inventoryCreateAllowsMemberAssignment,
                canSaveMetas: canSaveInventoryCreateMetas,
                isCreatingGoodsEntry: appState.isCreatingGoodsEntry,
                onAssignMember: applyCreateBulkMember,
                onShowTagAssignment: showCreateBulkTagSheet,
                onBack: returnFromCreateMetaStep,
                onSave: startSaveInventoryCreateFlow
            )
        )
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
