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
    var onRequestLocation: () -> Void
    var onOpenCamera: () -> Void
    var onPublish: (Data, String, String?, MegrumLocationCoordinate) async -> Bool
    var onDiscard: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var presentationState = GroomStoryComposerPresentationState()

    private var hasPhotoDraft: Bool {
        draftPhotoData != nil
    }

    private var canCreateAtSelectedLocation: Bool {
        MeguriAccessPolicy.canCreateAt(
            selectedCreationCoordinate,
            currentCoordinate: currentCoordinate
        )
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let draftPhotoData {
                GroomStoryEditorView(
                    photoData: draftPhotoData,
                    textOverlays: $presentationState.textOverlays,
                    isCreating: isCreating,
                    onClose: closeComposer,
                    onPublish: publishDraftPhoto
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

            GroomStoryComposerToastOverlay(message: presentationState.toastMessage)
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

    private func publishDraftPhoto() {
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
                    currentCoordinate: currentCoordinate
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
                selectedCreationCoordinate
            )
            guard published else {
                return
            }
            onDiscard()
            dismiss()
        }
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
