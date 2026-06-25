import MegrumDesign
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
    var currentCoordinate: MegrumLocationCoordinate?
    var isRequestingLocation: Bool
    var onRequestLocation: () -> Void
    var onOpenCamera: () -> Void
    var onPublish: (Data, String, String?, MegrumLocationCoordinate) async -> Bool
    var onDiscard: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var captionText = ""
    @State private var toastMessage: String?
    @State private var toastID = UUID()

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

            VStack(spacing: 0) {
                GroomStoryComposerHeader(
                    hasPhotoDraft: hasPhotoDraft,
                    onClose: closeComposer
                )

                ScrollView {
                    GroomStoryComposerStepContent(
                        selectedPhotoItem: $selectedPhotoItem,
                        selectedCreationCoordinate: $selectedCreationCoordinate,
                        captionText: $captionText,
                        draftPhotoData: draftPhotoData,
                        isPreparingPhoto: isPreparingPhoto,
                        isCreating: isCreating,
                        canUseCamera: canUseCamera,
                        cameraSubtitle: cameraSubtitle,
                        currentCoordinate: currentCoordinate,
                        isRequestingLocation: isRequestingLocation,
                        canCreateAtSelectedLocation: canCreateAtSelectedLocation,
                        onRequestLocation: onRequestLocation,
                        onOpenCamera: openCameraIfPossible,
                        onOutOfRange: showToast,
                        onPublish: publishDraftPhoto,
                        onResetPhotoDraft: resetPhotoDraft,
                        onPrepareFinalStep: seedSelectedCoordinateForFinalStepIfNeeded
                    )
                }

                Spacer()

                GroomStoryComposerPrivacyFooter()
            }

            GroomStoryComposerToastOverlay(message: toastMessage)
        }
        .onAppear(perform: seedSelectedCoordinateForFinalStepIfNeeded)
        .onChange(of: currentCoordinate) { _, _ in
            seedSelectedCoordinateForFinalStepIfNeeded()
        }
    }

    private var cameraSubtitle: String {
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
            let published = await onPublish(
                draftPhotoData,
                draftPhotoContentType,
                captionText.nilIfBlank,
                selectedCreationCoordinate
            )
            guard published else {
                return
            }
            onDiscard()
            dismiss()
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
        captionText = ""
    }

    private func closeComposer() {
        onDiscard()
        dismiss()
    }

    private func showToast(_ message: String) {
        let toastID = UUID()
        self.toastID = toastID
        withAnimation(.smooth(duration: 0.18)) {
            toastMessage = message
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.4))
            guard self.toastID == toastID else {
                return
            }
            withAnimation(.smooth(duration: 0.18)) {
                toastMessage = nil
            }
        }
    }
}
