import Foundation
import PhotosUI
import SwiftUI

struct GroomStoryComposerHeader: View {
    var hasPhotoDraft: Bool
    var onClose: () -> Void

    var body: some View {
        HStack {
            Button("閉じる", systemImage: "xmark", action: onClose)
                .labelStyle(.iconOnly)
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .buttonStyle(.plain)

            Spacer()

            Text("グルームに追加")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

            Color.clear
                .frame(width: 48, height: 48)
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
    }
}

struct GroomStoryComposerStepContent: View {
    @Binding var selectedPhotoItem: PhotosPickerItem?
    @Binding var selectedCreationCoordinate: MegrumLocationCoordinate?
    @Binding var captionText: String
    var draftPhotoData: Data?
    var isPreparingPhoto: Bool
    var isCreating: Bool
    var canUseCamera: Bool
    var cameraSubtitle: String
    var locksCreationCoordinate: Bool
    var currentCoordinate: MegrumLocationCoordinate?
    var isRequestingLocation: Bool
    var canCreateAtSelectedLocation: Bool
    var onRequestLocation: () -> Void
    var onOpenCamera: () -> Void
    var onOutOfRange: (String) -> Void
    var onSelectPhotoData: (Data, String) -> Void
    var onPublish: () -> Void
    var onResetPhotoDraft: () -> Void
    var onPrepareFinalStep: () -> Void

    var body: some View {
        if let draftPhotoData {
            GroomStoryFinalLocationStep(
                photoData: draftPhotoData,
                captionText: $captionText,
                selectedCreationCoordinate: $selectedCreationCoordinate,
                currentCoordinate: currentCoordinate,
                isRequestingLocation: isRequestingLocation,
                isCreating: isCreating,
                locksCreationCoordinate: locksCreationCoordinate,
                canCreateAtSelectedLocation: canCreateAtSelectedLocation,
                onRequestLocation: onRequestLocation,
                onOutOfRange: onOutOfRange,
                onPublish: onPublish,
                onResetPhotoDraft: onResetPhotoDraft
            )
            .onAppear(perform: onPrepareFinalStep)
        } else {
            GroomStoryPhotoSelectionStep(
                selectedPhotoItem: $selectedPhotoItem,
                isPreparingPhoto: isPreparingPhoto,
                isCreating: isCreating,
                canUseCamera: canUseCamera,
                cameraSubtitle: cameraSubtitle,
                locksCreationCoordinate: locksCreationCoordinate,
                onOpenCamera: onOpenCamera,
                onSelectPhotoData: onSelectPhotoData
            )
        }
    }
}

struct GroomStoryComposerPrivacyFooter: View {
    var body: some View {
        Text("投稿したグルームは近くの人にだけ表示されます。正確な位置は表示しません。")
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(.white.opacity(0.62))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 34)
            .padding(.bottom, 24)
    }
}

struct GroomStoryComposerToastOverlay: View {
    var message: String?

    var body: some View {
        if let message {
            VStack {
                Spacer()

                MeguriToastView(message: message)
                    .padding(.bottom, 92)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}
