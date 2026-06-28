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
    var locksCreationCoordinate: Bool
    var onOpenCamera: () -> Void
    var onSelectPhotoData: (Data, String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroomStoryPhotoActionGrid(
                selectedPhotoItem: $selectedPhotoItem,
                isPreparingPhoto: isPreparingPhoto,
                isCreating: isCreating,
                canUseCamera: canUseCamera,
                cameraSubtitle: cameraSubtitle,
                onOpenCamera: onOpenCamera,
                onSelectPhotoData: onSelectPhotoData
            )
        }
        .padding(.horizontal, 24)
        .padding(.top, 18)
    }
}

struct GroomStoryFinalLocationStep: View {
    var photoData: Data
    @Binding var captionText: String
    @Binding var selectedCreationCoordinate: MegrumLocationCoordinate?
    var currentCoordinate: MegrumLocationCoordinate?
    var isRequestingLocation: Bool
    var isCreating: Bool
    var locksCreationCoordinate: Bool
    var canCreateAtSelectedLocation: Bool
    var onRequestLocation: () -> Void
    var onOutOfRange: (String) -> Void
    var onPublish: () -> Void
    var onResetPhotoDraft: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            GroomStoryComposerStepHeader(
                title: locksCreationCoordinate ? "写真を確認する" : "最後に置く場所を決める",
                subtitle: locksCreationCoordinate
                    ? "地図で選んだ場所にグルームを投稿します。"
                    : "この写真が地図上に表示される見え方を確認しながら、半径1km以内にピンを立ててください。"
            )

            GroomDraftPhotoPreview(photoData: photoData, caption: captionText.nilIfBlank)

            GroomStoryCaptionField(captionText: $captionText)

            if locksCreationCoordinate {
                MeguriNoticeBanner(message: "地図で選択した場所に作成します。位置を変えたい場合は一度閉じて地図をタップし直してください。")
                    .padding(14)
                    .background(.white.opacity(0.96), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            } else {
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
            }

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
