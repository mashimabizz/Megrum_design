import Foundation
import MegrumCore
import MegrumDesign
#if canImport(PhotosUI)
import PhotosUI
#endif
import SwiftUI

extension GoodsEditorSheet {
    @ToolbarContentBuilder
    var editorToolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("閉じる", action: dismissEditor)
        }
        if draft.mode != .create {
            ToolbarItem(placement: .confirmationAction) {
                Text(draft.mode.badgeTitle)
                    .font(.caption.weight(.black))
                    .foregroundStyle(MegrumTheme.lavender)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(MegrumTheme.lavender.opacity(0.12), in: Capsule())
            }
        }
    }

    var navigationTitle: String {
        GoodsEditorPresentationText.navigationTitle(mode: draft.mode, entryKind: draft.entryKind)
    }

    var selectedGroup: OshiGroup? {
        guard let groupID = draft.groupID else {
            return nil
        }
        return appState.oshiGroups.first { $0.id == groupID }
    }

    var selectedMember: OshiCharacter? {
        guard let memberID = draft.memberID else {
            return nil
        }
        return scopedOshiCharacters.first { $0.id == memberID }
    }

    var selectedGroupSupportsMemberSelection: Bool {
        selectedGroup?.supportsMemberSelection == true
    }

    var scopedOshiCharacters: [OshiCharacter] {
        GoodsEditorMemberScope.members(for: selectedGroup, from: appState.oshiCharacters)
    }

    var faceTaggingMemberOptions: [FaceTaggingMemberOption] {
        scopedOshiCharacters.map { member in
            FaceTaggingMemberOption(memberID: member.id, name: member.name)
        }
    }

    var selectedGoodsType: GoodsType? {
        guard let goodsTypeID = draft.goodsTypeID else {
            return nil
        }
        return appState.goodsTypes.first { $0.id == goodsTypeID }
    }

    var resolvedTitlePreview: String {
        draft.resolvedTitle(
            groupName: selectedGroup?.name,
            memberName: selectedMember?.name,
            goodsTypeName: selectedGoodsType?.name
        )
    }

    var canSave: Bool {
        guard !isItemReadOnly else {
            return false
        }
        switch draft.mode {
        case .create:
            return draft.createInput(
                groupName: selectedGroup?.name,
                memberName: selectedMember?.name,
                goodsTypeName: selectedGoodsType?.name
            ) != nil && !appState.isCreatingGoodsEntry
        case .edit:
            return draft.existingItemID != nil
                && draft.updateInput(
                    groupName: selectedGroup?.name,
                    memberName: selectedMember?.name,
                    goodsTypeName: selectedGoodsType?.name
                ) != nil
                && appState.mutatingGoodsItemID != draft.existingItemID
        case .readonly:
            return false
        }
    }

    var isItemReadOnly: Bool {
        draft.mode == .readonly || (draft.entryKind == .inventory && draft.status == .traded)
    }

    var isSavingCurrentItem: Bool {
        switch draft.mode {
        case .create:
            appState.isCreatingGoodsEntry
        case .edit:
            appState.mutatingGoodsItemID == draft.existingItemID
        case .readonly:
            false
        }
    }

    var usesInventoryCreateFlow: Bool {
        draft.mode == .create && draft.entryKind == .inventory
    }

    var canAdvanceFromCreateCommon: Bool {
        draft.groupID != nil && draft.goodsTypeID != nil
    }

    var isTradingCardType: Bool {
        selectedGoodsType?.name == "トレカ"
    }

    var editorTagSuggestions: [String] {
        GoodsEditorTagSuggestionBuilder.suggestions(
            groupID: draft.groupID,
            selectedTags: draft.tagNames,
            inventory: appState.inventory,
            wishes: appState.wishes
        )
    }

    var photoSourceDialogTitle: String {
        draft.hasDisplayPhoto ? "写真を差し替え" : "写真を追加"
    }

    var photoActionTitle: String {
        GoodsEditorPresentationText.photoActionTitle(
            entryKind: draft.entryKind,
            hasDisplayPhoto: draft.hasDisplayPhoto
        )
    }

    var wishImageHint: String {
        GoodsEditorPresentationText.wishImageHint(hasDisplayPhoto: draft.hasDisplayPhoto)
    }

    var isWishPhotoRemovalLocked: Bool {
        GoodsEditorWishPhotoRemovalPolicy.isRemovalLocked(
            itemID: draft.existingItemID,
            entryKind: draft.entryKind,
            listings: appState.listings
        )
    }

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

    func dismissEditor() {
        dismiss()
    }

    func startSave() {
        Task {
            await save()
        }
    }

    func retrySave() {
        startSave()
    }

    func requestPhotoRemoval() {
        isShowingPhotoRemovalDialog = true
    }

    func requestInventoryDeleteConfirmation() {
        isConfirmingInventoryDelete = true
    }

    func startDeleteInventoryItem() {
        Task {
            await deleteInventoryItem()
        }
    }

    func startInventoryCreateCamera() {
        photoCaptureTarget = .inventoryCreate
        isShowingCameraCapture = true
    }

    func showInventoryCreatePhotoLibrary() {
        isShowingCreatePhotoLibraryPicker = true
    }

    func returnToCreateCommonStep() {
        createStep = .common
    }

    func returnFromCreateMetaStep() {
        createStep = createPhotos.isEmpty ? .common : .shoot
    }

    func startSaveInventoryCreateFlow() {
        Task {
            await saveInventoryCreateFlow()
        }
    }

    func handleSelectedGroupChange(_ groupID: UUID?) {
        resetCreateMetaMembers()
        Task {
            await loadMembers(for: groupID)
        }
    }

    func clearTransientEditorFeedback() {
        lastSaveFailure = nil
        createError = nil
    }

    #if canImport(PhotosUI)
    func handleSelectedPhotoItemChange(_ item: PhotosPickerItem?) {
        Task {
            await loadSelectedPhoto(item)
        }
    }

    func handleSelectedCreatePhotoItemsChange(_ items: [PhotosPickerItem]) {
        Task {
            await loadSelectedCreatePhotos(items)
        }
    }

    func handleSelectedTradingCardBulkPhotoItemChange(_ item: PhotosPickerItem?) {
        Task {
            await loadSelectedTradingCardBulkPhoto(item)
        }
    }
    #endif
}
