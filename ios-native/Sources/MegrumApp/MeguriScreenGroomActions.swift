import Foundation
import MegrumCore
import PhotosUI
import SwiftUI

extension MeguriScreen {
    func handleSelectedGroomPhotoItem(_ item: PhotosPickerItem?) {
        guard let item else {
            return
        }
        Task {
            await prepareSelectedGroomPhoto(item)
        }
    }

    func preloadGroomAuthorProfiles() async {
        let authorIDs = Set(appState.grooms.map(\.authorID))
        await appState.loadMeguriProfiles(userIDs: authorIDs, reportsFailure: false)
        for authorID in authorIDs where authorID != appState.viewer?.id && appState.publicProfilesByUserID[authorID] == nil {
            await appState.loadPublicUserProfile(userID: authorID, reportsFailure: false)
        }
    }

    func prepareSelectedGroomPhoto(_ item: PhotosPickerItem) async {
        isPreparingGroomPhoto = true
        defer {
            selectedGroomPhotoItem = nil
            isPreparingGroomPhoto = false
        }

        guard let data = try? await item.loadTransferable(type: Data.self) else {
            showToast("写真を読み込めませんでした")
            return
        }
        let upload = normalizedPhotoUpload(from: data)
        groomDraftPhotoData = upload.data
        groomDraftPhotoContentType = upload.contentType
        if groomCreationCoordinate == nil {
            groomCreationCoordinate = locationState.coordinate
        }
    }

    func prepareCapturedGroomPhoto(_ imageData: Data) {
        groomDraftPhotoData = imageData
        groomDraftPhotoContentType = "image/jpeg"
        if groomCreationCoordinate == nil {
            groomCreationCoordinate = locationState.coordinate
        }
        isShowingGroomCamera = false
        isShowingGroomComposer = true
    }

    func publishGroomPhoto(
        data: Data,
        imageContentType: String,
        caption: String?,
        coordinate: MegrumLocationCoordinate,
        metadata: MeguriContentMetadataDraft
    ) async -> Bool {
        await publishGroomPhoto(
            data: data,
            imageContentType: imageContentType,
            caption: caption,
            coordinate: coordinate,
            metadata: metadata,
            skipsArchiveLimitCheck: false
        )
    }

    func publishGroomPhoto(
        data: Data,
        imageContentType: String,
        caption: String?,
        coordinate: MegrumLocationCoordinate,
        metadata: MeguriContentMetadataDraft,
        skipsArchiveLimitCheck: Bool
    ) async -> Bool {
        // 無料プランはアーカイブ10件が上限。超える投稿の前に確認ポップアップを出す。
        if !skipsArchiveLimitCheck, await appState.groomArchiveWouldExceedFreeLimit() {
            pendingGroomPublish = PendingGroomPublish(
                data: data,
                imageContentType: imageContentType,
                caption: caption,
                coordinate: coordinate,
                metadata: metadata
            )
            isShowingGroomArchiveLimitAlert = true
            return false
        }
        let currentCoordinate = locationState.coordinate ?? (isGroomCreationLocationLocked ? coordinate : nil)
        if currentCoordinate == nil {
            locationState.startUpdatingCurrentLocation()
        }
        guard MeguriAccessPolicy.canCreateAt(
            coordinate,
            currentCoordinate: currentCoordinate
        ) else {
            showToast(
                MeguriAccessPolicy.creationLocationMessage(
                    selectedCoordinate: coordinate,
                    currentCoordinate: currentCoordinate
                )
            )
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
            localNoticeMessage = nil
            await appState.trimGroomArchiveToFreeLimitIfNeeded()
            await reloadMeguriFeed(force: true)
            return true
        } else {
            let message = appState.errorMessage ?? "グルームを投稿できませんでした"
            showToast(message)
            appState.clearErrorMessage()
            return false
        }
    }

    func openGroomComposer() {
        resetGroomDraft()
        if locationState.coordinate == nil {
            locationState.startUpdatingCurrentLocation()
        }
        isShowingGroomComposer = true
    }

    func openGroomComposer(at coordinate: MegrumLocationCoordinate) {
        resetGroomDraft()
        groomCreationCoordinate = coordinate
        isGroomCreationLocationLocked = true
        isShowingGroomComposer = true
    }

    func openGroomComposerAtPendingCoordinate() {
        guard let coordinate = pendingMapCreationCoordinate else {
            return
        }
        dismissPendingMapCreationCoordinate()
        openGroomComposer(at: coordinate)
    }

    func resetGroomDraft() {
        selectedGroomPhotoItem = nil
        groomDraftPhotoData = nil
        groomDraftPhotoContentType = "image/jpeg"
        groomCreationCoordinate = nil
        isGroomCreationLocationLocked = false
        isPreparingGroomPhoto = false
    }

    func openGroomFromStrip(_ groom: GroomPost, sourceAnchor: UnitPoint = .center) {
        guard MeguriAccessPolicy.canOpenGroom(
            groom,
            currentCoordinate: locationState.coordinate,
            viewerID: appState.viewer?.id,
            wasNotified: groom.wasNotified,
            subscriptionState: appState.subscriptionState
        ) else {
            if locationState.coordinate == nil {
                locationState.startUpdatingCurrentLocation()
            }
            showOutOfRangeAlert(
                MeguriAccessPolicy.groomAccessMessage(
                    groom,
                    currentCoordinate: locationState.coordinate,
                    viewerID: appState.viewer?.id,
                    wasNotified: groom.wasNotified,
                    subscriptionState: appState.subscriptionState
                )
            )
            return
        }
        localNoticeMessage = nil
        presentGroomViewer(groom, sourceAnchor: sourceAnchor)
    }

    func presentGroomViewer(_ groom: GroomPost, sourceAnchor: UnitPoint) {
        selectedGroomSourceAnchor = sourceAnchor
        if let onOpenGroomViewer {
            onOpenGroomViewer(groom, sourceAnchor)
        } else {
            selectedGroom = groom
        }
    }
}

/// アーカイブ上限確認中に保持する投稿内容。
struct PendingGroomPublish {
    var data: Data
    var imageContentType: String
    var caption: String?
    var coordinate: MegrumLocationCoordinate
    var metadata: MeguriContentMetadataDraft
}

extension MeguriScreen {
    /// 上限ポップアップで「このまま投稿する」を選んだ時：確認済みとして投稿し直す。
    func confirmPendingGroomPublish(_ pending: PendingGroomPublish) {
        pendingGroomPublish = nil
        Task {
            let published = await publishGroomPhoto(
                data: pending.data,
                imageContentType: pending.imageContentType,
                caption: pending.caption,
                coordinate: pending.coordinate,
                metadata: pending.metadata,
                skipsArchiveLimitCheck: true
            )
            if published {
                isShowingGroomComposer = false
                resetGroomDraft()
            }
        }
    }
}
