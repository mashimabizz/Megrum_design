import Foundation
import MegrumCore
import PhotosUI
import SwiftUI

@MainActor
struct MeguriGroomComposerPresentationModifier: ViewModifier {
    @Binding var selectedPhotoItem: PhotosPickerItem?
    @Binding var selectedCreationCoordinate: MegrumLocationCoordinate?
    @Binding var draftPhotoData: Data?
    @Binding var draftPhotoContentType: String
    var isPreparingPhoto: Bool
    var isCreating: Bool
    var canUseCamera: Bool
    var currentCoordinate: MegrumLocationCoordinate?
    var isRequestingLocation: Bool
    @Binding var isShowingGroomComposer: Bool
    @Binding var isShowingGroomCamera: Bool
    @Binding var isShowingGroomArchive: Bool
    @ObservedObject var appState: MegrumAppState
    var onRequestLocation: () -> Void
    var onOpenCamera: () -> Void
    var onCapturePhoto: (Data) -> Void
    var onCameraFailure: (String) -> Void
    var onPublish: (Data, String, String?, MegrumLocationCoordinate) async -> Bool
    var onDiscard: () -> Void

    func body(content: Content) -> some View {
        content
            .groomComposerPresentation(
                isPresented: $isShowingGroomComposer,
                selectedPhotoItem: $selectedPhotoItem,
                selectedCreationCoordinate: $selectedCreationCoordinate,
                draftPhotoData: $draftPhotoData,
                draftPhotoContentType: $draftPhotoContentType,
                isPreparingPhoto: isPreparingPhoto,
                isCreating: isCreating,
                canUseCamera: canUseCamera,
                currentCoordinate: currentCoordinate,
                isRequestingLocation: isRequestingLocation,
                onRequestLocation: onRequestLocation,
                onOpenCamera: onOpenCamera,
                onPublish: onPublish,
                onDiscard: onDiscard
            )
            .groomCameraPresentation(
                isPresented: $isShowingGroomCamera,
                onCapture: onCapturePhoto,
                onFailure: onCameraFailure
            )
            .groomArchivePresentation(
                isPresented: $isShowingGroomArchive,
                appState: appState,
                currentCoordinate: currentCoordinate
            )
    }
}

private extension View {
    @MainActor
    func groomComposerPresentation(
        isPresented: Binding<Bool>,
        selectedPhotoItem: Binding<PhotosPickerItem?>,
        selectedCreationCoordinate: Binding<MegrumLocationCoordinate?>,
        draftPhotoData: Binding<Data?>,
        draftPhotoContentType: Binding<String>,
        isPreparingPhoto: Bool,
        isCreating: Bool,
        canUseCamera: Bool,
        currentCoordinate: MegrumLocationCoordinate?,
        isRequestingLocation: Bool,
        onRequestLocation: @escaping () -> Void,
        onOpenCamera: @escaping () -> Void,
        onPublish: @escaping (Data, String, String?, MegrumLocationCoordinate) async -> Bool,
        onDiscard: @escaping () -> Void
    ) -> some View {
        #if os(iOS)
        fullScreenCover(isPresented: isPresented) {
            GroomStoryComposerScreen(
                selectedPhotoItem: selectedPhotoItem,
                selectedCreationCoordinate: selectedCreationCoordinate,
                draftPhotoData: draftPhotoData,
                draftPhotoContentType: draftPhotoContentType,
                isPreparingPhoto: isPreparingPhoto,
                isCreating: isCreating,
                canUseCamera: canUseCamera,
                currentCoordinate: currentCoordinate,
                isRequestingLocation: isRequestingLocation,
                onRequestLocation: onRequestLocation,
                onOpenCamera: onOpenCamera,
                onPublish: onPublish,
                onDiscard: onDiscard
            )
        }
        #else
        sheet(isPresented: isPresented) {
            GroomStoryComposerScreen(
                selectedPhotoItem: selectedPhotoItem,
                selectedCreationCoordinate: selectedCreationCoordinate,
                draftPhotoData: draftPhotoData,
                draftPhotoContentType: draftPhotoContentType,
                isPreparingPhoto: isPreparingPhoto,
                isCreating: isCreating,
                canUseCamera: false,
                currentCoordinate: currentCoordinate,
                isRequestingLocation: isRequestingLocation,
                onRequestLocation: onRequestLocation,
                onOpenCamera: onOpenCamera,
                onPublish: onPublish,
                onDiscard: onDiscard
            )
        }
        #endif
    }

    @MainActor
    func groomCameraPresentation(
        isPresented: Binding<Bool>,
        onCapture: @escaping (Data) -> Void,
        onFailure: @escaping (String) -> Void
    ) -> some View {
        #if os(iOS)
        sheet(isPresented: isPresented) {
            NativeCameraCaptureView(
                onCapture: onCapture,
                onFailure: onFailure
            )
            .ignoresSafeArea()
        }
        #else
        self
        #endif
    }

    @MainActor
    func groomArchivePresentation(
        isPresented: Binding<Bool>,
        appState: MegrumAppState,
        currentCoordinate: MegrumLocationCoordinate?
    ) -> some View {
        #if os(iOS)
        fullScreenCover(isPresented: isPresented) {
            GroomArchiveScreen(
                appState: appState,
                currentCoordinate: currentCoordinate
            )
        }
        #else
        sheet(isPresented: isPresented) {
            GroomArchiveScreen(
                appState: appState,
                currentCoordinate: currentCoordinate
            )
        }
        #endif
    }
}
