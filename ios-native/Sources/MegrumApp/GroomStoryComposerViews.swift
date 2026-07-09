import MegrumDesign
import MegrumCore
import PhotosUI
import SwiftUI

struct GroomStoryComposerScreen: View {
    @Binding var selectedPhotoItem: PhotosPickerItem?
    @Binding var selectedCreationCoordinate: MegrumLocationCoordinate?
    @Binding var draftPhotoData: Data?
    @Binding var draftPhotoContentType: String
    var isPreparingPhoto: Bool
    var isCreating: Bool
    var canUseCamera: Bool
    var locksCreationCoordinate: Bool
    var currentCoordinate: MegrumLocationCoordinate?
    var isRequestingLocation: Bool
    var groups: [OshiGroup]
    var characters: [OshiCharacter]
    var userOshiSelections: [UserOshiSelection]
    var inventory: [GoodsItem]
    var wishes: [WishItem]
    var isLoadingGroups: Bool
    var isLoadingCharacters: Bool
    var onRequestLocation: () -> Void
    var onOpenCamera: () -> Void
    var onLoadGroups: () async -> Void
    var onLoadCharacters: (OshiGroup?) async -> Void
    var onLoadUserOshiSelections: () async -> Void
    var onPublish: (Data, String, String?, MegrumLocationCoordinate, MeguriContentMetadataDraft) async -> Bool
    /// FB(iter1226.399)：ホーム経由の「この場所にする」用。投稿はバックグラウンドで実行し、即ホームへ戻す。
    var onPublishInBackground: (Data, String, String?, MegrumLocationCoordinate, MeguriContentMetadataDraft) -> Void = { _, _, _, _, _ in }
    var onDiscard: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var presentationState = GroomStoryComposerPresentationState()
    @State private var metadataDraft = MeguriContentMetadataDraft()
    @State private var isShowingMetadataPrompt = false
    /// FB(iter1226.391)：ホーム等（場所未確定）からの投稿で最後に地図で場所を選ぶステップ。
    @State private var isShowingLocationStep = false

    private var hasPhotoDraft: Bool {
        draftPhotoData != nil
    }

    private var canCreateAtSelectedLocation: Bool {
        MeguriAccessPolicy.canCreateAt(
            selectedCreationCoordinate,
            currentCoordinate: effectiveCurrentCoordinate
        )
    }

    private var effectiveCurrentCoordinate: MegrumLocationCoordinate? {
        currentCoordinate ?? (locksCreationCoordinate ? selectedCreationCoordinate : nil)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let draftPhotoData {
                GroomStoryEditorView(
                    photoData: draftPhotoData,
                    textOverlays: $presentationState.textOverlays,
                    isCreating: isCreating,
                    onClose: returnToPhotoSelection,
                    onPublish: beginPublishFlow
                )
            } else {
                VStack(spacing: 0) {
                    GroomStoryComposerHeader(
                        hasPhotoDraft: hasPhotoDraft,
                        onClose: closeComposer
                    )

                    ScrollView {
                        GroomStoryPhotoSelectionStep(
                            selectedPhotoItem: $selectedPhotoItem,
                            isPreparingPhoto: isPreparingPhoto,
                            isCreating: isCreating,
                            canUseCamera: canUseCamera,
                            cameraSubtitle: cameraSubtitle,
                            locksCreationCoordinate: locksCreationCoordinate,
                            onOpenCamera: openCameraIfPossible,
                            onSelectPhotoData: prepareLibraryGroomPhoto
                        )
                    }

                    Spacer()

                    GroomStoryComposerPrivacyFooter()
                }
            }

            if isShowingLocationStep {
                GroomStoryLocationStepView(
                    photoData: draftPhotoData,
                    caption: presentationState.captionForPublish,
                    selectedCoordinate: $selectedCreationCoordinate,
                    currentCoordinate: currentCoordinate,
                    isRequestingLocation: isRequestingLocation,
                    canConfirm: canCreateAtSelectedLocation,
                    onRequestLocation: onRequestLocation,
                    onOutOfRange: { showToast($0) },
                    onCancel: {
                        withAnimation(.smooth(duration: 0.2)) {
                            isShowingLocationStep = false
                        }
                    },
                    onConfirm: publishDraftPhotoInBackground
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(2)
            }

            GroomStoryComposerToastOverlay(message: presentationState.toastMessage)

            if isShowingMetadataPrompt {
                Color.black.opacity(0.54)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation(.smooth(duration: 0.18)) {
                            isShowingMetadataPrompt = false
                        }
                    }

                MeguriContentMetadataPrompt(
                    title: "トピックとシリーズを設定",
                    draft: $metadataDraft,
                    groups: groups,
                    characters: characters,
                    userOshiSelections: userOshiSelections,
                    inventory: inventory,
                    wishes: wishes,
                    isLoadingGroups: isLoadingGroups,
                    isLoadingCharacters: isLoadingCharacters,
                    isSubmitting: isCreating,
                    onLoadGroups: onLoadGroups,
                    onLoadCharacters: onLoadCharacters,
                    onLoadUserOshiSelections: onLoadUserOshiSelections,
                    onCancel: {
                        withAnimation(.smooth(duration: 0.18)) {
                            isShowingMetadataPrompt = false
                        }
                    },
                    onSubmit: proceedAfterMetadata
                )
                .transition(.scale(scale: 0.96).combined(with: .opacity))
            }
        }
        .onAppear(perform: seedSelectedCoordinateForFinalStepIfNeeded)
        .onChange(of: currentCoordinate) { _, _ in
            seedSelectedCoordinateForFinalStepIfNeeded()
        }
        .onChange(of: draftPhotoData) { _, _ in
            seedSelectedCoordinateForFinalStepIfNeeded()
        }
    }

    private var cameraSubtitle: String {
        if locksCreationCoordinate {
            return "写真が決まったら投稿へ"
        }
        if !canUseCamera {
            return "この端末では利用不可"
        }
        return "写真が決まったら場所選択へ"
    }

    private func openCameraIfPossible() {
        guard canUseCamera else {
            showToast("この端末ではカメラを利用できません。写真から選択してください。")
            return
        }
        onOpenCamera()
    }

    /// 写真編集の「投稿」から呼ばれる。まずトピック/シリーズのポップアップを出す（場所は次のステップ）。
    private func beginPublishFlow() {
        presentMetadataPrompt()
    }

    private func presentMetadataPrompt() {
        guard draftPhotoData != nil else {
            showToast("投稿する写真を選択してください")
            return
        }
        withAnimation(.smooth(duration: 0.18)) {
            isShowingMetadataPrompt = true
        }
        Task {
            if groups.isEmpty {
                await onLoadGroups()
            }
            if let group = groups.first(where: { $0.id == metadataDraft.groupID }) {
                await onLoadCharacters(group)
            }
        }
    }

    /// トピック/シリーズ確定後：めぐり地図経由（場所確定済み）はそのまま投稿、ホーム等は地図で場所を選ぶ。
    private func proceedAfterMetadata() {
        withAnimation(.smooth(duration: 0.18)) {
            isShowingMetadataPrompt = false
        }
        if locksCreationCoordinate {
            publishDraftPhoto()
            return
        }
        if currentCoordinate == nil {
            onRequestLocation()
        }
        if selectedCreationCoordinate == nil {
            selectedCreationCoordinate = currentCoordinate
        }
        withAnimation(.smooth(duration: 0.2)) {
            isShowingLocationStep = true
        }
    }

    private func publishDraftPhoto() {
        guard !isCreating else {
            return
        }
        guard let draftPhotoData else {
            showToast("投稿する写真を選択してください")
            return
        }
        guard let selectedCreationCoordinate else {
            if currentCoordinate == nil {
                onRequestLocation()
            }
            showToast("最後に地図上でピンを立ててください")
            return
        }
        if currentCoordinate == nil {
            onRequestLocation()
        }
        guard canCreateAtSelectedLocation else {
            showToast(
                MeguriAccessPolicy.creationLocationMessage(
                    selectedCoordinate: selectedCreationCoordinate,
                    currentCoordinate: effectiveCurrentCoordinate
                )
            )
            return
        }
        Task {
            let photoUpload = renderedGroomPhotoUpload(from: draftPhotoData)
            guard let photoUpload else {
                showToast("編集した写真を作成できませんでした")
                return
            }
            let published = await onPublish(
                photoUpload.data,
                photoUpload.contentType,
                presentationState.captionForPublish,
                selectedCreationCoordinate,
                metadataDraft
            )
            guard published else {
                showToast("グルームを投稿できませんでした")
                return
            }
            isShowingMetadataPrompt = false
            onDiscard()
            dismiss()
        }
    }

    /// FB(iter1226.399)：ホーム経由の「この場所にする」。写真を書き出したら即コンポーザを閉じてホームへ戻り、
    /// 実際の投稿はコンテナ側のバックグラウンドタスクに委ねる（自分アイコンの枠活性化アニメが見えるようにする）。
    private func publishDraftPhotoInBackground() {
        guard let draftPhotoData else {
            showToast("投稿する写真を選択してください")
            return
        }
        guard let selectedCreationCoordinate else {
            if currentCoordinate == nil {
                onRequestLocation()
            }
            showToast("最後に地図上でピンを立ててください")
            return
        }
        if currentCoordinate == nil {
            onRequestLocation()
        }
        guard canCreateAtSelectedLocation else {
            showToast(
                MeguriAccessPolicy.creationLocationMessage(
                    selectedCoordinate: selectedCreationCoordinate,
                    currentCoordinate: effectiveCurrentCoordinate
                )
            )
            return
        }
        guard let photoUpload = renderedGroomPhotoUpload(from: draftPhotoData) else {
            showToast("編集した写真を作成できませんでした")
            return
        }
        onPublishInBackground(
            photoUpload.data,
            photoUpload.contentType,
            presentationState.captionForPublish,
            selectedCreationCoordinate,
            metadataDraft
        )
        isShowingLocationStep = false
        isShowingMetadataPrompt = false
        onDiscard()
        dismiss()
    }

    @MainActor
    private func renderedGroomPhotoUpload(from draftPhotoData: Data) -> GoodsPhotoUpload? {
        do {
            let renderedData = try GroomStoryExportRenderer.renderedJPEGData(
                photoData: draftPhotoData,
                textOverlays: presentationState.textOverlays
            )
            return normalizedPhotoUpload(from: renderedData)
        } catch {
            return nil
        }
    }

    private func prepareLibraryGroomPhoto(_ data: Data, _ contentType: String) {
        let upload = normalizedPhotoUpload(from: data)
        draftPhotoData = upload.data
        draftPhotoContentType = upload.contentType.nilIfBlank ?? contentType
        if selectedCreationCoordinate == nil {
            selectedCreationCoordinate = currentCoordinate
        }
    }

    private func seedSelectedCoordinateForFinalStepIfNeeded() {
        guard hasPhotoDraft else {
            return
        }
        guard selectedCreationCoordinate == nil else {
            return
        }
        selectedCreationCoordinate = currentCoordinate
    }

    private func resetPhotoDraft() {
        draftPhotoData = nil
        draftPhotoContentType = "image/jpeg"
        selectedPhotoItem = nil
        selectedCreationCoordinate = nil
        metadataDraft = MeguriContentMetadataDraft()
        isShowingMetadataPrompt = false
        presentationState.clearCaptionAfterPhotoReset()
    }

    private func returnToPhotoSelection() {
        draftPhotoData = nil
        draftPhotoContentType = "image/jpeg"
        selectedPhotoItem = nil
        metadataDraft = MeguriContentMetadataDraft()
        isShowingMetadataPrompt = false
        presentationState.clearCaptionAfterPhotoReset()
    }

    private func closeComposer() {
        onDiscard()
        dismiss()
    }

    private func showToast(_ message: String) {
        let toastID = UUID()
        withAnimation(.smooth(duration: 0.18)) {
            presentationState.showToast(message, toastID: toastID)
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.4))
            withAnimation(.smooth(duration: 0.18)) {
                presentationState.clearToast(ifMatching: toastID)
            }
        }
    }
}
