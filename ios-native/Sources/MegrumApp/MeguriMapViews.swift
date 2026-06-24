import MegrumCore
import MegrumDesign
import MapKit
import SwiftUI

struct MeguriMapPresentationModifier: ViewModifier {
    @Binding var activeMap: MeguriMapKind?
    @ObservedObject var appState: MegrumAppState
    @ObservedObject var locationState: MegrumLocationState
    var selectedPrefecture: String?
    var boardScope: BoardThread.Audience

    func body(content: Content) -> some View {
        #if os(iOS)
        content.fullScreenCover(item: $activeMap) { kind in
            NavigationStack {
                MeguriMapScreen(
                    kind: kind,
                    appState: appState,
                    locationState: locationState,
                    selectedPrefecture: selectedPrefecture,
                    boardScope: boardScope
                )
            }
        }
        #else
        content.sheet(item: $activeMap) { kind in
            NavigationStack {
                MeguriMapScreen(
                    kind: kind,
                    appState: appState,
                    locationState: locationState,
                    selectedPrefecture: selectedPrefecture,
                    boardScope: boardScope
                )
            }
        }
        #endif
    }
}

enum MeguriMapKind: String, Identifiable {
    case grooms
    case boards

    var id: String { rawValue }

    var title: String {
        switch self {
        case .grooms:
            "グルームマップ"
        case .boards:
            "掲示板マップ"
        }
    }

    var radiusMeters: CLLocationDistance {
        switch self {
        case .grooms:
            MeguriAccessPolicy.groomOpenRadiusMeters
        case .boards:
            MeguriAccessPolicy.boardOpenRadiusMeters
        }
    }

    var regionSpan: MKCoordinateSpan {
        switch self {
        case .grooms:
            MKCoordinateSpan(latitudeDelta: 0.024, longitudeDelta: 0.024)
        case .boards:
            MKCoordinateSpan(latitudeDelta: 0.07, longitudeDelta: 0.07)
        }
    }
}

private struct MeguriMapScreen: View {
    var kind: MeguriMapKind
    @ObservedObject var appState: MegrumAppState
    @ObservedObject var locationState: MegrumLocationState
    var selectedPrefecture: String?
    var boardScope: BoardThread.Audience
    @Environment(\.dismiss) private var dismiss
    @State private var cameraPosition: MapCameraPosition
    @State private var selectedGroom: GroomPost?
    @State private var selectedThread: BoardThread?
    @State private var mapNotice: String?
    @State private var outOfRangeAlertMessage = ""
    @State private var isShowingOutOfRangeAlert = false
    @State private var hasCenteredMapOnLocation = false

    init(
        kind: MeguriMapKind,
        appState: MegrumAppState,
        locationState: MegrumLocationState,
        selectedPrefecture: String?,
        boardScope: BoardThread.Audience
    ) {
        self.kind = kind
        self.appState = appState
        self.locationState = locationState
        self.selectedPrefecture = selectedPrefecture
        self.boardScope = boardScope
        let initialGrooms = appState.groomMapPosts.isEmpty ? appState.grooms : appState.groomMapPosts
        _cameraPosition = State(initialValue: .region(MKCoordinateRegion(center: kind.initialCenter(userCoordinate: locationState.coordinate, grooms: initialGrooms, threads: appState.threads), span: kind.regionSpan)))
    }

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $cameraPosition, interactionModes: [.pan, .zoom, .rotate]) {
                if let rangeCircle {
                    MapCircle(center: rangeCircle.center, radius: rangeCircle.radius)
                        .foregroundStyle(MegrumTheme.lavender.opacity(0.08))
                        .stroke(MegrumTheme.lavender.opacity(0.42), lineWidth: 1.5)
                }

                switch kind {
                case .grooms:
                    ForEach(mapGrooms) { groom in
                        Annotation("グルーム", coordinate: groom.coordinate) {
                            Button {
                                openGroomIfInRange(groom)
                            } label: {
                                GroomMapPin(groom: groom, isOutOfRange: isGroomOutOfRange(groom))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                case .boards:
                    ForEach(appState.threads.compactMap(BoardMapAnnotation.init(thread:))) { annotation in
                        Annotation(annotation.thread.title, coordinate: annotation.coordinate) {
                            Button {
                                openThreadIfInRange(annotation.thread)
                            } label: {
                                BoardMapPin(
                                    thread: annotation.thread,
                                    isOutOfRange: isBoardOutOfRange(annotation.thread)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .mapControls {
                if !VisualQAPreviewMode.isEnabled(environment: ProcessInfo.processInfo.environment) {
                    MapUserLocationButton()
                }
                MapCompass()
                MapScaleView()
            }
            .ignoresSafeArea()

            VStack(spacing: 10) {
                MapGlassHeader(title: kind.title) {
                    dismiss()
                }

                if let mapNotice {
                    MapStatusBadge(
                        message: mapNotice,
                        isLoading: false
                    )
                } else if let mapStatusMessage {
                    MapStatusBadge(
                        message: mapStatusMessage,
                        isLoading: isLoadingMapContent || locationState.isRequestingLocation
                    )
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)

            VStack {
                HStack {
                    Spacer()
                    MeguriMapRecenterButton(
                        isRequesting: locationState.isRequestingLocation,
                        action: centerMapOnCurrentLocation
                    )
                }
                .padding(.top, 72)
                .padding(.trailing, 18)

                Spacer()
            }
        }
        .task {
            if !VisualQAPreviewMode.isEnabled(environment: ProcessInfo.processInfo.environment) {
                locationState.requestCurrentLocation()
            }
            await reloadMapContent(
                latitude: locationState.coordinate?.latitude,
                longitude: locationState.coordinate?.longitude
            )
            await MainActor.run {
                alignCameraToVisibleContent(userCoordinate: locationState.coordinate, animated: false)
            }
        }
        .onReceive(locationState.$coordinate.compactMap { $0 }) { coordinate in
            Task {
                await reloadMapContent(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude
                )
                await MainActor.run {
                    mapNotice = nil
                    alignCameraToVisibleContent(userCoordinate: coordinate, animated: true, force: true)
                }
            }
        }
        .sheet(item: $selectedGroom) { groom in
            GroomMapDetailSheet(groom: groom)
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedThread) { thread in
            NavigationStack {
                BoardThreadDetailScreen(
                    appState: appState,
                    thread: thread,
                    selectedPrefecture: selectedPrefecture,
                    coordinate: locationState.coordinate
                )
            }
        }
        .alert(MeguriAccessPolicy.outOfRangeTitle, isPresented: $isShowingOutOfRangeAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(outOfRangeAlertMessage)
        }
    }

    private func alignCameraToVisibleContent(
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

    private func centerMapOnCurrentLocation() {
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

    private var mapGrooms: [GroomPost] {
        appState.groomMapPosts.isEmpty ? appState.grooms : appState.groomMapPosts
    }

    private var isLoadingMapContent: Bool {
        switch kind {
        case .grooms:
            appState.isLoadingGroomMap
        case .boards:
            appState.isLoadingMeguri
        }
    }

    private func reloadMapContent(latitude: Double?, longitude: Double?) async {
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

    private var rangeCircle: (center: CLLocationCoordinate2D, radius: CLLocationDistance)? {
        guard let coordinate = locationState.coordinate else {
            return nil
        }
        return (coordinate.clLocationCoordinate, kind.radiusMeters)
    }

    private var mapStatusMessage: String? {
        if isLoadingMapContent || locationState.isRequestingLocation {
            return "現在地と投稿を読み込み中"
        }
        if let locationErrorMessage = locationState.locationErrorMessage, kind == .grooms || boardScope == .nearby3km {
            return locationErrorMessage
        }
        if kind == .boards, boardScope == .samePrefecture {
            return "都道府県内の位置つき掲示板を表示中。1km圏外は閲覧できません"
        }
        if kind == .grooms, rangeCircle != nil {
            return "現在地周辺のグルームを表示中。1km圏外は閲覧できません"
        }
        if kind == .boards, rangeCircle != nil {
            return "現在地周辺の掲示板を表示中。1km圏外は閲覧できません"
        }
        if rangeCircle == nil {
            return "範囲円は現在地取得後に表示されます"
        }
        return nil
    }

    private var mapBoardScope: BoardThread.Audience {
        switch kind {
        case .grooms:
            .nearby3km
        case .boards:
            boardScope
        }
    }

    private func openGroomIfInRange(_ groom: GroomPost) {
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

    private func openThreadIfInRange(_ thread: BoardThread) {
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

    private func isGroomOutOfRange(_ groom: GroomPost) -> Bool {
        !MeguriAccessPolicy.canOpenGroom(
            groom,
            currentCoordinate: locationState.coordinate,
            viewerID: appState.viewer?.id
        )
    }

    private func isBoardOutOfRange(_ thread: BoardThread) -> Bool {
        !MeguriAccessPolicy.canOpenBoard(
            thread,
            currentCoordinate: locationState.coordinate,
            viewerID: appState.viewer?.id
        )
    }

    private func canOpen(groom: GroomPost) -> Bool {
        MeguriAccessPolicy.canOpenGroom(
            groom,
            currentCoordinate: locationState.coordinate,
            viewerID: appState.viewer?.id
        )
    }

    private func canOpen(thread: BoardThread) -> Bool {
        MeguriAccessPolicy.canOpenBoard(
            thread,
            currentCoordinate: locationState.coordinate,
            viewerID: appState.viewer?.id
        )
    }

    private func groomRangeNotice(_ groom: GroomPost) -> String {
        MeguriAccessPolicy.groomAccessMessage(
            groom,
            currentCoordinate: locationState.coordinate,
            viewerID: appState.viewer?.id
        )
    }

    private func boardRangeNotice(_ thread: BoardThread) -> String {
        MeguriAccessPolicy.boardAccessMessage(
            thread,
            currentCoordinate: locationState.coordinate,
            viewerID: appState.viewer?.id
        )
    }

    private func showOutOfRangeAlert(_ message: String) {
        outOfRangeAlertMessage = message.isEmpty ? "半径1km以内のグルームと掲示板のみ開けます。" : message
        isShowingOutOfRangeAlert = true
    }
}

private struct MapGlassHeader: View {
    var title: String
    var onClose: () -> Void

    var body: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(MegrumTheme.ink)
                    .frame(width: 42, height: 42)
                    .background(.regularMaterial, in: Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text(title)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .padding(.horizontal, 16)
                .frame(height: 42)
                .background(.regularMaterial, in: Capsule())

            Spacer()

            Color.clear
                .frame(width: 42, height: 42)
        }
    }
}

private struct MapStatusBadge: View {
    var message: String
    var isLoading: Bool

    var body: some View {
        HStack(spacing: 8) {
            if isLoading {
                ProgressView()
                    .controlSize(.small)
                    .tint(MegrumTheme.lavender)
            } else {
                Image(systemName: "location")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(MegrumTheme.lavender)
            }

            Text(message)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 38)
        .background(.regularMaterial, in: Capsule())
    }
}
