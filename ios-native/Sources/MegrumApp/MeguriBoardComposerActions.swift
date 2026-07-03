import Foundation
import PhotosUI
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

extension BoardThreadComposerSheet {
    func hydrateMeguriProfileDefaults() async {
        guard anonymousDisplayName == Self.defaultAnonymousDisplayName,
              anonymousAvatarID == Self.defaultAnonymousAvatarID
        else {
            return
        }
        if appState.meguriProfile == nil {
            await appState.loadMeguriProfile(reportsFailure: false)
        }
        guard let profile = appState.meguriProfile else {
            return
        }
        anonymousDisplayName = profile.displayName
        anonymousAvatarID = profile.avatarID
    }

    func loadThumbnail(_ item: PhotosPickerItem?) {
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

    func clearThumbnail() {
        thumbnailItem = nil
        thumbnailUpload = nil
        thumbnailErrorMessage = nil
        #if canImport(UIKit)
        thumbnailPreviewImage = nil
        #endif
    }

    func handlePrimaryAction() {
        submitThread()
    }

    func revealLocationStep() {
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

    func submitThread() {
        guard canSubmit else {
            if locationMessage != nil {
                locationState.requestCurrentLocation()
                seedSelectedCoordinateIfNeeded()
            }
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
                thumbnailUpload: thumbnailUpload,
                anonymousDisplayName: anonymousDisplayName,
                anonymousAvatarID: anonymousAvatarID,
                groupID: metadataDraft.groupID,
                characterID: metadataDraft.characterID,
                seriesName: metadataDraft.normalizedSeriesName
            )
            if let created {
                onCreated(created)
                dismiss()
            } else {
                let message = appState.errorMessage ?? "チャットルームを作成できませんでした"
                showToast(message)
                appState.clearErrorMessage()
            }
        }
    }

    func seedSelectedCoordinateIfNeeded() {
        guard selectedCoordinate == nil else {
            return
        }
        selectedCoordinate = baseCoordinate
    }

    func showToast(_ message: String) {
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
