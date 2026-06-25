import Foundation
import MegrumCore
import PhotosUI
import SwiftUI

@MainActor
struct MeguriScreenPresentationModifier: ViewModifier {
    @ObservedObject var appState: MegrumAppState
    @ObservedObject var locationState: MegrumLocationState
    @Binding var selectedThread: BoardThread?
    @Binding var isShowingThreadComposer: Bool
    @Binding var isShowingPrefecturePicker: Bool
    @Binding var selectedGroomPhotoItem: PhotosPickerItem?
    @Binding var groomCreationCoordinate: MegrumLocationCoordinate?
    @Binding var groomDraftPhotoData: Data?
    @Binding var groomDraftPhotoContentType: String
    var isPreparingGroomPhoto: Bool
    @Binding var isShowingGroomComposer: Bool
    @Binding var isShowingGroomCamera: Bool
    @Binding var isShowingGroomArchive: Bool
    @Binding var selectedGroom: GroomPost?
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
    var onPublishGroomPhoto: (Data, String, String?, MegrumLocationCoordinate) async -> Bool
    var onResetGroomDraft: () -> Void

    func body(content: Content) -> some View {
        content
            .sheet(item: $selectedThread) { thread in
                NavigationStack {
                    BoardThreadDetailScreen(
                        appState: appState,
                        thread: thread,
                        selectedPrefecture: selectedPrefecture,
                        coordinate: locationState.coordinate
                    )
                }
            }
            .sheet(
                isPresented: $isShowingThreadComposer,
                onDismiss: onThreadComposerDismiss
            ) {
                NavigationStack {
                    BoardThreadComposerSheet(
                        appState: appState,
                        locationState: locationState,
                        fallbackCoordinate: locationState.coordinate,
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
                    grooms: appState.grooms,
                    appState: appState
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
