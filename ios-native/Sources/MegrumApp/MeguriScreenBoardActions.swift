import MegrumCore
import MapKit
import SwiftUI

extension MeguriScreen {
    func requestInitialLocationIfNeeded() {
        guard !VisualQAPreviewMode.isEnabled(environment: ProcessInfo.processInfo.environment) else {
            return
        }
        // ガイドツアー中は位置情報ダイアログが割り込まないよう抑制する。
        // ツアー終了時に onChange(of: appState.isTutorialActive) で呼び直す（MeguriScreen）。
        guard !appState.isTutorialActive else {
            return
        }
        // センタリングは起動後の初回表示だけ。タブを離れて戻った時は
        // 直前に見ていた位置・ズームを維持する。
        if !didAutoCenterHomeMap {
            if let coordinate = locationState.coordinate {
                didAutoCenterHomeMap = true
                shouldCenterHomeMapWhenLocationArrives = false
                centerHomeMap(on: coordinate, animated: false)
            } else {
                shouldCenterHomeMapWhenLocationArrives = true
            }
        }
        locationState.startUpdatingCurrentLocation()
    }

    func handleCoordinateChange(_ coordinate: MegrumLocationCoordinate) {
        if shouldCenterHomeMapWhenLocationArrives {
            shouldCenterHomeMapWhenLocationArrives = false
            didAutoCenterHomeMap = true
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

    func reloadMeguriFeed(scope: BoardThread.Audience? = nil, force: Bool = false) async {
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
            scope: targetScope,
            force: force
        )
        if let coordinate = locationState.coordinate {
            await appState.loadGroomMapPosts(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                radiusMeters: 3_000,
                force: force
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
            viewerID: appState.viewer?.id,
            subscriptionState: appState.subscriptionState
        ) else {
            if locationState.coordinate == nil {
                locationState.startUpdatingCurrentLocation()
            }
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
        onOpenBoardThread(
            MeguriBoardThreadRoute(
                thread: thread,
                selectedPrefecture: selectedBoardPrefecture,
                coordinate: locationState.coordinate
            )
        )
    }

    /// 地図の表示範囲が変わった時のビューポート読み込み。
    /// 直前の取得範囲でおおむねカバーされている場合は再取得しない。
    func handleViewportChange(_ region: MKCoordinateRegion) {
        // iter1226.434：大きくズームアウトしている間は実データを読み込まず、
        // セルごとの「おおよその件数」だけを軽量RPCで取得して表示する。
        if MeguriMapDensityPlanner.isDensityMode(spanLatitudeDelta: region.span.latitudeDelta) {
            let bounds = MeguriMapDensityPlanner.fetchBounds(region: region)
            let cellDegrees = MeguriMapDensityPlanner.cellDegrees(spanLatitudeDelta: region.span.latitudeDelta)
            Task {
                await appState.loadMeguriMapDensity(
                    minLatitude: bounds.minLatitude,
                    minLongitude: bounds.minLongitude,
                    maxLatitude: bounds.maxLatitude,
                    maxLongitude: bounds.maxLongitude,
                    cellDegrees: cellDegrees
                )
            }
            return
        }

        let center = MegrumLocationCoordinate(
            latitude: region.center.latitude,
            longitude: region.center.longitude
        )
        let halfHeightMeters = region.span.latitudeDelta * 111_000 / 2
        let halfWidthMeters = region.span.longitudeDelta * 111_000
            * cos(region.center.latitude * .pi / 180) / 2
        let viewportRadius = (halfHeightMeters * halfHeightMeters + halfWidthMeters * halfWidthMeters)
            .squareRoot()
        let fetchRadius = min(max(viewportRadius * 1.4, 1_000), 100_000)

        if let lastCenter = lastViewportFetchCenter {
            let moved = CLLocation(latitude: lastCenter.latitude, longitude: lastCenter.longitude)
                .distance(from: CLLocation(latitude: center.latitude, longitude: center.longitude))
            let isCovered = moved < lastViewportFetchRadiusMeters * 0.35
                && fetchRadius <= lastViewportFetchRadiusMeters * 1.25
            if isCovered {
                return
            }
        }
        lastViewportFetchCenter = center
        lastViewportFetchRadiusMeters = fetchRadius

        Task {
            await appState.loadMeguriMapViewport(
                latitude: center.latitude,
                longitude: center.longitude,
                radiusMeters: Int(fetchRadius),
                prefecture: selectedBoardPrefecture,
                scope: selectedBoardScope
            )
        }
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
        onOpenBoardThread(
            MeguriBoardThreadRoute(
                thread: thread,
                selectedPrefecture: selectedBoardPrefecture,
                coordinate: locationState.coordinate
            )
        )
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
