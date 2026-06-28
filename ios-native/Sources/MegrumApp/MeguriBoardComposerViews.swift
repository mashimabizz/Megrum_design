import MegrumCore
import MegrumDesign
import PhotosUI
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct BoardThreadComposerSheet: View {
    static let defaultAnonymousDisplayName = "めぐりさん"
    static let defaultAnonymousAvatarID = BoardAnonymousAvatarOption.options.first?.id ?? "avatar_1"

    @ObservedObject var appState: MegrumAppState
    @ObservedObject var locationState: MegrumLocationState
    var fallbackCoordinate: MegrumLocationCoordinate?
    var initialCreationCoordinate: MegrumLocationCoordinate?
    var locksCreationCoordinate: Bool
    var selectedPrefecture: String?
    var onCreated: (BoardThread) -> Void

    @Environment(\.dismiss) var dismiss
    @State var title = ""
    @State var bodyText = ""
    @State var anonymousDisplayName = BoardThreadComposerSheet.defaultAnonymousDisplayName
    @State var anonymousAvatarID = BoardThreadComposerSheet.defaultAnonymousAvatarID
    @State var thumbnailItem: PhotosPickerItem?
    @State var thumbnailUpload: GoodsPhotoUpload?
    @State var thumbnailErrorMessage: String?
    @State var selectedCoordinate: MegrumLocationCoordinate?
    @State var isShowingLocationStep = false
    @State var toastMessage: String?
    @State var toastID = UUID()
    #if canImport(UIKit)
    @State var thumbnailPreviewImage: UIImage?
    #endif

    init(
        appState: MegrumAppState,
        locationState: MegrumLocationState,
        fallbackCoordinate: MegrumLocationCoordinate? = nil,
        initialCreationCoordinate: MegrumLocationCoordinate? = nil,
        locksCreationCoordinate: Bool = false,
        selectedPrefecture: String?,
        onCreated: @escaping (BoardThread) -> Void = { _ in }
    ) {
        self.appState = appState
        self.locationState = locationState
        self.fallbackCoordinate = fallbackCoordinate
        self.initialCreationCoordinate = initialCreationCoordinate
        self.locksCreationCoordinate = locksCreationCoordinate
        self.selectedPrefecture = selectedPrefecture
        self.onCreated = onCreated
        _selectedCoordinate = State(initialValue: initialCreationCoordinate)
        _isShowingLocationStep = State(initialValue: locksCreationCoordinate)
    }

    var body: some View {
        composerContent
            .background(MegrumTheme.canvas.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                BoardThreadComposerPrimaryActionBar(
                    title: primaryActionTitle,
                    isCreating: appState.isCreatingBoardThread,
                    isEnabled: primaryActionEnabled,
                    action: handlePrimaryAction
                )
            }
            .overlay(alignment: .bottom) {
                if let toastMessage {
                    MeguriToastView(message: toastMessage)
                        .padding(.bottom, 84)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("チャットルーム")
            .megrumInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .onChange(of: thumbnailItem) { _, item in
                loadThumbnail(item)
            }
            .task {
                await hydrateMeguriProfileDefaults()
                if baseCoordinate == nil {
                    locationState.requestCurrentLocation()
                }
            }
            .onChange(of: locationState.coordinate) { _, _ in
                if isShowingLocationStep {
                    seedSelectedCoordinateIfNeeded()
                }
            }
    }

    private var composerContent: some View {
        #if canImport(UIKit)
        BoardThreadComposerContent(
            title: $title,
            bodyText: $bodyText,
            anonymousDisplayName: $anonymousDisplayName,
            anonymousAvatarID: $anonymousAvatarID,
            thumbnailItem: $thumbnailItem,
            missingContextMessage: missingContextMessage,
            isShowingLocationStep: isShowingLocationStep,
            locksCreationCoordinate: locksCreationCoordinate,
            hasThumbnail: thumbnailUpload != nil,
            currentCoordinate: baseCoordinate,
            isRequestingLocation: locationState.isRequestingLocation,
            selectedCoordinate: $selectedCoordinate,
            thumbnailPreviewImage: thumbnailPreviewImage,
            onRemoveThumbnail: clearThumbnail,
            onRequestLocation: {
                locationState.requestCurrentLocation()
            },
            onOutOfRange: showToast,
            onLocationStepAppear: seedSelectedCoordinateIfNeeded
        )
        #else
        BoardThreadComposerContent(
            title: $title,
            bodyText: $bodyText,
            anonymousDisplayName: $anonymousDisplayName,
            anonymousAvatarID: $anonymousAvatarID,
            thumbnailItem: $thumbnailItem,
            missingContextMessage: missingContextMessage,
            isShowingLocationStep: isShowingLocationStep,
            locksCreationCoordinate: locksCreationCoordinate,
            hasThumbnail: thumbnailUpload != nil,
            currentCoordinate: baseCoordinate,
            isRequestingLocation: locationState.isRequestingLocation,
            selectedCoordinate: $selectedCoordinate,
            onRemoveThumbnail: clearThumbnail,
            onRequestLocation: {
                locationState.requestCurrentLocation()
            },
            onOutOfRange: showToast,
            onLocationStepAppear: seedSelectedCoordinateIfNeeded
        )
        #endif
    }
}
