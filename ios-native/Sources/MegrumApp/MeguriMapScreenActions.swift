import MapKit
import MegrumCore
import SwiftUI

extension MeguriMapScreen {
    func alignCameraToVisibleContent(
        userCoordinate: MegrumLocationCoordinate?,
        animated: Bool,
        force: Bool = false
    ) {
        if !force, userCoordinate != nil, hasCenteredMapOnLocation {
            return
        }

        let region = kind.visibleRegion(
            userCoordinate: userCoordinate,
            grooms: mapGrooms,
            threads: appState.threads,
            boardScope: boardScope
        )
        let update = {
            cameraPosition = .region(region)
        }
        if animated {
            withAnimation(.smooth(duration: 0.28)) {
                update()
            }
        } else {
            update()
        }
        if userCoordinate != nil {
            hasCenteredMapOnLocation = true
        }
    }

    func centerMapOnCurrentLocation() {
        guard let coordinate = locationState.coordinate else {
            mapNotice = "現在地を確認中"
            locationState.requestCurrentLocation()
            return
        }

        let region = MKCoordinateRegion(
            center: coordinate.clLocationCoordinate,
            span: kind.regionSpan
        )
        withAnimation(.smooth(duration: 0.28)) {
            cameraPosition = .region(region)
        }
        mapNotice = nil
        hasCenteredMapOnLocation = true
    }

    func reloadMapContent(latitude: Double?, longitude: Double?) async {
        switch kind {
        case .grooms:
            await appState.loadGroomMapPosts(
                latitude: latitude,
                longitude: longitude,
                radiusMeters: 3_000
            )
        case .boards:
            if boardScope == .nearby3km, (latitude == nil || longitude == nil) {
                await MainActor.run {
                    locationState.requestCurrentLocation()
                }
                return
            }
            await appState.loadMeguriFeed(
                latitude: latitude,
                longitude: longitude,
                prefecture: selectedPrefecture,
                scope: mapBoardScope
            )
        }
    }

    func openGroomIfInRange(_ groom: GroomPost) {
        guard kind == .grooms else {
            selectedGroom = groom
            return
        }
        if canOpen(groom: groom) {
            mapNotice = nil
            selectedGroom = groom
            return
        }
        guard locationState.coordinate != nil else {
            locationState.requestCurrentLocation()
            showOutOfRangeAlert(
                MeguriAccessPolicy.groomAccessMessage(
                    groom,
                    currentCoordinate: locationState.coordinate,
                    viewerID: appState.viewer?.id
                )
            )
            return
        }
        showOutOfRangeAlert(groomRangeNotice(groom))
    }

    func openThreadIfInRange(_ thread: BoardThread) {
        if canOpen(thread: thread) {
            mapNotice = nil
            selectedThread = thread
            return
        }
        guard locationState.coordinate != nil else {
            locationState.requestCurrentLocation()
            showOutOfRangeAlert(
                MeguriAccessPolicy.boardAccessMessage(
                    thread,
                    currentCoordinate: locationState.coordinate,
                    viewerID: appState.viewer?.id
                )
            )
            return
        }
        showOutOfRangeAlert(boardRangeNotice(thread))
    }

    func isGroomOutOfRange(_ groom: GroomPost) -> Bool {
        !MeguriAccessPolicy.canOpenGroom(
            groom,
            currentCoordinate: locationState.coordinate,
            viewerID: appState.viewer?.id
        )
    }

    func isBoardOutOfRange(_ thread: BoardThread) -> Bool {
        !MeguriAccessPolicy.canOpenBoard(
            thread,
            currentCoordinate: locationState.coordinate,
            viewerID: appState.viewer?.id
        )
    }

    func canOpen(groom: GroomPost) -> Bool {
        MeguriAccessPolicy.canOpenGroom(
            groom,
            currentCoordinate: locationState.coordinate,
            viewerID: appState.viewer?.id
        )
    }

    func canOpen(thread: BoardThread) -> Bool {
        MeguriAccessPolicy.canOpenBoard(
            thread,
            currentCoordinate: locationState.coordinate,
            viewerID: appState.viewer?.id
        )
    }

    func groomRangeNotice(_ groom: GroomPost) -> String {
        MeguriAccessPolicy.groomAccessMessage(
            groom,
            currentCoordinate: locationState.coordinate,
            viewerID: appState.viewer?.id
        )
    }

    func boardRangeNotice(_ thread: BoardThread) -> String {
        MeguriAccessPolicy.boardAccessMessage(
            thread,
            currentCoordinate: locationState.coordinate,
            viewerID: appState.viewer?.id
        )
    }

    func showOutOfRangeAlert(_ message: String) {
        outOfRangeAlertMessage = message.isEmpty ? "半径1km以内のグルームと掲示板のみ開けます。" : message
        isShowingOutOfRangeAlert = true
    }
}
