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
    @Binding var metadataDraft: MeguriContentMetadataDraft
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
    var groups: [OshiGroup]
    var characters: [OshiCharacter]
    var userOshiSelections: [UserOshiSelection]
    var inventory: [GoodsItem]
    var wishes: [WishItem]
    var isLoadingGroups: Bool
    var isLoadingCharacters: Bool
    var onRemoveThumbnail: () -> Void
    var onLoadGroups: () async -> Void
    var onLoadCharacters: (OshiGroup?) async -> Void
    var onLoadUserOshiSelections: () async -> Void
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

                MeguriContentMetadataFields(
                    title: "トピックとシリーズ",
                    draft: $metadataDraft,
                    groups: groups,
                    characters: characters,
                    userOshiSelections: userOshiSelections,
                    inventory: inventory,
                    wishes: wishes,
                    isLoadingGroups: isLoadingGroups,
                    isLoadingCharacters: isLoadingCharacters,
                    onLoadGroups: onLoadGroups,
                    onLoadCharacters: onLoadCharacters,
                    onLoadUserOshiSelections: onLoadUserOshiSelections
                )

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
