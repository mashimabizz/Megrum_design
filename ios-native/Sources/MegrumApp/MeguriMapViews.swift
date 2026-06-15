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
            1_000
        case .boards:
            3_000
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
                                selectedThread = annotation.thread
                            } label: {
                                BoardMapPin(thread: annotation.thread)
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
        if kind == .boards, boardScope != .nearby3km {
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
            return "都道府県内の位置つきスレッドを表示中"
        }
        if kind == .grooms, rangeCircle != nil {
            return "現在地周辺のグルームを表示中。1km外は閲覧できません"
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
            withAnimation(.smooth(duration: 0.2)) {
                mapNotice = MeguriAccessPolicy.groomAccessMessage(
                    groom,
                    currentCoordinate: locationState.coordinate,
                    viewerID: appState.viewer?.id
                )
            }
            locationState.requestCurrentLocation()
            return
        }
        withAnimation(.smooth(duration: 0.2)) {
            mapNotice = groomRangeNotice(groom)
        }
    }

    private func isGroomOutOfRange(_ groom: GroomPost) -> Bool {
        !MeguriAccessPolicy.canOpenGroom(
            groom,
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

    private func distanceFromCurrentLocation(to groom: GroomPost) -> CLLocationDistance? {
        MeguriAccessPolicy.distanceMeters(from: locationState.coordinate, to: groom)
    }

    private func groomRangeNotice(_ groom: GroomPost) -> String {
        MeguriAccessPolicy.groomAccessMessage(
            groom,
            currentCoordinate: locationState.coordinate,
            viewerID: appState.viewer?.id
        )
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

private struct GroomMapPin: View {
    var groom: GroomPost
    var isOutOfRange: Bool

    var body: some View {
        VStack(spacing: 0) {
            GroomThumbnailCircle(url: groom.imageURL, size: 58)
                .overlay(Circle().stroke(.white, lineWidth: 3))
                .overlay(alignment: .bottomTrailing) {
                    if isOutOfRange {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(MegrumTheme.ink)
                            .frame(width: 21, height: 21)
                            .background(.regularMaterial, in: Circle())
                            .offset(x: 3, y: 3)
                    }
                }
                .shadow(color: MegrumTheme.ink.opacity(0.22), radius: 12, y: 8)
                .saturation(isOutOfRange ? 0.25 : 1)
                .opacity(isOutOfRange ? 0.68 : 1)

            Triangle()
                .fill(.white)
                .frame(width: 14, height: 8)
                .offset(y: -1)
        }
        .accessibilityLabel(isOutOfRange ? "1km圏外のグルーム" : "グルーム")
    }
}

private struct BoardMapPin: View {
    var thread: BoardThread

    var body: some View {
        Text(thread.title)
            .font(.system(size: 12, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .lineLimit(1)
            .padding(.horizontal, 12)
            .frame(height: 34)
            .background(MegrumTheme.lavender, in: Capsule())
            .overlay(alignment: .bottom) {
                Triangle()
                    .fill(MegrumTheme.lavender)
                    .frame(width: 14, height: 8)
                    .offset(y: 6)
            }
            .shadow(color: MegrumTheme.ink.opacity(0.2), radius: 12, y: 7)
            .accessibilityLabel("掲示板 \(thread.title)")
    }
}

private struct GroomMapDetailSheet: View {
    var groom: GroomPost

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("グルーム")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            AsyncImage(url: groom.imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.white.opacity(0.86))
                        .overlay {
                            GroomImageFailureView(message: "画像を読み込めませんでした", foregroundColor: MegrumTheme.ink)
                        }
                default:
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [MegrumTheme.sky, MegrumTheme.pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay {
                            ProgressView()
                                .tint(.white)
                        }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .padding(20)
        .background(MegrumTheme.canvas)
    }
}

struct GroomThumbnailCircle: View {
    var url: URL
    var size: CGFloat

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                GroomImageFailureView(message: nil, foregroundColor: .white)
            default:
                ProgressView()
                    .tint(.white)
            }
        }
        .frame(width: size, height: size)
        .background(
            LinearGradient(
                colors: [MegrumTheme.sky, MegrumTheme.pink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(Circle())
        .contentShape(Circle())
    }
}

struct GroomImageFailureView: View {
    var message: String?
    var foregroundColor: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "photo")
                .font(.system(size: message == nil ? 20 : 30, weight: .bold))

            if let message {
                Text(message)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
            }
        }
        .foregroundStyle(foregroundColor.opacity(0.78))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct BoardMapAnnotation: Identifiable {
    var thread: BoardThread
    var coordinate: CLLocationCoordinate2D

    var id: UUID { thread.id }

    init?(thread: BoardThread) {
        guard let latitude = thread.latitude, let longitude = thread.longitude else {
            return nil
        }
        self.thread = thread
        self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

extension GroomPost {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

private extension MeguriMapKind {
    func initialCenter(userCoordinate: MegrumLocationCoordinate?, grooms: [GroomPost], threads: [BoardThread]) -> CLLocationCoordinate2D {
        if let userCoordinate {
            return userCoordinate.clLocationCoordinate
        }

        switch self {
        case .grooms:
            return grooms.first?.coordinate ?? Self.fallbackCenter
        case .boards:
            if let thread = threads.first(where: { $0.latitude != nil && $0.longitude != nil }),
               let latitude = thread.latitude,
               let longitude = thread.longitude {
                return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            }
            return Self.fallbackCenter
        }
    }

    func visibleRegion(
        userCoordinate: MegrumLocationCoordinate?,
        grooms: [GroomPost],
        threads: [BoardThread],
        boardScope: BoardThread.Audience
    ) -> MKCoordinateRegion {
        let userLocation = userCoordinate?.clLocationCoordinate
        var rect = MKMapRect.null

        if let userLocation, shouldCenterRangeCircle(boardScope: boardScope) {
            rect = rect.union(.meguriRect(centeredAt: userLocation, radiusMeters: radiusMeters))
        } else if let userLocation, annotationCoordinates(grooms: grooms, threads: threads).isEmpty {
            rect = rect.union(.meguriRect(centeredAt: userLocation, radiusMeters: 220))
        }

        for coordinate in annotationCoordinates(grooms: grooms, threads: threads) where coordinate.isMeguriValid {
            rect = rect.union(.meguriRect(centeredAt: coordinate, radiusMeters: 150))
        }

        guard !rect.isNull else {
            return MKCoordinateRegion(
                center: initialCenter(userCoordinate: userCoordinate, grooms: grooms, threads: threads),
                span: regionSpan
            )
        }

        return MKCoordinateRegion(rect.meguriPadded())
            .meguriClamped(minimum: minimumRegionSpan, maximum: maximumRegionSpan)
    }

    private func annotationCoordinates(grooms: [GroomPost], threads: [BoardThread]) -> [CLLocationCoordinate2D] {
        switch self {
        case .grooms:
            return grooms.map(\.coordinate)
        case .boards:
            return threads.compactMap { thread in
                guard let latitude = thread.latitude, let longitude = thread.longitude else {
                    return nil
                }
                return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            }
        }
    }

    private func shouldCenterRangeCircle(boardScope: BoardThread.Audience) -> Bool {
        switch self {
        case .grooms:
            return true
        case .boards:
            return boardScope == .nearby3km
        }
    }

    private var minimumRegionSpan: MKCoordinateSpan {
        switch self {
        case .grooms:
            MKCoordinateSpan(latitudeDelta: 0.018, longitudeDelta: 0.018)
        case .boards:
            MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
        }
    }

    private var maximumRegionSpan: MKCoordinateSpan {
        switch self {
        case .grooms:
            MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
        case .boards:
            MKCoordinateSpan(latitudeDelta: 0.16, longitudeDelta: 0.16)
        }
    }

    static var fallbackCenter: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: 35.681236, longitude: 139.767125)
    }
}

private extension MKMapRect {
    static func meguriRect(centeredAt coordinate: CLLocationCoordinate2D, radiusMeters: CLLocationDistance) -> MKMapRect {
        let point = MKMapPoint(coordinate)
        let metersPerMapPoint = max(MKMetersPerMapPointAtLatitude(coordinate.latitude), 0.000_001)
        let radiusMapPoints = max(radiusMeters / metersPerMapPoint, 1)
        return MKMapRect(
            x: point.x - radiusMapPoints,
            y: point.y - radiusMapPoints,
            width: radiusMapPoints * 2,
            height: radiusMapPoints * 2
        )
    }

    func meguriPadded(fraction: Double = 0.24) -> MKMapRect {
        insetBy(dx: -size.width * fraction, dy: -size.height * fraction)
    }
}

private extension MKCoordinateRegion {
    func meguriClamped(minimum: MKCoordinateSpan, maximum: MKCoordinateSpan) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(
                latitudeDelta: span.latitudeDelta.meguriClamped(minimum.latitudeDelta, maximum.latitudeDelta),
                longitudeDelta: span.longitudeDelta.meguriClamped(minimum.longitudeDelta, maximum.longitudeDelta)
            )
        )
    }
}

private extension CLLocationCoordinate2D {
    var isMeguriValid: Bool {
        CLLocationCoordinate2DIsValid(self)
    }
}

private extension Double {
    func meguriClamped(_ lowerBound: Double, _ upperBound: Double) -> Double {
        min(max(self, lowerBound), upperBound)
    }
}

extension CLLocationDistance {
    var meguriDistanceText: String {
        if self < 1_000 {
            return "\(Int(rounded()))m"
        }
        return String(format: "%.1fkm", self / 1_000)
    }
}
