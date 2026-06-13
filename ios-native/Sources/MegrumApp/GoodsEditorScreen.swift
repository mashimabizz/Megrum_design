import MegrumCore
import MegrumDesign
#if canImport(PhotosUI)
import PhotosUI
#endif
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

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
        if draft.mode == .edit {
            return draft.entryKind == .inventory ? "マイグッズを編集" : "Wishを編集"
        }
        return draft.entryKind == .inventory ? "マイグッズに追加" : "Wishに追加"
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
        return appState.oshiCharacters.first { $0.id == memberID }
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

    private var photoSourceDialogTitle: String {
        draft.hasDisplayPhoto ? "写真を差し替え" : "写真を追加"
    }

    private var photoActionTitle: String {
        if draft.entryKind == .wish {
            return draft.hasDisplayPhoto ? "差し替え" : "+ 画像を選択"
        }
        return draft.hasDisplayPhoto ? "撮り直す / 差し替え" : "写真を追加"
    }

    private var wishImageHint: String {
        draft.hasDisplayPhoto ? "1枚登録済" : "任意"
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
            members: appState.oshiCharacters,
            isLoadingOshiCharacters: appState.isLoadingOshiCharacters,
            goodsTypes: appState.goodsTypes,
            isLoadingGoodsTypes: appState.isLoadingGoodsTypes,
            selectedGroupName: selectedGroup?.name,
            selectedGoodsTypeName: selectedGoodsType?.name,
            createError: createError,
            canAdvanceFromCreateCommon: canAdvanceFromCreateCommon,
            isTradingCardType: isTradingCardType,
            isProcessingTradingCardBulk: isProcessingTradingCardBulk,
            tradingCardBulkStatusMessage: tradingCardBulkStatusMessage,
            canSaveInventoryCreateMetas: canSaveInventoryCreateMetas,
            isCreatingGoodsEntry: appState.isCreatingGoodsEntry,
            photoError: photoError,
            photoActionTitle: photoActionTitle,
            titlePreview: resolvedTitlePreview,
            wishImageHint: wishImageHint,
            isWishPhotoRemovalLocked: isWishPhotoRemovalLocked,
            onRemoveTag: removeTag,
            onAddTag: addCurrentTag,
            onCommonNext: goToCreateShoot,
            onPickCamera: startInventoryCreateCamera,
            onPickPhotos: showInventoryCreatePhotoLibrary,
            onStartTradingCardBulk: showTradingCardBulkSourceDialog,
            onRemovePhoto: removeCreatePhoto,
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
        if usesInventoryCreateFlow {
            return "推し・種別、写真、写真ごとの詳細の順に登録できます。"
        }
        if draft.entryKind == .inventory {
            return "写真、推し、数量、タグを編集できます。"
        }
        return "推し、数量、画像、タグを編集できます。"
    }

    private var saveButtonTitle: String {
        if draft.mode == .edit {
            if appState.mutatingGoodsItemID == draft.existingItemID {
                return "更新しています"
            }
            return draft.entryKind == .wish ? "ウィッシュを更新" : "変更を保存"
        }
        if appState.isCreatingGoodsEntry {
            return "保存しています"
        }
        return draft.entryKind == .inventory ? "マイグッズを登録" : "Wishを登録"
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

    private func memberName(for memberID: UUID?) -> String? {
        guard let memberID else {
            return nil
        }
        return appState.oshiCharacters.first { $0.id == memberID }?.name
    }

    private func photoUpload(for photoID: UUID?) -> GoodsPhotoUpload? {
        guard let photoID else {
            return nil
        }
        return createPhotos.first { $0.id == photoID }?.upload
    }

    private func inventoryCreateInputs() -> [GoodsEntryInput] {
        createMetas.compactMap { meta in
            meta.createInput(
                sharedDraft: draft,
                photoUpload: photoUpload(for: meta.photoID),
                groupName: selectedGroup?.name,
                memberName: memberName(for: meta.memberID),
                goodsTypeName: selectedGoodsType?.name
            )
        }
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
        if appState.oshiGroups.isEmpty {
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
        if draft.groupID == nil {
            draft.groupID = appState.oshiGroups.first?.id
        }
        if draft.goodsTypeID == nil {
            draft.goodsTypeID = appState.goodsTypes.first?.id
        }
        didAssignDefaults = draft.groupID != nil && draft.goodsTypeID != nil
    }

    private func loadMembers(for groupID: UUID?) async {
        guard let groupID,
              let group = appState.oshiGroups.first(where: { $0.id == groupID })
        else {
            draft.memberID = nil
            return
        }
        await appState.loadOshiCharacters(group: group)
        if let memberID = draft.memberID,
           !appState.oshiCharacters.contains(where: { $0.id == memberID }) {
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
            createPhotos.append(GoodsCreatePhotoDraft(upload: upload))
            if createStep == .meta {
                syncCreateMetasWithPhotos()
            }
            createError = nil
            photoError = nil
            return
        }
        draft.setLocalPhotoUpload(upload)
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
            let results = try await TradingCardBulkRecognizer.recognizeCards(in: data)
            appendTradingCardBulkResults(results)
        } catch {
            createError = error.localizedDescription
        }
    }

    private func appendTradingCardBulkResults(_ results: [TradingCardBulkRecognitionResult]) {
        var nextPhotos: [GoodsCreatePhotoDraft] = []
        var lastError: String?

        for result in results {
            let upload = result.upload
            if let uploadError = goodsEditorPhotoUploadError(for: upload) {
                lastError = uploadError
                continue
            }
            nextPhotos.append(GoodsCreatePhotoDraft(upload: upload))
        }

        guard !nextPhotos.isEmpty else {
            createError = lastError ?? "AIで追加できるカード画像がありませんでした"
            return
        }

        createPhotos.append(contentsOf: nextPhotos)
        if createStep == .meta {
            syncCreateMetasWithPhotos()
        }

        let usedFallback = results.contains { $0.source == .fallbackOriginal }
        tradingCardBulkStatusMessage = usedFallback
            ? "カード枠を検出できなかったため、元写真を1枚追加しました。必要なら撮り直すか、写真一覧から削除してください。"
            : "\(nextPhotos.count)枚のカードを切り出して追加しました。続けて追加するか、詳細設定へ進めます。"
        createError = lastError
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
