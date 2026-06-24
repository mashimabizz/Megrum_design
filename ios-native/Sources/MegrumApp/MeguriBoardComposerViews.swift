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

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var bodyText = ""
    @State private var thumbnailItem: PhotosPickerItem?
    @State private var thumbnailUpload: GoodsPhotoUpload?
    @State private var thumbnailErrorMessage: String?
    @State private var selectedCoordinate: MegrumLocationCoordinate?
    @State private var isShowingLocationStep = false
    @State private var toastMessage: String?
    @State private var toastID = UUID()
    #if canImport(UIKit)
    @State private var thumbnailPreviewImage: UIImage?
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

    private var canSubmit: Bool {
        isShowingLocationStep
            && contentMessage == nil
            && locationMessage == nil
            && !appState.isCreatingBoardThread
    }

    private var missingContextMessage: String? {
        if let contentMessage {
            return contentMessage
        }
        guard isShowingLocationStep else {
            return nil
        }
        return locationMessage
    }

    private var contentMessage: String? {
        if let thumbnailErrorMessage {
            return thumbnailErrorMessage
        }
        guard !title.isBlank else {
            return "タイトルを入力してください"
        }
        guard !bodyText.isBlank else {
            return "本文を入力してください"
        }
        return nil
    }

    private var locationMessage: String? {
        guard baseCoordinate != nil else {
            return "現在地を確認してから作成場所を選んでください"
        }
        guard selectedCoordinate != nil else {
            return "地図上で作成場所を選んでください"
        }
        guard submitCoordinate != nil else {
            return "1km圏外には作成できません"
        }
        return nil
    }

    private var canAdvanceToLocationStep: Bool {
        contentMessage == nil && !appState.isCreatingBoardThread
    }

    private var primaryActionTitle: String {
        isShowingLocationStep ? "この場所で作成する" : "最後に場所を決める"
    }

    private var primaryActionEnabled: Bool {
        isShowingLocationStep ? canSubmit : canAdvanceToLocationStep
    }

    private var submitLatitude: Double? {
        submitCoordinate?.latitude
    }

    private var submitLongitude: Double? {
        submitCoordinate?.longitude
    }

    private var submitScope: BoardThread.Audience {
        .nearby3km
    }

    private var submitCoordinate: MegrumLocationCoordinate? {
        guard let selectedCoordinate,
              MeguriAccessPolicy.canCreateAt(
                  selectedCoordinate,
                  currentCoordinate: baseCoordinate
              )
        else {
            return nil
        }
        return selectedCoordinate
    }

    private var baseCoordinate: MegrumLocationCoordinate? {
        locationState.coordinate ?? fallbackCoordinate
    }

    private var submitPrefecture: String? {
        selectedPrefecture.nilIfBlank
            ?? (appState.viewer?.prefecture).nilIfBlank
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

    private func loadThumbnail(_ item: PhotosPickerItem?) {
        guard let item else {
            return
        }
        Task {
            guard let data = try? await item.loadTransferable(type: Data.self) else {
                await MainActor.run {
                    thumbnailErrorMessage = "サムネイルを読み込めませんでした"
                }
                return
            }
            let upload = normalizedPhotoUpload(from: data)
            await MainActor.run {
                if upload.data.count > goodsEditorMaxPhotoUploadBytes {
                    thumbnailErrorMessage = "サムネイルは10MB以下にしてください"
                    thumbnailUpload = nil
                    #if canImport(UIKit)
                    thumbnailPreviewImage = nil
                    #endif
                    return
                }
                thumbnailUpload = upload
                thumbnailErrorMessage = nil
                #if canImport(UIKit)
                thumbnailPreviewImage = UIImage(data: upload.data)
                #endif
            }
        }
    }

    private func clearThumbnail() {
        thumbnailItem = nil
        thumbnailUpload = nil
        thumbnailErrorMessage = nil
        #if canImport(UIKit)
        thumbnailPreviewImage = nil
        #endif
    }

    private func handlePrimaryAction() {
        if !isShowingLocationStep {
            revealLocationStep()
            return
        }
        submitThread()
    }

    private func revealLocationStep() {
        guard canAdvanceToLocationStep else {
            if let contentMessage {
                showToast(contentMessage)
            }
            return
        }
        isShowingLocationStep = true
        if baseCoordinate == nil {
            locationState.requestCurrentLocation()
        }
        seedSelectedCoordinateIfNeeded()
    }

    private func submitThread() {
        guard canSubmit else {
            if let missingContextMessage {
                showToast(missingContextMessage)
            }
            return
        }
        Task {
            let created = await appState.createBoardThreadRecord(
                title: title,
                body: bodyText,
                scope: submitScope,
                latitude: submitLatitude,
                longitude: submitLongitude,
                prefecture: submitPrefecture,
                thumbnailUpload: thumbnailUpload
            )
            if let created {
                onCreated(created)
                dismiss()
            } else {
                let message = appState.errorMessage ?? "掲示板を作成できませんでした"
                showToast(message)
                appState.clearErrorMessage()
            }
        }
    }

    private func seedSelectedCoordinateIfNeeded() {
        guard selectedCoordinate == nil else {
            return
        }
        selectedCoordinate = baseCoordinate
    }

    private func showToast(_ message: String) {
        let toastID = UUID()
        self.toastID = toastID
        withAnimation(.smooth(duration: 0.18)) {
            toastMessage = message
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.4))
            guard self.toastID == toastID else {
                return
            }
            withAnimation(.smooth(duration: 0.18)) {
                toastMessage = nil
            }
        }
    }
}
