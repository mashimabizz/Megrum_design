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
            beginGroomZoom(
                grooms: [groom],
                initialGroom: groom,
                mirrorCoordinate: CLLocationCoordinate2D(latitude: groom.latitude, longitude: groom.longitude),
                isCluster: false,
                clusterCount: 1
            )
            return
        }
        if canOpen(groom: groom) {
            mapNotice = nil
            // 1km圏内＋地図表示中のグルームを1つのストーリーとして繋げて開く。
            let connected = GroomNearbyStoryResolver.connectedGrooms(
                around: groom,
                in: mapGrooms.filter(canOpen(groom:))
            )
            prefetchGroomImages(connected)
            beginGroomZoom(
                grooms: connected,
                initialGroom: groom,
                mirrorCoordinate: CLLocationCoordinate2D(latitude: groom.latitude, longitude: groom.longitude),
                isCluster: false,
                clusterCount: 1
            )
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

    func openGroomCluster(_ grooms: [GroomPost], _ pinCoordinate: CLLocationCoordinate2D) {
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
        prefetchGroomImages(storyGrooms)
        beginGroomZoom(
            grooms: storyGrooms,
            initialGroom: first,
            mirrorCoordinate: pinCoordinate,
            isCluster: grooms.count > 1,
            clusterCount: grooms.count
        )
    }

    /// iter1226.455：二段階提示の1段階目。ミラー用の pendingZoom を立てる（まだ開かない）。
    /// ミラーが layout 済みになったら handleZoomMirrorFrame が viewerRoute を立てて push する。
    func beginGroomZoom(
        grooms: [GroomPost],
        initialGroom: GroomPost,
        mirrorCoordinate: CLLocationCoordinate2D,
        isCluster: Bool,
        clusterCount: Int
    ) {
        pendingZoom = PendingGroomMapZoom(
            id: UUID(),
            latitude: mirrorCoordinate.latitude,
            longitude: mirrorCoordinate.longitude,
            representative: initialGroom,
            grooms: grooms,
            initialGroom: initialGroom,
            isCluster: isCluster,
            clusterCount: clusterCount,
            isRead: appState.viewedGroomIDs.contains(initialGroom.id)
        )
    }

    /// iter1226.455：ミラー（source）の layout 完了フレームを受けて push を開始する。
    /// 同一フレームで source と提示が生まれる問題を避け、source が確実に存在してから zoom する。
    func handleZoomMirrorFrame(_ frame: CGRect) {
        guard let pending = pendingZoom,
              viewerRoute == nil,
              lastPresentedZoomID != pending.id,   // 閉じた後の再オープンを防ぐ
              frame.width > 0,
              frame.height > 0
        else {
            return
        }
        Task { @MainActor in
            await Task.yield()
            guard pendingZoom?.id == pending.id,
                  viewerRoute == nil,
                  lastPresentedZoomID != pending.id
            else {
                return
            }
            lastPresentedZoomID = pending.id
            viewerRoute = GroomMapViewerRoute(
                sourceID: pending.id,
                grooms: pending.grooms,
                initialGroom: pending.initialGroom
            )
        }
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
