import MegrumCore
import MapKit
import SwiftUI

extension MeguriScreen {
    func requestInitialLocationIfNeeded() {
        guard !VisualQAPreviewMode.isEnabled(environment: ProcessInfo.processInfo.environment) else {
            return
        }
        locationState.requestCurrentLocation()
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
            locationState.requestCurrentLocation()
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
                locationState.requestCurrentLocation()
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
        if locationState.coordinate == nil {
            locationState.requestCurrentLocation()
        }
        isShowingThreadComposer = true
    }

    func openThreadFromHome(_ thread: BoardThread) {
        guard MeguriAccessPolicy.canOpenBoard(
            thread,
            currentCoordinate: locationState.coordinate,
            viewerID: appState.viewer?.id
        ) else {
            if locationState.coordinate == nil {
                locationState.requestCurrentLocation()
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
            locationState.requestCurrentLocation()
            return
        }
        centerHomeMap(on: coordinate, animated: true)
    }

    func openPendingCreatedThreadIfNeeded() {
        guard let thread = pendingCreatedThread else {
            return
        }
        pendingCreatedThread = nil
        selectedThread = thread
    }

    func centerHomeMap(on coordinate: MegrumLocationCoordinate, animated: Bool) {
        let region = MKCoordinateRegion(
            center: coordinate.clLocationCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.018, longitudeDelta: 0.018)
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
}
