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
    var onCreatedInventoryItems: ([GoodsItem]) -> Void

    enum PhotoCaptureTarget {
        case draft
        case inventoryCreate
        case tradingCardBulk
    }

    enum SeriesSuggestionTarget {
        case draft
        case selectedCreateMetas
    }

    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    @State var draft: GoodsEditorDraft
    @State var tagDraft = ""
    @State var photoError: String?
    @State var lastSaveFailure: GoodsEditorSaveFailure?
    @State var createStep: GoodsCreateStep = .common
    @State var createPhotos: [GoodsCreatePhotoDraft] = []
    @State var createMetas: [GoodsCreateMetaDraft] = [GoodsCreateMetaDraft()]
    @State var selectedCreateMetaIDs: Set<UUID> = []
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
    @State var isShowingCreateBulkTagSelectionSheet = false
    @State var isConfirmingInventoryCreateWithoutTags = false
    @State var isOpeningGoogleLensSearch = false
    @State var googleLensSearchErrorMessage: String?
    @FocusState var isTagFieldFocused: Bool
    #if canImport(PhotosUI)
    @State var selectedPhotoItem: PhotosPickerItem?
    @State var selectedCreatePhotoItems: [PhotosPickerItem] = []
    @State var selectedTradingCardBulkPhotoItem: PhotosPickerItem?
    #endif

    init(
        appState: MegrumAppState,
        route: GoodsEditorRoute,
        onCreatedInventoryItems: @escaping ([GoodsItem]) -> Void = { _ in }
    ) {
        self.appState = appState
        self.route = route
        self.onCreatedInventoryItems = onCreatedInventoryItems
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
            onConfirmDelete: requestInventoryDeleteConfirmation,
            fixedFooter: fixedInventoryCreateFooter
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
                    navigationTitle: "シリーズを登録",
                    textFieldPlaceholder: "例：会場限定",
                    footerText: "このWishにシリーズを追加します。",
                    confirmationTitle: "追加",
                    googleLensItems: draftGoogleLensItems,
                    isOpeningGoogleLens: isOpeningGoogleLensSearch,
                    googleLensErrorMessage: googleLensSearchErrorMessage,
                    onOpenGoogleLens: openDraftGoogleLensSearch,
                    onApply: addTagFromSelectionSheet
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $isShowingCreateBulkTagSelectionSheet) {
                GoodsBulkTagSheet(
                    selectedCount: selectedCreateMetaIDs.count,
                    candidateNames: createBulkTagSuggestions,
                    previewItemsByTag: editorTagPreviewItemsByTag,
                    navigationTitle: "シリーズを一括登録",
                    textFieldPlaceholder: "例：会場限定",
                    footerText: "\(selectedCreateMetaIDs.count)件の画像に同じシリーズを追加します。",
                    confirmationTitle: "登録",
                    googleLensItems: selectedCreateMetaGoogleLensItems,
                    isOpeningGoogleLens: isOpeningGoogleLensSearch,
                    googleLensErrorMessage: googleLensSearchErrorMessage,
                    onOpenGoogleLens: openSelectedCreateMetaGoogleLensSearch,
                    onApply: applyCreateBulkTag
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .alert(
                "シリーズ未設定の画像があります",
                isPresented: $isConfirmingInventoryCreateWithoutTags
            ) {
                Button("シリーズを設定する", role: .cancel) {}
                Button("このまま登録") {
                    Task {
                        await saveInventoryCreateFlow()
                    }
                }
            } message: {
                Text("シリーズを登録していないと、検索やマッチ候補で見つかりにくくなる可能性があります。なるべくシリーズを登録してください。")
            }
            .goodsEditorTradingCardBulkSourceDialog(
                isPresented: $isShowingTradingCardBulkSourceDialog,
                onPickCamera: startTradingCardBulkCamera,
                onPickPhotoLibrary: showTradingCardBulkPhotoLibrary
            )
    }
}
