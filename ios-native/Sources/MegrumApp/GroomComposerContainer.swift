import MegrumCore
import PhotosUI
import SwiftUI

/// ホームなど、めぐりタブ外からグルーム投稿コンポーザをその場で開くための自己完結ホスト。iter1226.387 / FB8-6。
/// めぐり画面の状態機械には手を入れず、下書き状態＋投稿処理をここに閉じ込める（回帰リスクを避ける）。
@MainActor
struct GroomComposerContainer<Content: View>: View {
    @ObservedObject var appState: MegrumAppState
    @ObservedObject var locationState: MegrumLocationState
    @Binding var isPresented: Bool
    @ViewBuilder var content: () -> Content

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var draftPhotoData: Data?
    @State private var draftPhotoContentType = "image/jpeg"
    @State private var creationCoordinate: MegrumLocationCoordinate?
    @State private var isPreparingPhoto = false
    @State private var isCreating = false
    @State private var isShowingCamera = false

    var body: some View {
        content()
            .modifier(
                MeguriGroomComposerPresentationModifier(
                    selectedPhotoItem: $selectedPhotoItem,
                    selectedCreationCoordinate: $creationCoordinate,
                    draftPhotoData: $draftPhotoData,
                    draftPhotoContentType: $draftPhotoContentType,
                    isPreparingPhoto: isPreparingPhoto,
                    isCreating: isCreating,
                    canUseCamera: true,
                    locksCreationCoordinate: false,
                    currentCoordinate: locationState.coordinate,
                    isRequestingLocation: locationState.isRequestingLocation,
                    isShowingGroomComposer: $isPresented,
                    isShowingGroomCamera: $isShowingCamera,
                    isShowingGroomArchive: .constant(false),
                    appState: appState,
                    onRequestLocation: { locationState.startUpdatingCurrentLocation() },
                    onOpenCamera: { isShowingCamera = true },
                    onCapturePhoto: handleCapturedPhoto,
                    onCameraFailure: { _ in },
                    onPublish: publish,
                    onDiscard: {
                        resetDraft()
                        isPresented = false
                    }
                )
            )
            .onChange(of: selectedPhotoItem) { _, item in
                guard let item else {
                    return
                }
                Task { await preparePhoto(item) }
            }
            .onChange(of: isPresented) { _, presented in
                if presented {
                    if creationCoordinate == nil {
                        creationCoordinate = locationState.coordinate
                    }
                    if locationState.coordinate == nil {
                        locationState.startUpdatingCurrentLocation()
                    }
                } else {
                    resetDraft()
                }
            }
    }

    private func preparePhoto(_ item: PhotosPickerItem) async {
        isPreparingPhoto = true
        defer {
            selectedPhotoItem = nil
            isPreparingPhoto = false
        }
        guard let data = try? await item.loadTransferable(type: Data.self) else {
            return
        }
        let upload = normalizedPhotoUpload(from: data)
        draftPhotoData = upload.data
        draftPhotoContentType = upload.contentType
        if creationCoordinate == nil {
            creationCoordinate = locationState.coordinate
        }
    }

    private func handleCapturedPhoto(_ data: Data) {
        draftPhotoData = data
        draftPhotoContentType = "image/jpeg"
        if creationCoordinate == nil {
            creationCoordinate = locationState.coordinate
        }
        isShowingCamera = false
        isPresented = true
    }

    private func publish(
        data: Data,
        imageContentType: String,
        caption: String?,
        coordinate: MegrumLocationCoordinate,
        metadata: MeguriContentMetadataDraft
    ) async -> Bool {
        isCreating = true
        defer { isCreating = false }

        guard MeguriAccessPolicy.canCreateAt(coordinate, currentCoordinate: locationState.coordinate) else {
            if locationState.coordinate == nil {
                locationState.startUpdatingCurrentLocation()
            }
            return false
        }

        let created = await appState.createGroomPost(
            imageData: data,
            imageContentType: imageContentType,
            caption: caption,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            groupID: metadata.groupID,
            characterID: metadata.characterID,
            seriesName: metadata.normalizedSeriesName
        )
        if created {
            await appState.loadGroomMapPosts(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                force: true
            )
            resetDraft()
            return true
        }
        return false
    }

    private func resetDraft() {
        selectedPhotoItem = nil
        draftPhotoData = nil
        draftPhotoContentType = "image/jpeg"
        creationCoordinate = nil
        isPreparingPhoto = false
    }
}
