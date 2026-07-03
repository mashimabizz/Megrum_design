import Foundation
import MegrumCore
import PhotosUI
import SwiftUI

@MainActor
struct MeguriScreenPresentationModifier: ViewModifier {
    @ObservedObject var appState: MegrumAppState
    @ObservedObject var locationState: MegrumLocationState
    @Binding var isShowingThreadComposer: Bool
    @Binding var threadCreationCoordinate: MegrumLocationCoordinate?
    @Binding var isShowingPrefecturePicker: Bool
    @Binding var selectedGroomPhotoItem: PhotosPickerItem?
    @Binding var groomCreationCoordinate: MegrumLocationCoordinate?
    var isGroomCreationLocationLocked: Bool
    @Binding var groomDraftPhotoData: Data?
    @Binding var groomDraftPhotoContentType: String
    var isPreparingGroomPhoto: Bool
    @Binding var isShowingGroomComposer: Bool
    @Binding var isShowingGroomCamera: Bool
    @Binding var isShowingGroomArchive: Bool
    @Binding var selectedGroom: GroomPost?
    @Binding var selectedGroomSourceAnchor: UnitPoint
    @Binding var activeMap: MeguriMapKind?
    var selectedPrefecture: String?
    var boardScope: BoardThread.Audience
    var canUseCamera: Bool
    var onThreadComposerDismiss: () -> Void
    var onThreadCreated: (BoardThread) -> Void
    var onSelectPrefecture: (String) -> Void
    var onRequestLocation: () -> Void
    var onOpenGroomCamera: () -> Void
    var onPrepareCapturedGroomPhoto: (Data) -> Void
    var onShowToast: (String) -> Void
    var onPublishGroomPhoto: (Data, String, String?, MegrumLocationCoordinate, MeguriContentMetadataDraft) async -> Bool
    var onResetGroomDraft: () -> Void
    var onOpenMeguriUserProfile: (UUID) -> Void

    func body(content: Content) -> some View {
        content
            .sheet(
                isPresented: $isShowingThreadComposer,
                onDismiss: onThreadComposerDismiss
            ) {
                NavigationStack {
                    BoardThreadComposerSheet(
                        appState: appState,
                        locationState: locationState,
                        fallbackCoordinate: locationState.coordinate,
                        initialCreationCoordinate: threadCreationCoordinate,
                        locksCreationCoordinate: threadCreationCoordinate != nil,
                        selectedPrefecture: selectedPrefecture,
                        onCreated: onThreadCreated
                    )
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $isShowingPrefecturePicker) {
                NavigationStack {
                    BoardPrefecturePickerSheet(
                        selectedPrefecture: selectedPrefecture,
                        onSelect: onSelectPrefecture
                    )
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .modifier(
                MeguriGroomComposerPresentationModifier(
                    selectedPhotoItem: $selectedGroomPhotoItem,
                    selectedCreationCoordinate: $groomCreationCoordinate,
                    draftPhotoData: $groomDraftPhotoData,
                    draftPhotoContentType: $groomDraftPhotoContentType,
                    isPreparingPhoto: isPreparingGroomPhoto,
                    isCreating: appState.isCreatingGroomPost,
                    canUseCamera: canUseCamera,
                    locksCreationCoordinate: isGroomCreationLocationLocked,
                    currentCoordinate: locationState.coordinate,
                    isRequestingLocation: locationState.isRequestingLocation,
                    isShowingGroomComposer: $isShowingGroomComposer,
                    isShowingGroomCamera: $isShowingGroomCamera,
                    isShowingGroomArchive: $isShowingGroomArchive,
                    appState: appState,
                    onRequestLocation: onRequestLocation,
                    onOpenCamera: onOpenGroomCamera,
                    onCapturePhoto: onPrepareCapturedGroomPhoto,
                    onCameraFailure: onShowToast,
                    onPublish: onPublishGroomPhoto,
                    onDiscard: onResetGroomDraft
                )
            )
            .modifier(
                GroomViewerPresentationModifier(
                    selectedGroom: $selectedGroom,
                    sourceAnchor: selectedGroomSourceAnchor,
                    grooms: appState.grooms,
                    appState: appState,
                    onOpenMeguriUserProfile: onOpenMeguriUserProfile
                )
            )
            .modifier(
                MeguriMapPresentationModifier(
                    activeMap: $activeMap,
                    appState: appState,
                    locationState: locationState,
                    selectedPrefecture: selectedPrefecture,
                    boardScope: boardScope
                )
            )
    }
}
