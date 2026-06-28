import MegrumCore
import MegrumDesign
import PhotosUI
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct BoardThreadComposerContent: View {
    @Binding var title: String
    @Binding var bodyText: String
    @Binding var anonymousDisplayName: String
    @Binding var anonymousAvatarID: String
    @Binding var thumbnailItem: PhotosPickerItem?
    var missingContextMessage: String?
    var isShowingLocationStep: Bool
    var locksCreationCoordinate: Bool
    var hasThumbnail: Bool
    var currentCoordinate: MegrumLocationCoordinate?
    var isRequestingLocation: Bool
    @Binding var selectedCoordinate: MegrumLocationCoordinate?
    #if canImport(UIKit)
    var thumbnailPreviewImage: UIImage?
    #endif
    var onRemoveThumbnail: () -> Void
    var onRequestLocation: () -> Void
    var onOutOfRange: (String) -> Void
    var onLocationStepAppear: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                thumbnailSection

                BoardThreadAnonymousProfileSection(
                    displayName: $anonymousDisplayName,
                    selectedAvatarID: $anonymousAvatarID
                )

                BoardThreadTitleField(title: $title)

                BoardThreadBodyEditor(bodyText: $bodyText)

                if !locksCreationCoordinate, isShowingLocationStep {
                    locationStep
                }
            }
            .padding(20)
        }
    }

    private var thumbnailSection: some View {
        #if canImport(UIKit)
        BoardThreadThumbnailSection(
            thumbnailItem: $thumbnailItem,
            hasThumbnail: hasThumbnail,
            previewImage: thumbnailPreviewImage,
            onRemoveThumbnail: onRemoveThumbnail
        )
        #else
        BoardThreadThumbnailSection(
            thumbnailItem: $thumbnailItem,
            hasThumbnail: hasThumbnail,
            onRemoveThumbnail: onRemoveThumbnail
        )
        #endif
    }

    private var locationStep: some View {
        BoardThreadComposerLocationStep(
            title: title.nilIfBlank ?? "チャットルーム",
            summary: bodyText.nilIfBlank ?? "現地の話題",
            hasThumbnail: hasThumbnail,
            currentCoordinate: currentCoordinate,
            isRequestingLocation: isRequestingLocation,
            selectedCoordinate: $selectedCoordinate,
            onRequestLocation: onRequestLocation,
            onOutOfRange: onOutOfRange,
            onAppear: onLocationStepAppear
        )
    }
}

struct BoardThreadComposerPrimaryActionBar: View {
    var title: String
    var isCreating: Bool
    var isEnabled: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isCreating {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(title)
                }
            }
            .font(.system(size: 17, weight: .heavy, design: .rounded))
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(MegrumTheme.lavender, in: Capsule())
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(.regularMaterial)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.48)
    }
}
