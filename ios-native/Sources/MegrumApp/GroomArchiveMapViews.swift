import CoreLocation
import MapKit
import MegrumCore
import MegrumDesign
import SwiftUI

struct GroomArchiveMap: View {
    @Binding var cameraPosition: MapCameraPosition
    var grooms: [GroomPost]
    var currentCoordinate: MegrumLocationCoordinate?
    var onSelect: (GroomPost) -> Void
    /// iter1226.459：単体グルームピンをめぐりホームと同じ標準zoomのsourceにする（iOS18+）。
    var groomZoomNamespace: Namespace.ID? = nil

    /// めぐりホーム地図と同じ統合/分解モーフを使う（共通コントローラ）。
    @State private var morphController = MeguriClusterMorphController()
    @State private var visibleSpanLatitudeDelta: Double = 0.05
    /// iter1226.459：カメラ移動ごとにoverlayピンの位置を追従させるためのtick。
    @State private var cameraUpdateTick = 0

    /// iter1226.459：iOS18+かつnamespaceありなら、単体グルームピンの見た目はoverlay側
    /// （常設matchedTransitionSource）に出し、Annotation側は透明タップ領域にする。
    private var usesOverlayGroomPins: Bool {
        #if canImport(UIKit)
        if #available(iOS 18.0, *), groomZoomNamespace != nil {
            return true
        }
        #endif
        return false
    }

    var body: some View {
        GeometryReader { geometry in
            MapReader { proxy in
                Map(position: $cameraPosition, interactionModes: [.pan, .zoom]) {
                    if let currentCoordinate {
                        Annotation("現在地", coordinate: currentCoordinate.clLocationCoordinate) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 15, weight: .heavy))
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                                .background(MegrumTheme.lavender, in: Circle())
                                .overlay(Circle().stroke(.white, lineWidth: 3))
                                .shadow(color: MegrumTheme.ink.opacity(0.22), radius: 10, y: 5)
                        }
                    }

                    ForEach(morphController.displayedElements) { displayed in
                        let coordinate = CLLocationCoordinate2D(
                            latitude: displayed.latitude,
                            longitude: displayed.longitude
                        )
                        switch displayed.element {
                        case .single(.groom(let groom)):
                            Annotation("", coordinate: coordinate) {
                                Button {
                                    onSelect(groom)
                                } label: {
                                    if usesOverlayGroomPins {
                                        // iter1226.459：見た目はoverlay側の常設ピン。ここはタップ領域だけ。
                                        Color.clear
                                            .frame(width: 62, height: 84)
                                            .contentShape(Rectangle())
                                    } else {
                                        MeguriPinConditionalPopIn(popsIn: displayed.popsIn) {
                                            GroomArchiveMapPin(groom: groom)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                                .opacity(displayed.opacity)
                                .accessibilityLabel("過去のグルーム")
                            }
                        case .cluster(let cluster):
                            Annotation("", coordinate: coordinate) {
                                Button {
                                    zoomToSplit(cluster, containerSize: geometry.size)
                                } label: {
                                    MeguriPinConditionalPopIn(popsIn: displayed.popsIn) {
                                        MeguriFloatingMotion(seed: cluster.id.hashValue) {
                                            MeguriClusterPin(cluster: cluster)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                                .opacity(displayed.opacity)
                            }
                        case .single(.thread):
                            // アーカイブはグルームのみ
                            EmptyMapContent()
                        }
                    }
                }
                .mapStyle(MeguriMapVisualStyle.quietStandard)
                .overlay {
                    groomZoomSourcePinsOverlay(proxy: proxy)
                }
                .overlay {
                    MeguriMapBrandToneOverlay(
                        topWhiteOpacity: 0.72,
                        middleWhiteOpacity: 0.16,
                        bottomWhiteOpacity: 0.04
                    )
                }
                .onMapCameraChange(frequency: .continuous) { _ in
                    // iter1226.459：overlayの常設グルームピンをパン/ズームに追従させる。
                    if usesOverlayGroomPins {
                        cameraUpdateTick &+= 1
                    }
                }
                .onMapCameraChange(frequency: .onEnd) { context in
                    visibleSpanLatitudeDelta = context.region.span.latitudeDelta
                    recomputeDisplayElements()
                }
                .onChange(of: grooms.map(\.id), initial: true) { _, _ in
                    recomputeDisplayElements()
                }
            }
        }
    }

    /// iter1226.459：表示中の単体グルームピンの画面位置に、常設の可視ピン
    /// （matchedTransitionSource付き）を重ねる。めぐりホームと同じ「source常設・タップ即提示」。
    @ViewBuilder
    private func groomZoomSourcePinsOverlay(proxy: MapProxy) -> some View {
        #if canImport(UIKit)
        if #available(iOS 18.0, *), let groomZoomNamespace {
            let _ = cameraUpdateTick
            ForEach(morphController.displayedElements) { displayed in
                if case .single(.groom(let groom)) = displayed.element,
                   let point = proxy.convert(
                       CLLocationCoordinate2D(latitude: displayed.latitude, longitude: displayed.longitude),
                       to: .local
                   ) {
                    MeguriPinConditionalPopIn(popsIn: displayed.popsIn) {
                        GroomArchiveMapPin(groom: groom)
                    }
                    .opacity(displayed.opacity)
                    .matchedTransitionSource(id: GroomMapZoomSourceID.groom(groom.id), in: groomZoomNamespace)
                    .position(point)
                    .allowsHitTesting(false)
                }
            }
        }
        #endif
    }

    private func recomputeDisplayElements() {
        morphController.apply(
            MeguriMapClusterBuilder.elements(
                grooms: grooms,
                threads: [],
                spanLatitudeDelta: visibleSpanLatitudeDelta
            )
        )
    }

    private func zoomToSplit(_ cluster: MeguriMapClusterBuilder.Cluster, containerSize: CGSize) {
        MegrumHaptics.buttonTap()
        let targetSpan = MeguriMapClusterBuilder.splitSpan(
            for: cluster,
            currentSpanLatitudeDelta: visibleSpanLatitudeDelta
        ) * 0.9
        let aspect = containerSize.width > 0 && containerSize.height > 0
            ? max(containerSize.height / containerSize.width, 1)
            : 2.2
        withAnimation(.smooth(duration: 0.34)) {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(
                        latitude: cluster.latitude,
                        longitude: cluster.longitude
                    ),
                    span: MKCoordinateSpan(
                        latitudeDelta: targetSpan,
                        longitudeDelta: targetSpan / aspect
                    )
                )
            )
        }
        visibleSpanLatitudeDelta = targetSpan
        recomputeDisplayElements()
    }
}

private struct GroomArchiveMapPin: View {
    var groom: GroomPost

    var body: some View {
        MeguriPinPopIn {
            MeguriFloatingMotion(seed: groom.id.hashValue) {
                VStack(spacing: 4) {
                    GroomMapPin(groom: groom, isOutOfRange: false)

                    Text(groom.createdAt.formatted(.dateTime.month().day()))
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.white.opacity(0.92), in: Capsule())
                        .shadow(color: MegrumTheme.ink.opacity(0.12), radius: 6, y: 3)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("過去のグルーム")
    }
}

enum GroomArchiveMapRegion {
    static func region(
        for grooms: [GroomPost],
        currentCoordinate: MegrumLocationCoordinate?
    ) -> MKCoordinateRegion {
        var rect = MKMapRect.null

        if let currentCoordinate {
            rect = rect.union(rectAround(currentCoordinate.clLocationCoordinate, radiusMeters: 300))
        }

        for groom in grooms {
            rect = rect.union(rectAround(groom.coordinate, radiusMeters: 180))
        }

        guard !rect.isNull else {
            return MKCoordinateRegion(
                center: currentCoordinate?.clLocationCoordinate
                    ?? CLLocationCoordinate2D(latitude: 35.681236, longitude: 139.767125),
                span: MKCoordinateSpan(latitudeDelta: 0.018, longitudeDelta: 0.018)
            )
        }

        let padded = rect.insetBy(dx: -rect.size.width * 0.24, dy: -rect.size.height * 0.24)
        let region = MKCoordinateRegion(padded)
        return MKCoordinateRegion(
            center: region.center,
            span: MKCoordinateSpan(
                latitudeDelta: min(max(region.span.latitudeDelta, 0.018), 0.22),
                longitudeDelta: min(max(region.span.longitudeDelta * 1.28, 0.018), 0.22)
            )
        )
    }

    static func focusedRegion(for groom: GroomPost) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: groom.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.0065, longitudeDelta: 0.0065)
        )
    }

    private static func rectAround(
        _ coordinate: CLLocationCoordinate2D,
        radiusMeters: CLLocationDistance
    ) -> MKMapRect {
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
}
