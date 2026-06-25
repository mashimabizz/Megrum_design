import MegrumDesign
import PhotosUI
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct GroomStoryPhotoSelectionStep: View {
    @Binding var selectedPhotoItem: PhotosPickerItem?
    var isPreparingPhoto: Bool
    var isCreating: Bool
    var canUseCamera: Bool
    var cameraSubtitle: String
    var onOpenCamera: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            GroomStoryComposerStepHeader(
                title: "先に写真を決める",
                subtitle: "撮影・選択した写真を確認してから、最後に地図上の表示位置を決めます。"
            )

            GroomStoryPhotoActionGrid(
                selectedPhotoItem: $selectedPhotoItem,
                isPreparingPhoto: isPreparingPhoto,
                isCreating: isCreating,
                canUseCamera: canUseCamera,
                cameraSubtitle: cameraSubtitle,
                onOpenCamera: onOpenCamera
            )
        }
        .padding(.horizontal, 24)
        .padding(.top, 28)
    }
}

struct GroomStoryFinalLocationStep: View {
    var photoData: Data
    @Binding var captionText: String
    @Binding var selectedCreationCoordinate: MegrumLocationCoordinate?
    var currentCoordinate: MegrumLocationCoordinate?
    var isRequestingLocation: Bool
    var isCreating: Bool
    var canCreateAtSelectedLocation: Bool
    var onRequestLocation: () -> Void
    var onOutOfRange: (String) -> Void
    var onPublish: () -> Void
    var onResetPhotoDraft: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            GroomStoryComposerStepHeader(
                title: "最後に置く場所を決める",
                subtitle: "この写真が地図上に表示される見え方を確認しながら、半径1km以内にピンを立ててください。"
            )

            GroomDraftPhotoPreview(photoData: photoData, caption: captionText.nilIfBlank)

            GroomStoryCaptionField(captionText: $captionText)

            MeguriCreationLocationPicker(
                title: "地図での表示プレビュー",
                subtitle: "現在地から半径1km以内の地図上をタップして選択",
                currentCoordinate: currentCoordinate,
                isRequestingLocation: isRequestingLocation,
                preview: .groom(imageData: photoData, caption: captionText.nilIfBlank),
                selectedCoordinate: $selectedCreationCoordinate,
                onRequestLocation: onRequestLocation,
                onOutOfRange: onOutOfRange
            )
            .padding(14)
            .background(.white.opacity(0.96), in: RoundedRectangle(cornerRadius: 26, style: .continuous))

            GroomStoryPublishButton(
                isCreating: isCreating,
                canCreateAtSelectedLocation: canCreateAtSelectedLocation,
                onPublish: onPublish
            )

            GroomStoryResetPhotoButton(onReset: onResetPhotoDraft)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
}
