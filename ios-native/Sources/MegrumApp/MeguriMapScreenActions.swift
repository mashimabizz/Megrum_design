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
            threads: mapThreads,
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

        // FB(iter1226.390): 地図の現在地1km圏内の推しグルームを検出して遭遇記録＋通知。
        if let latitude, let longitude, kind == .all || kind == .grooms {
            await appState.evaluateGroomProximity(latitude: latitude, longitude: longitude)
        }
    }

    func openGroomIfInRange(_ groom: GroomPost) {
        guard kind == .grooms || kind == .all else {
            presentGroomViewer(grooms: [groom], initialGroom: groom, sourceID: .groom(groom.id))
            return
        }
        if canOpen(groom: groom) {
            mapNotice = nil
            // 1km圏内＋地図表示中のグルームを1つのストーリーとして繋げて開く。
            let connected = GroomNearbyStoryResolver.connectedGrooms(
                around: groom,
                in: mapGrooms.filter(canOpen(groom:))
            )
            presentGroomViewer(grooms: connected, initialGroom: groom, sourceID: .groom(groom.id))
            return
        }
        guard locationState.coordinate != nil else {
            locationState.startUpdatingCurrentLocation()
            showOutOfRangeAlert(
                MeguriAccessPolicy.groomAccessMessage(
                    groom,
                    currentCoordinate: locationState.coordinate,
                    viewerID: appState.viewer?.id,
                    hasEncountered: groom.encounteredInRange,
                    subscriptionState: appState.subscriptionState
                )
            )
            return
        }
        showOutOfRangeAlert(groomRangeNotice(groom))
    }

    func openGroomCluster(_ grooms: [GroomPost], _ sourceID: GroomMapZoomSourceID) {
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
        // クラスタも同様に、1km圏内のグルームまで繋げて1つのストーリーで見せる。
        let connected = GroomNearbyStoryResolver.connectedGrooms(
            around: first,
            in: mapGrooms.filter(canOpen(groom:))
        )
        let storyGrooms = connected.count > 1 ? connected : visibleGrooms
        presentGroomViewer(grooms: storyGrooms, initialGroom: first, sourceID: sourceID)
    }

    /// iter1226.457：ホームレールと同じ「タップ即提示」。source（常設のoverlayピン）は
    /// 既に layout 済みなので、待たずに route を立てるだけで zoom がマッチする。
    func presentGroomViewer(grooms: [GroomPost], initialGroom: GroomPost, sourceID: GroomMapZoomSourceID) {
        GroomOpenMetricsLog.emit("mapTap", "present groom=\(initialGroom.id)")
        prefetchGroomImages(grooms)
        viewerRoute = GroomMapViewerRoute(
            sourceID: sourceID,
            grooms: grooms,
            initialGroom: initialGroom
        )
    }

    /// ビューアを開く前に先頭数枚の画像を温めて、開いた瞬間のローディングを防ぐ。
    private func prefetchGroomImages(_ grooms: [GroomPost]) {
        let urls = grooms.prefix(3).map(\.imageURL)
        guard !urls.isEmpty else {
            return
        }
        Task(priority: .userInitiated) {
            await GoodsRemoteImageDataLoader.preload(urls: urls)
        }
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
                    viewerID: appState.viewer?.id,
                    subscriptionState: appState.subscriptionState
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
            viewerID: appState.viewer?.id,
            hasEncountered: groom.encounteredInRange,
            subscriptionState: appState.subscriptionState
        )
    }

    func isBoardOutOfRange(_ thread: BoardThread) -> Bool {
        !MeguriAccessPolicy.canOpenBoard(
            thread,
            currentCoordinate: locationState.coordinate,
            viewerID: appState.viewer?.id,
            subscriptionState: appState.subscriptionState
        )
    }

    func canOpen(groom: GroomPost) -> Bool {
        MeguriAccessPolicy.canOpenGroom(
            groom,
            currentCoordinate: locationState.coordinate,
            viewerID: appState.viewer?.id,
            hasEncountered: groom.encounteredInRange,
            subscriptionState: appState.subscriptionState
        )
    }

    func canOpen(thread: BoardThread) -> Bool {
        MeguriAccessPolicy.canOpenBoard(
            thread,
            currentCoordinate: locationState.coordinate,
            viewerID: appState.viewer?.id,
            subscriptionState: appState.subscriptionState
        )
    }

    func groomRangeNotice(_ groom: GroomPost) -> String {
        MeguriAccessPolicy.groomAccessMessage(
            groom,
            currentCoordinate: locationState.coordinate,
            viewerID: appState.viewer?.id,
            hasEncountered: groom.encounteredInRange,
            subscriptionState: appState.subscriptionState
        )
    }

    func boardRangeNotice(_ thread: BoardThread) -> String {
        MeguriAccessPolicy.boardAccessMessage(
            thread,
            currentCoordinate: locationState.coordinate,
            viewerID: appState.viewer?.id,
            subscriptionState: appState.subscriptionState
        )
    }

    func showOutOfRangeAlert(_ message: String) {
        outOfRangeAlertMessage = message.isEmpty ? "半径1km以内のグルームとチャットルームのみ開けます。" : message
        isShowingOutOfRangeAlert = true
    }
}
