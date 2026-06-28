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
            locationState.startUpdatingCurrentLocation()
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
        case .all:
            async let grooms: Void = appState.loadGroomMapPosts(
                latitude: latitude,
                longitude: longitude,
                radiusMeters: 3_000
            )
            if boardScope == .nearby3km, (latitude == nil || longitude == nil) {
                await MainActor.run {
                    locationState.startUpdatingCurrentLocation()
                }
                _ = await grooms
                return
            }
            async let boards: Void = appState.loadMeguriFeed(
                latitude: latitude,
                longitude: longitude,
                prefecture: selectedPrefecture,
                scope: mapBoardScope
            )
            _ = await (grooms, boards)
        case .grooms:
            await appState.loadGroomMapPosts(
                latitude: latitude,
                longitude: longitude,
                radiusMeters: 3_000
            )
        case .boards:
            if boardScope == .nearby3km, (latitude == nil || longitude == nil) {
                await MainActor.run {
                    locationState.startUpdatingCurrentLocation()
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
        guard kind == .grooms || kind == .all else {
            selectedGroom = groom
            return
        }
        if canOpen(groom: groom) {
            mapNotice = nil
            selectedGroom = groom
            return
        }
        guard locationState.coordinate != nil else {
            locationState.startUpdatingCurrentLocation()
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

    func openGroomCluster(_ grooms: [GroomPost]) {
        let openable = grooms.filter(canOpen(groom:))
        let visibleGrooms = openable.isEmpty ? grooms : openable
        guard let first = visibleGrooms.first else {
            return
        }
        if openable.isEmpty {
            showOutOfRangeAlert(groomRangeNotice(first))
            return
        }
        mapNotice = nil
        selectedGroomGroup = GroomMapGroomSelection(grooms: visibleGrooms, initialGroom: first)
    }

    func openThreadIfInRange(_ thread: BoardThread) {
        if canOpen(thread: thread) {
            mapNotice = nil
            selectedThread = thread
            return
        }
        guard locationState.coordinate != nil else {
            locationState.startUpdatingCurrentLocation()
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
        outOfRangeAlertMessage = message.isEmpty ? "半径1km以内のグルームとチャットルームのみ開けます。" : message
        isShowingOutOfRangeAlert = true
    }
}
