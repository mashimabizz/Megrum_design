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

    private enum PhotoCaptureTarget {
        case draft
        case inventoryCreate
        case tradingCardBulk
    }

    @Environment(\.dismiss) private var dismiss
    @State private var draft: GoodsEditorDraft
    @State private var tagDraft = ""
    @State private var photoError: String?
    @State private var lastSaveFailure: GoodsEditorSaveFailure?
    @State private var createStep: GoodsCreateStep = .common
    @State private var createPhotos: [GoodsCreatePhotoDraft] = []
    @State private var createMetas: [GoodsCreateMetaDraft] = [GoodsCreateMetaDraft()]
    @State private var createError: String?
    @State private var photoCaptureTarget: PhotoCaptureTarget = .draft
    @State private var isShowingPhotoRemovalDialog = false
    @State private var isShowingPhotoSourceDialog = false
    @State private var isShowingPhotoLibraryPicker = false
    @State private var isShowingCreatePhotoLibraryPicker = false
    @State private var isShowingCameraCapture = false
    @State private var isConfirmingInventoryDelete = false
    @State private var isShowingTradingCardBulkSourceDialog = false
    @State private var isShowingTradingCardBulkPhotoLibraryPicker = false
    @State private var isProcessingTradingCardBulk = false
    @State private var tradingCardBulkStatusMessage: String?
    @State private var cropSession: GoodsPhotoCropSession?
    @State private var faceTaggingReviewQueue = FaceTaggingReviewQueue()
    @State private var showsCreateOshiMasterSheet = false
    @State private var createOshiRequestSheet: OshiRequestSheetState?
    @State private var deleteErrorMessage: String?
    @State private var didAssignDefaults = false
    @FocusState private var isTagFieldFocused: Bool
    #if canImport(PhotosUI)
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedCreatePhotoItems: [PhotosPickerItem] = []
    @State private var selectedTradingCardBulkPhotoItem: PhotosPickerItem?
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

    private var selectedGroup: OshiGroup? {
        guard let groupID = draft.groupID else {
            return nil
        }
        return appState.oshiGroups.first { $0.id == groupID }
    }

    private var selectedMember: OshiCharacter? {
        guard let memberID = draft.memberID else {
            return nil
        }
        return scopedOshiCharacters.first { $0.id == memberID }
    }

    private var selectedGroupSupportsMemberSelection: Bool {
        selectedGroup?.supportsMemberSelection == true
    }

    private var scopedOshiCharacters: [OshiCharacter] {
        GoodsEditorMemberScope.members(for: selectedGroup, from: appState.oshiCharacters)
    }

    private var faceTaggingMemberOptions: [FaceTaggingMemberOption] {
        scopedOshiCharacters.map { member in
            FaceTaggingMemberOption(memberID: member.id, name: member.name)
        }
    }

    private var selectedGoodsType: GoodsType? {
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

    private var isItemReadOnly: Bool {
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

    private var usesInventoryCreateFlow: Bool {
        draft.mode == .create && draft.entryKind == .inventory
    }

    private var canAdvanceFromCreateCommon: Bool {
        draft.groupID != nil && draft.goodsTypeID != nil
    }

    private var isTradingCardType: Bool {
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

    private var isWishPhotoRemovalLocked: Bool {
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

    private var canSaveInventoryCreateMetas: Bool {
        !inventoryCreateInputs().isEmpty && !appState.isCreatingGoodsEntry
    }

    private func goToCreateShoot() {
        guard canAdvanceFromCreateCommon else {
            createError = "グループとグッズ種別を選択してください"
            return
        }
        createError = nil
        createStep = .shoot
    }

    private func goToCreateMetaWithPhotos() {
        guard !createPhotos.isEmpty else {
            createError = "登録する写真を選んでください"
            return
        }
        syncCreateMetasWithPhotos()
        createError = nil
        createStep = .meta
    }

    private func goToCreateMetaWithoutPhoto() {
        createMetas = [GoodsCreateMetaDraft()]
        createError = nil
        createStep = .meta
    }

    private func resetInventoryCreateFlow() {
        createStep = .common
        createPhotos = []
        createMetas = [GoodsCreateMetaDraft()]
        createError = nil
        photoError = nil
        tradingCardBulkStatusMessage = nil
        isProcessingTradingCardBulk = false
        cropSession = nil
        showsCreateOshiMasterSheet = false
        createOshiRequestSheet = nil
        #if canImport(PhotosUI)
        selectedCreatePhotoItems = []
        selectedTradingCardBulkPhotoItem = nil
        #endif
    }

    private func resetCreateMetaMembers() {
        guard usesInventoryCreateFlow else {
            return
        }
        createMetas = createMetas.map { meta in
            var next = meta
            next.memberID = nil
            return next
        }
    }

    private func syncCreateMetasWithPhotos() {
        guard !createPhotos.isEmpty else {
            if createMetas.isEmpty {
                createMetas = [GoodsCreateMetaDraft()]
            }
            return
        }
        let currentByPhotoID = Dictionary(uniqueKeysWithValues: createMetas.compactMap { meta in
            meta.photoID.map { ($0, meta) }
        })
        createMetas = createPhotos.map { photo in
            currentByPhotoID[photo.id] ?? GoodsCreateMetaDraft(photoID: photo.id)
        }
    }

    private func removeCreatePhoto(_ photoID: UUID) {
        createPhotos.removeAll { $0.id == photoID }
        if createStep == .meta {
            syncCreateMetasWithPhotos()
        } else {
            createMetas.removeAll { $0.photoID == photoID }
        }
    }

    private func showCropForCreatePhoto(_ photoID: UUID) {
        guard let photo = createPhotos.first(where: { $0.id == photoID }) else {
            return
        }
        cropSession = GoodsPhotoCropSession(
            source: .selectedPhoto(photoID: photoID),
            upload: photo.upload
        )
    }

    private func cropSheetTitle(for session: GoodsPhotoCropSession) -> String {
        switch session.source {
        case .selectedPhoto:
            "写真を切り取る"
        case .tradingCardBulk:
            "トレカAI一括登録"
        }
    }

    private func applyCropUploads(_ uploads: [GoodsPhotoUpload], from session: GoodsPhotoCropSession) {
        let nextDrafts = uploads.compactMap { upload -> GoodsCreatePhotoDraft? in
            if let uploadError = goodsEditorPhotoUploadError(for: upload) {
                createError = uploadError
                return nil
            }
            return GoodsCreatePhotoDraft(upload: upload)
        }

        guard !nextDrafts.isEmpty else {
            createError = createError ?? "切り取り画像を追加できませんでした"
            return
        }

        switch session.source {
        case .selectedPhoto(let photoID):
            if let index = createPhotos.firstIndex(where: { $0.id == photoID }) {
                createPhotos.replaceSubrange(index...index, with: nextDrafts)
            } else {
                createPhotos.append(contentsOf: nextDrafts)
            }
            tradingCardBulkStatusMessage = nil
        case .tradingCardBulk:
            createPhotos.append(contentsOf: nextDrafts)
            tradingCardBulkStatusMessage = "\(nextDrafts.count)枚の切り取り画像を写真一覧へ追加しました。"
        }

        if createStep == .meta {
            syncCreateMetasWithPhotos()
        }
        nextDrafts.forEach { draft in
            analyzeFaceTagsIfNeeded(upload: draft.upload, target: .createPhoto(draft.id))
        }
        createError = nil
        cropSession = nil
    }

    private func analyzeFaceTagsIfNeeded(upload: GoodsPhotoUpload, target: FaceTaggingReviewTarget) {
        let imageData = upload.data
        guard let group = selectedGroup, group.supportsMemberSelection else {
            return
        }
        let initialMemberIDs = GoodsEditorMemberScope.memberIDs(for: group, from: appState.oshiCharacters)

        Task {
            do {
                let eligibleMemberIDs: [UUID]
                if initialMemberIDs.isEmpty {
                    await loadMembers(for: group.id)
                    eligibleMemberIDs = GoodsEditorMemberScope.memberIDs(for: group, from: appState.oshiCharacters)
                } else {
                    eligibleMemberIDs = initialMemberIDs
                }
                guard !eligibleMemberIDs.isEmpty else {
                    return
                }

                let memberIDSet = Set(eligibleMemberIDs)
                let loadedProfiles = await appState.loadMemberFaceProfiles(memberIDs: eligibleMemberIDs)
                let memberProfiles = loadedProfiles.filter { memberIDSet.contains($0.memberID) }
                let service = UnifiedMemberTaggingService()
                let analysis = try await service.analyzeImage(
                    imageData,
                    imageID: UUID(),
                    memberProfiles: memberProfiles
                )
                guard !analysis.results.isEmpty else {
                    return
                }
                await MainActor.run {
                    enqueueFaceTaggingReview(
                        FaceTaggingReviewContext(
                            target: target,
                            imageData: imageData,
                            analysis: analysis
                        )
                    )
                }
            } catch {
                #if DEBUG
                print("Face tagging analysis failed: \(error)")
                #endif
            }
        }
    }

    private func enqueueFaceTaggingReview(_ context: FaceTaggingReviewContext) {
        faceTaggingReviewQueue.enqueue(context)
    }

    private func presentNextFaceTaggingReview() {
        faceTaggingReviewQueue.presentNextIfNeeded()
    }

    private func applyFaceTaggingCorrections(
        _ corrections: [FaceTaggingCorrectionDraft],
        target: FaceTaggingReviewTarget
    ) {
        guard let selectedMemberID = corrections.compactMap(\.selectedMemberID).first else {
            return
        }
        guard GoodsEditorMemberScope.canUseMemberID(
            selectedMemberID,
            group: selectedGroup,
            members: appState.oshiCharacters
        ) else {
            return
        }
        switch target {
        case .draft:
            draft.memberID = selectedMemberID
        case .createPhoto(let photoID):
            if let index = createMetas.firstIndex(where: { $0.photoID == photoID }) {
                createMetas[index].memberID = selectedMemberID
            } else {
                createMetas.append(GoodsCreateMetaDraft(photoID: photoID, memberID: selectedMemberID))
            }
        }
    }

    private func inventoryCreateInputs() -> [GoodsEntryInput] {
        GoodsInventoryCreateInputBuilder.inputs(
            metas: createMetas,
            photos: createPhotos,
            sharedDraft: draft,
            groupName: selectedGroup?.name,
            members: scopedOshiCharacters,
            goodsTypeName: selectedGoodsType?.name
        )
    }

    private func saveInventoryCreateFlow() async {
        guard canAdvanceFromCreateCommon else {
            createError = "グループとグッズ種別を選択してください"
            return
        }
        let inputs = inventoryCreateInputs()
        guard !inputs.isEmpty else {
            createError = "登録するアイテムがありません"
            return
        }

        createError = nil
        var savedCount = 0
        for input in inputs {
            let saved = await appState.createGoodsEntry(input)
            if !saved {
                let base = appState.errorMessage ?? "保存に失敗しました"
                createError = savedCount > 0 ? "\(savedCount)件は登録済みです。\(base)" : base
                return
            }
            savedCount += 1
        }
        dismiss()
    }

    private func loadChoices() async {
        if appState.oshiGroups.isEmpty || appState.oshiGenres.isEmpty {
            await appState.loadOshiGroups()
        }
        if appState.goodsTypes.isEmpty {
            await appState.loadGoodsTypes()
        }
        assignDefaultsIfNeeded()
        await loadMembers(for: draft.groupID)
        isTagFieldFocused = false
    }

    private func assignDefaultsIfNeeded() {
        guard draft.mode == .create, !didAssignDefaults else {
            return
        }
        let skipsGroupDefault = usesInventoryCreateFlow && draft.entryKind == .inventory
        if draft.groupID == nil && !skipsGroupDefault {
            draft.groupID = appState.oshiGroups.first?.id
        }
        if draft.goodsTypeID == nil {
            draft.goodsTypeID = appState.goodsTypes.first?.id
        }
        didAssignDefaults = (skipsGroupDefault || draft.groupID != nil) && draft.goodsTypeID != nil
    }

    private func loadMembers(for groupID: UUID?) async {
        guard let groupID,
              let group = appState.oshiGroups.first(where: { $0.id == groupID })
        else {
            draft.memberID = nil
            resetCreateMetaMembers()
            await appState.loadOshiCharacters(group: nil)
            return
        }
        guard group.supportsMemberSelection else {
            draft.memberID = nil
            resetCreateMetaMembers()
            await appState.loadOshiCharacters(group: nil)
            return
        }
        await appState.loadOshiCharacters(group: group)
        if let memberID = draft.memberID,
           !GoodsEditorMemberScope.canUseMemberID(memberID, group: group, members: appState.oshiCharacters) {
            draft.memberID = nil
        }
    }

    private func addCurrentTag() {
        guard !isItemReadOnly else {
            return
        }
        draft.addTag(tagDraft)
        tagDraft = ""
    }

    private func addSuggestedTag(_ tag: String) {
        guard !isItemReadOnly else {
            return
        }
        draft.addTag(tag)
    }

    private func showCreateOshiMasterSheet() {
        showsCreateOshiMasterSheet = true
    }

    private func selectCreateOshiGroup(_ group: OshiGroup) {
        draft.groupID = group.id
        draft.memberID = nil
        createError = nil
        showsCreateOshiMasterSheet = false
        Task {
            await loadMembers(for: group.id)
        }
    }

    private func submitCreateOshiRequest(_ payload: OshiRequestSheetPayload) {
        Task {
            await submitCreateOshiRequestAsync(payload)
        }
    }

    private func submitCreateOshiRequestAsync(_ payload: OshiRequestSheetPayload) async {
        createOshiRequestSheet = nil
        guard await appState.createOshiRequest(
            OshiRequestCreateInput(
                requestedName: payload.name,
                requestedKind: payload.kind,
                requestedGenreID: payload.genreID,
                note: payload.note
            )
        ) != nil else {
            createError = appState.errorMessage ?? "追加リクエストを送信できませんでした"
            return
        }
        createError = nil
    }

    private func removeTag(_ tag: String) {
        draft.removeTag(tag)
    }

    private func clearLocalPhotoSelection() {
        draft.clearLocalPhotoSelection()
        photoError = nil
        #if canImport(PhotosUI)
        selectedPhotoItem = nil
        #endif
    }

    private func showDraftPhotoSourceDialog() {
        photoCaptureTarget = .draft
        isShowingPhotoSourceDialog = true
    }

    private func showTradingCardBulkSourceDialog() {
        isShowingTradingCardBulkSourceDialog = true
    }

    private func startTradingCardBulkCamera() {
        photoCaptureTarget = .tradingCardBulk
        isShowingCameraCapture = true
    }

    private func showTradingCardBulkPhotoLibrary() {
        isShowingTradingCardBulkPhotoLibraryPicker = true
    }

    private func removeWishPhoto() {
        guard draft.entryKind == .wish, !isItemReadOnly else {
            return
        }
        if isWishPhotoRemovalLocked {
            photoError = "この WISH は個別募集で使用中のため画像を削除できません（差し替えは可能）"
            return
        }
        draft.removeDisplayPhoto()
        photoError = nil
        #if canImport(PhotosUI)
        selectedPhotoItem = nil
        #endif
    }

    private func loadCapturedCameraPhoto(_ data: Data) {
        if photoCaptureTarget == .tradingCardBulk {
            Task {
                await processTradingCardBulkImage(data)
            }
            return
        }

        let upload = GoodsPhotoUpload(data: data, contentType: "image/jpeg")
        if let uploadError = goodsEditorPhotoUploadError(for: upload) {
            if photoCaptureTarget == .draft {
                draft.clearLocalPhotoSelection()
            }
            photoError = uploadError
            createError = uploadError
            return
        }
        if photoCaptureTarget == .inventoryCreate {
            let photo = GoodsCreatePhotoDraft(upload: upload)
            createPhotos.append(photo)
            if createStep == .meta {
                syncCreateMetasWithPhotos()
            }
            analyzeFaceTagsIfNeeded(upload: upload, target: .createPhoto(photo.id))
            createError = nil
            photoError = nil
            return
        }
        draft.setLocalPhotoUpload(upload)
        analyzeFaceTagsIfNeeded(upload: upload, target: .draft)
        photoError = nil
        #if canImport(PhotosUI)
        selectedPhotoItem = nil
        #endif
    }

    #if canImport(PhotosUI)
    private func loadSelectedPhoto(_ item: PhotosPickerItem?) async {
        guard let item else {
            draft.hasLocalPhoto = false
            draft.localPhotoData = nil
            draft.localPhotoContentType = nil
            return
        }

        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                draft.hasLocalPhoto = false
                draft.localPhotoData = nil
                draft.localPhotoContentType = nil
                return
            }
            let upload = normalizedPhotoUpload(from: data)
            if let uploadError = goodsEditorPhotoUploadError(for: upload) {
                draft.hasLocalPhoto = false
                draft.localPhotoData = nil
                draft.localPhotoContentType = nil
                photoError = uploadError
                return
            }
            draft.setLocalPhotoUpload(upload)
            analyzeFaceTagsIfNeeded(upload: upload, target: .draft)
            photoError = nil
        } catch {
            draft.hasLocalPhoto = false
            draft.localPhotoData = nil
            draft.localPhotoContentType = nil
            photoError = "写真を読み込めませんでした"
        }
    }

    private func loadSelectedCreatePhotos(_ items: [PhotosPickerItem]) async {
        guard !items.isEmpty else {
            return
        }

        var nextPhotos: [GoodsCreatePhotoDraft] = []
        var lastError: String?
        for item in items {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    lastError = "写真を読み込めませんでした"
                    continue
                }
                let upload = normalizedPhotoUpload(from: data)
                if let uploadError = goodsEditorPhotoUploadError(for: upload) {
                    lastError = uploadError
                    continue
                }
                nextPhotos.append(GoodsCreatePhotoDraft(upload: upload))
            } catch {
                lastError = "写真を読み込めませんでした"
            }
        }

        if nextPhotos.isEmpty {
            createError = lastError ?? "写真を読み込めませんでした"
        } else {
            createPhotos.append(contentsOf: nextPhotos)
            if createStep == .meta {
                syncCreateMetasWithPhotos()
            }
            nextPhotos.forEach { photo in
                analyzeFaceTagsIfNeeded(upload: photo.upload, target: .createPhoto(photo.id))
            }
            createError = lastError
        }
        selectedCreatePhotoItems = []
    }

    private func loadSelectedTradingCardBulkPhoto(_ item: PhotosPickerItem?) async {
        guard let item else {
            return
        }

        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                createError = "写真を読み込めませんでした"
                selectedTradingCardBulkPhotoItem = nil
                return
            }
            await processTradingCardBulkImage(data)
        } catch {
            createError = "写真を読み込めませんでした"
        }
        selectedTradingCardBulkPhotoItem = nil
    }
    #endif

    private func processTradingCardBulkImage(_ data: Data) async {
        guard isTradingCardType else {
            createError = "トレカ種別を選択した時だけAI一括登録を使えます"
            return
        }

        createError = nil
        tradingCardBulkStatusMessage = nil
        isProcessingTradingCardBulk = true
        defer {
            isProcessingTradingCardBulk = false
        }

        do {
            let upload = normalizedPhotoUpload(from: data)
            if let uploadError = goodsEditorPhotoUploadError(for: upload) {
                createError = uploadError
                return
            }
            let frames = try await TradingCardBulkRecognizer.detectCropFrames(in: upload.data)
            cropSession = GoodsPhotoCropSession(
                source: .tradingCardBulk,
                upload: upload,
                initialFrames: frames
            )
            tradingCardBulkStatusMessage = frames.isEmpty
                ? "カード枠を検出できませんでした。写真上をドラッグして手動で切り取り枠を追加してください。"
                : "\(frames.count)件の候補を検出しました。黄色い枠を確認してから追加してください。"
        } catch {
            createError = error.localizedDescription
        }
    }

    private func save() async {
        lastSaveFailure = nil
        let saved: Bool
        switch draft.mode {
        case .create:
            guard let input = draft.createInput(
                groupName: selectedGroup?.name,
                memberName: selectedMember?.name,
                goodsTypeName: selectedGoodsType?.name
            ) else {
                return
            }
            saved = await appState.createGoodsEntry(input)
        case .edit:
            guard let itemID = draft.existingItemID,
                  let input = draft.updateInput(
                    groupName: selectedGroup?.name,
                    memberName: selectedMember?.name,
                    goodsTypeName: selectedGoodsType?.name
                  )
            else {
                return
            }
            saved = await appState.updateGoodsEntry(itemID: itemID, kind: draft.entryKind, input: input)
        case .readonly:
            return
        }
        if saved {
            dismiss()
        } else {
            lastSaveFailure = GoodsEditorSaveFailure.make(draft: draft, appMessage: appState.errorMessage)
        }
    }

    private func deleteInventoryItem() async {
        guard draft.entryKind == .inventory,
              draft.mode == .edit,
              let itemID = draft.existingItemID,
              !isItemReadOnly
        else {
            return
        }
        let deleted = await appState.archiveGoodsItem(itemID)
        if deleted {
            dismiss()
        } else {
            deleteErrorMessage = appState.errorMessage ?? "通信状況を確認してからもう一度お試しください。"
        }
    }

}
