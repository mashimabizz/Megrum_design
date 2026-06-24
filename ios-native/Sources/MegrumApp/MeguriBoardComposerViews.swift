import MegrumCore
import MegrumDesign
import PhotosUI
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct BoardThreadComposerSheet: View {
    @ObservedObject var appState: MegrumAppState
    @ObservedObject var locationState: MegrumLocationState
    var fallbackCoordinate: MegrumLocationCoordinate?
    var selectedPrefecture: String?
    var onCreated: (BoardThread) -> Void

    @Environment(\.dismiss) var dismiss
    @State var title = ""
    @State var bodyText = ""
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
        selectedPrefecture: String?,
        onCreated: @escaping (BoardThread) -> Void = { _ in }
    ) {
        self.appState = appState
        self.locationState = locationState
        self.fallbackCoordinate = fallbackCoordinate
        self.selectedPrefecture = selectedPrefecture
        self.onCreated = onCreated
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("スレッドを立てる")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)

                    Text("周辺の人と現地情報を共有できます")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }

                if let missingContextMessage {
                    MeguriNoticeBanner(message: missingContextMessage)
                }

                thumbnailSection

                BoardThreadTitleField(title: $title)

                BoardThreadBodyEditor(bodyText: $bodyText)

                if isShowingLocationStep {
                    locationStep
                } else {
                    MeguriNoticeBanner(message: "タイトルと本文が決まったら、最後に地図上で表示される場所を選びます。")
                }

            }
            .padding(20)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            Button(action: handlePrimaryAction) {
                Group {
                    if appState.isCreatingBoardThread {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(primaryActionTitle)
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
            .disabled(!primaryActionEnabled)
            .opacity(primaryActionEnabled ? 1 : 0.48)
        }
        .overlay(alignment: .bottom) {
            if let toastMessage {
                MeguriToastView(message: toastMessage)
                    .padding(.bottom, 84)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationTitle("掲示板")
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

    private var thumbnailSection: some View {
        #if canImport(UIKit)
        BoardThreadThumbnailSection(
            thumbnailItem: $thumbnailItem,
            hasThumbnail: thumbnailUpload != nil,
            previewImage: thumbnailPreviewImage,
            onRemoveThumbnail: clearThumbnail
        )
        #else
        BoardThreadThumbnailSection(
            thumbnailItem: $thumbnailItem,
            hasThumbnail: thumbnailUpload != nil,
            onRemoveThumbnail: clearThumbnail
        )
        #endif
    }

    private var locationStep: some View {
        BoardThreadComposerLocationStep(
            title: title.nilIfBlank ?? "掲示板",
            summary: bodyText.nilIfBlank ?? "現地の話題",
            hasThumbnail: thumbnailUpload != nil,
            currentCoordinate: baseCoordinate,
            isRequestingLocation: locationState.isRequestingLocation,
            selectedCoordinate: $selectedCoordinate,
            onRequestLocation: {
                locationState.requestCurrentLocation()
            },
            onOutOfRange: showToast,
            onAppear: seedSelectedCoordinateIfNeeded
        )
    }
}
