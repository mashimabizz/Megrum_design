import Foundation
import MegrumCore
import MegrumDesign
#if canImport(PhotosUI)
import PhotosUI
#endif
import SwiftUI

struct GoodsEditorSheet: View {
    @ObservedObject var appState: MegrumAppState
    var route: GoodsEditorRoute

    enum PhotoCaptureTarget {
        case draft
        case inventoryCreate
        case tradingCardBulk
    }

    @Environment(\.dismiss) var dismiss
    @State var draft: GoodsEditorDraft
    @State var tagDraft = ""
    @State var photoError: String?
    @State var lastSaveFailure: GoodsEditorSaveFailure?
    @State var createStep: GoodsCreateStep = .common
    @State var createPhotos: [GoodsCreatePhotoDraft] = []
    @State var createMetas: [GoodsCreateMetaDraft] = [GoodsCreateMetaDraft()]
    @State var createError: String?
    @State var photoCaptureTarget: PhotoCaptureTarget = .draft
    @State var isShowingPhotoRemovalDialog = false
    @State var isShowingPhotoSourceDialog = false
    @State var isShowingPhotoLibraryPicker = false
    @State var isShowingCreatePhotoLibraryPicker = false
    @State var isShowingCameraCapture = false
    @State var isConfirmingInventoryDelete = false
    @State var isShowingTradingCardBulkSourceDialog = false
    @State var isShowingTradingCardBulkPhotoLibraryPicker = false
    @State var isProcessingTradingCardBulk = false
    @State var tradingCardBulkStatusMessage: String?
    @State var cropSession: GoodsPhotoCropSession?
    @State var faceTaggingReviewQueue = FaceTaggingReviewQueue()
    @State var showsCreateOshiMasterSheet = false
    @State var createOshiRequestSheet: OshiRequestSheetState?
    @State var deleteErrorMessage: String?
    @State var didAssignDefaults = false
    @State var isShowingTagSelectionSheet = false
    @FocusState var isTagFieldFocused: Bool
    #if canImport(PhotosUI)
    @State var selectedPhotoItem: PhotosPickerItem?
    @State var selectedCreatePhotoItems: [PhotosPickerItem] = []
    @State var selectedTradingCardBulkPhotoItem: PhotosPickerItem?
    #endif

    init(appState: MegrumAppState, route: GoodsEditorRoute) {
        self.appState = appState
        self.route = route
        _draft = State(initialValue: GoodsEditorDraft(mode: route.mode, entryKind: route.kind, item: route.item))
    }

    var body: some View {
        GoodsEditorSheetScrollContent(
            blockingReasons: draft.blockingReasons,
            lastSaveFailure: lastSaveFailure,
            usesInventoryCreateFlow: usesInventoryCreateFlow,
            entryKind: draft.entryKind,
            mode: draft.mode,
            existingItemID: draft.existingItemID,
            isItemReadOnly: isItemReadOnly,
            isSavingCurrentItem: isSavingCurrentItem,
            isMutatingCurrentItem: appState.mutatingGoodsItemID == draft.existingItemID,
            canSave: canSave,
            saveButtonTitle: saveButtonTitle,
            onRetrySave: retrySave,
            onRequestPhotoRemoval: requestPhotoRemoval,
            onClose: dismissEditor,
            onSave: startSave,
            onConfirmDelete: requestInventoryDeleteConfirmation
        ) {
            formContent
        }
            .scrollDismissesKeyboard(.interactively)
            .background(MegrumTheme.canvas.ignoresSafeArea())
            .navigationTitle(navigationTitle)
            .megrumInlineNavigationTitle()
            .toolbar {
                editorToolbar
            }
            .task {
                await loadChoices()
            }
            .onChange(of: appState.oshiGroups) { _, _ in
                assignDefaultsIfNeeded()
            }
            .onChange(of: appState.goodsTypes) { _, _ in
                assignDefaultsIfNeeded()
            }
            .onChange(of: draft.groupID) { _, newValue in
                handleSelectedGroupChange(newValue)
            }
            .onChange(of: draft.entryKind) { _, _ in
                resetInventoryCreateFlow()
            }
            .onChange(of: draft) { _, _ in
                clearTransientEditorFeedback()
            }
            .goodsEditorFailureAlerts(
                lastSaveFailure: $lastSaveFailure,
                deleteErrorMessage: $deleteErrorMessage,
                onRetry: retrySave,
                onClearPhoto: clearLocalPhotoSelection
            )
            .goodsEditorDialogs(
                isShowingPhotoRemovalDialog: $isShowingPhotoRemovalDialog,
                isShowingPhotoSourceDialog: $isShowingPhotoSourceDialog,
                isShowingPhotoLibraryPicker: $isShowingPhotoLibraryPicker,
                isShowingCameraCapture: $isShowingCameraCapture,
                isConfirmingInventoryDelete: $isConfirmingInventoryDelete,
                photoSourceDialogTitle: photoSourceDialogTitle,
                onClearPhoto: clearLocalPhotoSelection,
                onDeleteInventory: startDeleteInventoryItem
            )
#if canImport(PhotosUI)
            .photosPicker(isPresented: $isShowingPhotoLibraryPicker, selection: $selectedPhotoItem, matching: .images)
            .photosPicker(
                isPresented: $isShowingCreatePhotoLibraryPicker,
                selection: $selectedCreatePhotoItems,
                maxSelectionCount: 0,
                matching: .images
            )
            .photosPicker(
                isPresented: $isShowingTradingCardBulkPhotoLibraryPicker,
                selection: $selectedTradingCardBulkPhotoItem,
                matching: .images
            )
            .onChange(of: selectedPhotoItem) { _, newValue in
                handleSelectedPhotoItemChange(newValue)
            }
            .onChange(of: selectedCreatePhotoItems) { _, newValue in
                handleSelectedCreatePhotoItemsChange(newValue)
            }
            .onChange(of: selectedTradingCardBulkPhotoItem) { _, newValue in
                handleSelectedTradingCardBulkPhotoItemChange(newValue)
            }
#endif
#if os(iOS)
            .sheet(isPresented: $isShowingCameraCapture) {
                NativeCameraCaptureView { imageData in
                    loadCapturedCameraPhoto(imageData)
                } onFailure: { message in
                    photoError = message
                    createError = message
                }
                .ignoresSafeArea()
            }
#endif
            .sheet(item: $cropSession) { session in
                GoodsPhotoCropSheet(
                    session: session,
                    title: cropSheetTitle(for: session),
                    onCancel: { cropSession = nil },
                    onApply: { uploads in
                        applyCropUploads(uploads, from: session)
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
            }
            .sheet(
                item: $faceTaggingReviewQueue.current,
                onDismiss: presentNextFaceTaggingReview
            ) { context in
                FaceTaggingReviewSheet(
                    imageData: context.imageData,
                    analysis: context.analysis,
                    memberOptions: faceTaggingMemberOptions,
                    onSave: { drafts in
                        applyFaceTaggingCorrections(drafts, target: context.target)
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showsCreateOshiMasterSheet) {
                OshiMasterSelectSheet(
                    genres: appState.oshiGenres,
                    groups: appState.oshiGroups,
                    selectedGroupIDs: draft.groupID.map { Set([$0]) } ?? [],
                    charactersByGroupID: [:],
                    onClose: { showsCreateOshiMasterSheet = false },
                    onRequest: { query in
                        showsCreateOshiMasterSheet = false
                        createOshiRequestSheet = .oshi(initialName: query)
                    },
                    onSelect: selectCreateOshiGroup
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
            }
            .sheet(item: $createOshiRequestSheet) { state in
                OshiRequestSheet(
                    state: state,
                    genres: appState.oshiGenres,
                    onClose: { createOshiRequestSheet = nil },
                    onSubmit: { submitCreateOshiRequest($0) }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
            }
            .sheet(isPresented: $isShowingTagSelectionSheet) {
                GoodsBulkTagSheet(
                    selectedCount: 1,
                    candidateNames: editorTagSuggestions,
                    previewItemsByTag: editorTagPreviewItemsByTag,
                    navigationTitle: "タグを登録",
                    textFieldPlaceholder: "例：会場限定",
                    footerText: "このWishにタグを追加します。",
                    confirmationTitle: "追加",
                    onApply: addTagFromSelectionSheet
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .goodsEditorTradingCardBulkSourceDialog(
                isPresented: $isShowingTradingCardBulkSourceDialog,
                onPickCamera: startTradingCardBulkCamera,
                onPickPhotoLibrary: showTradingCardBulkPhotoLibrary
            )
    }

    @ToolbarContentBuilder
    private var editorToolbar: some ToolbarContent {
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

    private var navigationTitle: String {
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

    private var resolvedTitlePreview: String {
        draft.resolvedTitle(
            groupName: selectedGroup?.name,
            memberName: selectedMember?.name,
            goodsTypeName: selectedGoodsType?.name
        )
    }

    private var canSave: Bool {
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

    private var isSavingCurrentItem: Bool {
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

    private var editorTagSuggestions: [String] {
        return GoodsEditorTagSuggestionBuilder.suggestions(
            groupID: draft.groupID,
            selectedTags: draft.tagNames,
            inventory: appState.inventory,
            wishes: appState.wishes
        )
    }

    private var photoSourceDialogTitle: String {
        draft.hasDisplayPhoto ? "写真を差し替え" : "写真を追加"
    }

    private var photoActionTitle: String {
        GoodsEditorPresentationText.photoActionTitle(
            entryKind: draft.entryKind,
            hasDisplayPhoto: draft.hasDisplayPhoto
        )
    }

    private var wishImageHint: String {
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
    private var formContent: some View {
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

    private var headerDescription: String {
        GoodsEditorPresentationText.headerDescription(
            usesInventoryCreateFlow: usesInventoryCreateFlow,
            entryKind: draft.entryKind
        )
    }

    private var editorTagPreviewItemsByTag: [String: [TagPreviewItem]] {
        IndividualListingConditionTagBuilder(
            inventory: appState.inventory,
            wishes: appState.wishes,
            selectedGroupID: draft.groupID
        )
        .previewItemsByTag()
    }

    private var saveButtonTitle: String {
        GoodsEditorPresentationText.saveButtonTitle(
            mode: draft.mode,
            entryKind: draft.entryKind,
            isMutatingCurrentItem: appState.mutatingGoodsItemID == draft.existingItemID,
            isCreatingGoodsEntry: appState.isCreatingGoodsEntry
        )
    }

    private func dismissEditor() {
        dismiss()
    }

    private func startSave() {
        Task {
            await save()
        }
    }

    private func retrySave() {
        startSave()
    }

    private func requestPhotoRemoval() {
        isShowingPhotoRemovalDialog = true
    }

    private func requestInventoryDeleteConfirmation() {
        isConfirmingInventoryDelete = true
    }

    private func startDeleteInventoryItem() {
        Task {
            await deleteInventoryItem()
        }
    }

    private func startInventoryCreateCamera() {
        photoCaptureTarget = .inventoryCreate
        isShowingCameraCapture = true
    }

    private func showInventoryCreatePhotoLibrary() {
        isShowingCreatePhotoLibraryPicker = true
    }

    private func returnToCreateCommonStep() {
        createStep = .common
    }

    private func returnFromCreateMetaStep() {
        createStep = createPhotos.isEmpty ? .common : .shoot
    }

    private func startSaveInventoryCreateFlow() {
        Task {
            await saveInventoryCreateFlow()
        }
    }

    private func handleSelectedGroupChange(_ groupID: UUID?) {
        resetCreateMetaMembers()
        Task {
            await loadMembers(for: groupID)
        }
    }

    private func clearTransientEditorFeedback() {
        lastSaveFailure = nil
        createError = nil
    }

    #if canImport(PhotosUI)
    private func handleSelectedPhotoItemChange(_ item: PhotosPickerItem?) {
        Task {
            await loadSelectedPhoto(item)
        }
    }

    private func handleSelectedCreatePhotoItemsChange(_ items: [PhotosPickerItem]) {
        Task {
            await loadSelectedCreatePhotos(items)
        }
    }

    private func handleSelectedTradingCardBulkPhotoItemChange(_ item: PhotosPickerItem?) {
        Task {
            await loadSelectedTradingCardBulkPhoto(item)
        }
    }
    #endif

}
