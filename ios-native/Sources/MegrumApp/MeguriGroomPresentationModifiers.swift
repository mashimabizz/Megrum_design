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
    var locksCreationCoordinate: Bool
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
    var onPublish: (Data, String, String?, MegrumLocationCoordinate, MeguriContentMetadataDraft) async -> Bool
    /// FB(iter1226.399)：ホーム経由「この場所にする」用のバックグラウンド投稿。既定は何もしない。
    var onPublishInBackground: (Data, String, String?, MegrumLocationCoordinate, MeguriContentMetadataDraft) -> Void = { _, _, _, _, _ in }
    /// FB(iter1226.401)：ホーム経由は左からスライドイン。
    var presentsFromLeading: Bool = false
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
                locksCreationCoordinate: locksCreationCoordinate,
                currentCoordinate: currentCoordinate,
                isRequestingLocation: isRequestingLocation,
                groups: appState.oshiGroups,
                characters: appState.oshiCharacters,
                userOshiSelections: appState.userOshiSelections,
                inventory: appState.inventory,
                wishes: appState.wishes,
                isLoadingGroups: appState.isLoadingOshiGroups,
                isLoadingCharacters: appState.isLoadingOshiCharacters,
                onRequestLocation: onRequestLocation,
                onOpenCamera: onOpenCamera,
                onLoadGroups: {
                    await appState.loadOshiGroups()
                },
                onLoadCharacters: { group in
                    await appState.loadOshiCharacters(group: group)
                },
                onLoadUserOshiSelections: {
                    await appState.loadUserOshiSelections()
                },
                onPublish: onPublish,
                onPublishInBackground: onPublishInBackground,
                presentsFromLeading: presentsFromLeading,
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
    @ViewBuilder
    func groomComposerPresentation(
        isPresented: Binding<Bool>,
        selectedPhotoItem: Binding<PhotosPickerItem?>,
        selectedCreationCoordinate: Binding<MegrumLocationCoordinate?>,
        draftPhotoData: Binding<Data?>,
        draftPhotoContentType: Binding<String>,
        isPreparingPhoto: Bool,
        isCreating: Bool,
        canUseCamera: Bool,
        locksCreationCoordinate: Bool,
        currentCoordinate: MegrumLocationCoordinate?,
        isRequestingLocation: Bool,
        groups: [OshiGroup],
        characters: [OshiCharacter],
        userOshiSelections: [UserOshiSelection],
        inventory: [GoodsItem],
        wishes: [WishItem],
        isLoadingGroups: Bool,
        isLoadingCharacters: Bool,
        onRequestLocation: @escaping () -> Void,
        onOpenCamera: @escaping () -> Void,
        onLoadGroups: @escaping () async -> Void,
        onLoadCharacters: @escaping (OshiGroup?) async -> Void,
        onLoadUserOshiSelections: @escaping () async -> Void,
        onPublish: @escaping (Data, String, String?, MegrumLocationCoordinate, MeguriContentMetadataDraft) async -> Bool,
        onPublishInBackground: @escaping (Data, String, String?, MegrumLocationCoordinate, MeguriContentMetadataDraft) -> Void,
        presentsFromLeading: Bool,
        onDiscard: @escaping () -> Void
    ) -> some View {
        #if os(iOS)
        // iter1226.422：ホーム経由（左から）は fullScreenCover を使わない。
        // cover 既定の「下から」アニメが transaction 無効化でも実機で残り、
        // 内部の左オフセットと合成されて「左下から」に見えていたため、
        // 他のスライド画面と同じ ZStack オーバーレイ（.leading）で出す。
        if presentsFromLeading {
            overlay {
                MegrumSlideBoolPresentationOverlay(
                    isPresented: isPresented,
                    backSwipeInteractionScope: .fullScreen,
                    presentationEdge: .leading
                ) { _ in
                    // iter1226.424：スライドオーバーレイ配下は safe area がゼロ化されるため、
                    // ウィンドウ実測のインセットで上下を確保する（ステータスバー重なり防止）。
                    ZStack {
                        Color.black.ignoresSafeArea()
                        GroomStoryComposerScreen(
                            selectedPhotoItem: selectedPhotoItem,
                            selectedCreationCoordinate: selectedCreationCoordinate,
                            draftPhotoData: draftPhotoData,
                            draftPhotoContentType: draftPhotoContentType,
                            isPreparingPhoto: isPreparingPhoto,
                            isCreating: isCreating,
                            canUseCamera: canUseCamera,
                            locksCreationCoordinate: locksCreationCoordinate,
                            currentCoordinate: currentCoordinate,
                            isRequestingLocation: isRequestingLocation,
                            groups: groups,
                            characters: characters,
                            userOshiSelections: userOshiSelections,
                            inventory: inventory,
                            wishes: wishes,
                            isLoadingGroups: isLoadingGroups,
                            isLoadingCharacters: isLoadingCharacters,
                            onRequestLocation: onRequestLocation,
                            onOpenCamera: onOpenCamera,
                            onLoadGroups: onLoadGroups,
                            onLoadCharacters: onLoadCharacters,
                            onLoadUserOshiSelections: onLoadUserOshiSelections,
                            onPublish: onPublish,
                            onPublishInBackground: onPublishInBackground,
                            onDiscard: onDiscard
                        )
                        .padding(.top, MegrumWindowInsets.top)
                        .padding(.bottom, MegrumWindowInsets.bottom)
                    }
                }
            }
        } else {
            fullScreenCover(isPresented: isPresented) {
                    GroomStoryComposerScreen(
                    selectedPhotoItem: selectedPhotoItem,
                    selectedCreationCoordinate: selectedCreationCoordinate,
                    draftPhotoData: draftPhotoData,
                    draftPhotoContentType: draftPhotoContentType,
                    isPreparingPhoto: isPreparingPhoto,
                    isCreating: isCreating,
                    canUseCamera: canUseCamera,
                    locksCreationCoordinate: locksCreationCoordinate,
                    currentCoordinate: currentCoordinate,
                    isRequestingLocation: isRequestingLocation,
                    groups: groups,
                    characters: characters,
                    userOshiSelections: userOshiSelections,
                    inventory: inventory,
                    wishes: wishes,
                    isLoadingGroups: isLoadingGroups,
                    isLoadingCharacters: isLoadingCharacters,
                    onRequestLocation: onRequestLocation,
                    onOpenCamera: onOpenCamera,
                    onLoadGroups: onLoadGroups,
                    onLoadCharacters: onLoadCharacters,
                    onLoadUserOshiSelections: onLoadUserOshiSelections,
                    onPublish: onPublish,
                    onPublishInBackground: onPublishInBackground,
                    onDiscard: onDiscard
                )
            }
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
                locksCreationCoordinate: locksCreationCoordinate,
                currentCoordinate: currentCoordinate,
                isRequestingLocation: isRequestingLocation,
                groups: groups,
                characters: characters,
                userOshiSelections: userOshiSelections,
                inventory: inventory,
                wishes: wishes,
                isLoadingGroups: isLoadingGroups,
                isLoadingCharacters: isLoadingCharacters,
                onRequestLocation: onRequestLocation,
                onOpenCamera: onOpenCamera,
                onLoadGroups: onLoadGroups,
                onLoadCharacters: onLoadCharacters,
                onLoadUserOshiSelections: onLoadUserOshiSelections,
                onPublish: onPublish,
                onPublishInBackground: onPublishInBackground,
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
