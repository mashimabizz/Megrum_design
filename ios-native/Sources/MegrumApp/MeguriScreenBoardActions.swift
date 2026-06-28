import MegrumCore
import MapKit
import SwiftUI

extension MeguriScreen {
    func requestInitialLocationIfNeeded() {
        guard !VisualQAPreviewMode.isEnabled(environment: ProcessInfo.processInfo.environment) else {
            return
        }
        if let coordinate = locationState.coordinate {
            shouldCenterHomeMapWhenLocationArrives = false
            centerHomeMap(on: coordinate, animated: false)
        } else {
            shouldCenterHomeMapWhenLocationArrives = true
        }
        locationState.startUpdatingCurrentLocation()
    }

    func handleCoordinateChange(_ coordinate: MegrumLocationCoordinate) {
        if shouldCenterHomeMapWhenLocationArrives {
            shouldCenterHomeMapWhenLocationArrives = false
            centerHomeMap(on: coordinate, animated: true)
        }

        Task {
            await appState.loadMeguriFeed(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                prefecture: selectedBoardPrefecture,
                scope: selectedBoardScope
            )
            await appState.loadGroomMapPosts(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                radiusMeters: 3_000
            )
        }
    }

    func selectBoardPrefecture(_ prefecture: String) {
        storedBoardPrefecture = prefecture
        storedBoardScopeRaw = BoardThread.Audience.samePrefecture.rawValue
        Task {
            await reloadMeguriFeed(scope: .samePrefecture)
        }
    }

    func updateBoardScope(_ scope: BoardThread.Audience) {
        storedBoardScopeRaw = scope.rawValue
        if scope == .nearby3km, locationState.coordinate == nil {
            locationState.startUpdatingCurrentLocation()
            return
        }
        Task {
            await reloadMeguriFeed(scope: scope)
        }
    }

    func reloadMeguriFeed(scope: BoardThread.Audience? = nil) async {
        let targetScope = scope ?? selectedBoardScope
        if targetScope == .nearby3km, locationState.coordinate == nil {
            await MainActor.run {
                locationState.startUpdatingCurrentLocation()
            }
            return
        }
        await appState.loadMeguriFeed(
            latitude: locationState.coordinate?.latitude,
            longitude: locationState.coordinate?.longitude,
            prefecture: selectedBoardPrefecture,
            scope: targetScope
        )
        if let coordinate = locationState.coordinate {
            await appState.loadGroomMapPosts(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                radiusMeters: 3_000
            )
        }
    }

    func openThreadComposer() {
        threadCreationCoordinate = nil
        if locationState.coordinate == nil {
            locationState.startUpdatingCurrentLocation()
        }
        isShowingThreadComposer = true
    }

    func openThreadComposer(at coordinate: MegrumLocationCoordinate) {
        threadCreationCoordinate = coordinate
        isShowingThreadComposer = true
    }

    func openThreadFromHome(_ thread: BoardThread) {
        guard MeguriAccessPolicy.canOpenBoard(
            thread,
            currentCoordinate: locationState.coordinate,
            viewerID: appState.viewer?.id
        ) else {
            if locationState.coordinate == nil {
                locationState.startUpdatingCurrentLocation()
            }
            showOutOfRangeAlert(
                MeguriAccessPolicy.boardAccessMessage(
                    thread,
                    currentCoordinate: locationState.coordinate,
                    viewerID: appState.viewer?.id
                )
            )
            return
        }
        selectedThread = thread
    }

    func centerHomeMapOnCurrentLocation() {
        guard let coordinate = locationState.coordinate else {
            shouldCenterHomeMapWhenLocationArrives = true
            locationState.startUpdatingCurrentLocation()
            return
        }
        centerHomeMap(on: coordinate, animated: true)
    }

    func openPendingCreatedThreadIfNeeded() {
        threadCreationCoordinate = nil
        guard let thread = pendingCreatedThread else {
            return
        }
        pendingCreatedThread = nil
        selectedThread = thread
    }

    func centerHomeMap(on coordinate: MegrumLocationCoordinate, animated: Bool) {
        let region = MKCoordinateRegion(
            center: coordinate.clLocationCoordinate,
            span: MeguriHomeMapCamera.focusedSpan
        )
        let update = {
            homeCameraPosition = .region(region)
        }
        if animated {
            withAnimation(.smooth(duration: 0.28)) {
                update()
            }
        } else {
            update()
        }
    }

    func handleHomeMapTap(_ coordinate: MegrumLocationCoordinate) {
        guard let currentCoordinate = locationState.coordinate else {
            pendingMapCreationCoordinate = nil
            shouldCenterHomeMapWhenLocationArrives = true
            locationState.startUpdatingCurrentLocation()
            showToast("現在地を確認してから、1km圏内をタップしてください")
            return
        }
        guard MeguriAccessPolicy.canCreateAt(
            coordinate,
            currentCoordinate: currentCoordinate
        ) else {
            showToast("1km圏外にグルーム・チャットは作成できません", placement: .top)
            return
        }
        withAnimation(.easeOut(duration: 0.16)) {
            pendingMapCreationCoordinate = coordinate
        }
    }

    func openThreadComposerAtPendingCoordinate() {
        guard let coordinate = pendingMapCreationCoordinate else {
            return
        }
        dismissPendingMapCreationCoordinate()
        openThreadComposer(at: coordinate)
    }

    func dismissPendingMapCreationCoordinate() {
        withAnimation(.easeOut(duration: 0.14)) {
            pendingMapCreationCoordinate = nil
        }
    }
}
