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
            viewerID: appState.viewer?.id
        ) else {
            if locationState.coordinate == nil {
                locationState.startUpdatingCurrentLocation()
            }
            showOutOfRangeAlert(
                MeguriAccessPolicy.groomAccessMessage(
                    groom,
                    currentCoordinate: locationState.coordinate,
                    viewerID: appState.viewer?.id
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
