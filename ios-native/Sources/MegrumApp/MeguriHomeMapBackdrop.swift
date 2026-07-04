import MegrumCore
import MegrumDesign
import MapKit
import SwiftUI

struct MeguriHomeMapBackdrop: View {
    @Binding var cameraPosition: MapCameraPosition
    var selectedKind: MeguriMapKind
    var grooms: [GroomPost]
    var threads: [BoardThread]
    var currentCoordinate: MegrumLocationCoordinate?
    var viewerID: UUID?
    var subscriptionState: UserSubscriptionState
    var onSelectGroom: (GroomPost, UnitPoint) -> Void
    var onSelectThread: (BoardThread) -> Void
    var onTapCoordinate: (MegrumLocationCoordinate) -> Void
    var pendingCreationCoordinate: MegrumLocationCoordinate?
    var onCreateGroomAtPendingCoordinate: () -> Void
    var onCreateThreadAtPendingCoordinate: () -> Void
    var onCancelPendingCreationCoordinate: () -> Void
    var onViewportChange: (MKCoordinateRegion) -> Void = { _ in }

    /// 表示中スパン（クラスタリング粒度に使用）。カメラ操作の終了時に更新。
    @State private var visibleSpanLatitudeDelta = MeguriHomeMapCamera.focusedSpan.latitudeDelta
    /// クラスタ計算はコストがあるため、入力（マーカー・種別・スパン）が
    /// 変わった時だけ再計算してキャッシュする。ローディング表示などの
    /// 無関係な再描画で地図が固まらないようにする。
    @State private var displayedElements: [MeguriMapClusterBuilder.DisplayedElement] = []
    /// 統合/分解モーフの途中で新しい再計算が来た時に古いフェーズ2を破棄する。
    @State private var morphToken = UUID()

    private var clusterInputKey: String {
        let groomKey = (selectedKind == .all || selectedKind == .grooms)
            ? grooms.map { $0.id.uuidString }.joined(separator: ",")
            : ""
        let threadKey = (selectedKind == .all || selectedKind == .boards)
            ? threads.map { $0.id.uuidString }.joined(separator: ",")
            : ""
        return "\(groomKey)|\(threadKey)|\(visibleSpanLatitudeDelta)"
    }

    private func recomputeDisplayElements() {
        let visibleGrooms = (selectedKind == .all || selectedKind == .grooms) ? grooms : []
        let visibleThreads = (selectedKind == .all || selectedKind == .boards)
            ? threads.filter { $0.latitude != nil && $0.longitude != nil }
            : []
        let next = MeguriMapClusterBuilder.elements(
            grooms: visibleGrooms,
            threads: visibleThreads,
            spanLatitudeDelta: visibleSpanLatitudeDelta
        )
        applyElements(next)
    }

    /// 統合/分解のモーフ演出つきで表示マーカーを更新する。
    /// - 統合: 統合される側のマーカーが統合先の中間地点へ動いてから1つになる。
    /// - 分解: 分解後のマーカーがクラスタ位置に現れて、それぞれの位置へ散らばる。
    private func applyElements(_ next: [MeguriMapClusterBuilder.Element]) {
        guard next.map(\.id) != displayedElements.map(\.id) else {
            return
        }
        let token = UUID()
        morphToken = token
        guard !displayedElements.isEmpty else {
            displayedElements = next.map { MeguriMapClusterBuilder.DisplayedElement(element: $0, popsIn: true) }
            return
        }

        let previous = displayedElements

        // フェーズ1: これから統合される既存マーカーを、統合先の中間地点へ動かす。
        var gathering = previous
        var hasGatheringMove = false
        for target in next {
            guard case .cluster(let cluster) = target else {
                continue
            }
            let targetMemberIDs = Set(cluster.items.map(\.id))
            for index in gathering.indices where gathering[index].element.id != target.id {
                let memberIDs = Set(gathering[index].element.memberIDs)
                if !memberIDs.isEmpty, memberIDs.isSubset(of: targetMemberIDs) {
                    gathering[index].latitude = cluster.latitude
                    gathering[index].longitude = cluster.longitude
                    hasGatheringMove = true
                }
            }
        }

        let commitFinal = {
            guard morphToken == token else {
                return
            }
            // フェーズ2: 分解されたマーカーは元クラスタの位置に出して、
            // それぞれの位置へ散らばらせる。
            let previousByID = previous
            var start: [MeguriMapClusterBuilder.DisplayedElement] = []
            var needsScatter = false
            for element in next {
                let memberIDs = Set(element.memberIDs)
                if let parent = previousByID.first(where: { candidate in
                    candidate.element.id != element.id
                        && memberIDs.isSubset(of: Set(candidate.element.memberIDs))
                }) {
                    var displayed = MeguriMapClusterBuilder.DisplayedElement(element: element, popsIn: false)
                    displayed.latitude = parent.latitude
                    displayed.longitude = parent.longitude
                    start.append(displayed)
                    needsScatter = true
                } else {
                    let existed = previousByID.contains { $0.element.id == element.id }
                    let mergedHere = previousByID.contains { candidate in
                        candidate.element.id != element.id
                            && Set(candidate.element.memberIDs).isSubset(of: memberIDs)
                    }
                    start.append(
                        MeguriMapClusterBuilder.DisplayedElement(
                            element: element,
                            popsIn: !existed && !mergedHere
                        )
                    )
                }
            }
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                displayedElements = start
            }
            if needsScatter {
                Task { @MainActor in
                    await Task.yield()
                    guard morphToken == token else {
                        return
                    }
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.72)) {
                        displayedElements = displayedElements.map { displayed in
                            var next = displayed
                            next.latitude = displayed.element.displayLatitude
                            next.longitude = displayed.element.displayLongitude
                            return next
                        }
                    }
                }
            }
        }

        if hasGatheringMove {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
                displayedElements = gathering
            }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 330_000_000)
                commitFinal()
            }
        } else {
            commitFinal()
        }
    }

    var body: some View {
        GeometryReader { geometry in
            MapReader { proxy in
                ZStack(alignment: .topLeading) {
                    Map(position: $cameraPosition, interactionModes: [.pan, .zoom]) {
                        if let currentCoordinate {
                            MapCircle(
                                center: currentCoordinate.clLocationCoordinate,
                                radius: MeguriAccessPolicy.groomOpenRadiusMeters
                            )
                            .foregroundStyle(MegrumTheme.lavender.opacity(0.08))
                            .stroke(MegrumTheme.lavender.opacity(0.48), lineWidth: 1.8)

                            Annotation("現在地", coordinate: currentCoordinate.clLocationCoordinate) {
                                CurrentLocationDot()
                            }
                        }

                        ForEach(displayedElements) { displayed in
                            let coordinate = CLLocationCoordinate2D(
                                latitude: displayed.latitude,
                                longitude: displayed.longitude
                            )
                            switch displayed.element {
                            case .single(.groom(let groom)):
                                Annotation("", coordinate: coordinate) {
                                    Button {
                                        onSelectGroom(
                                            groom,
                                            sourceAnchor(for: groom, in: proxy, containerSize: geometry.size)
                                        )
                                    } label: {
                                        MeguriPinConditionalPopIn(popsIn: displayed.popsIn) {
                                            MeguriFloatingMotion(seed: groom.id.hashValue) {
                                                GroomMapPin(
                                                    groom: groom,
                                                    isOutOfRange: !MeguriAccessPolicy.canOpenGroom(
                                                        groom,
                                                        currentCoordinate: currentCoordinate,
                                                        viewerID: viewerID
                                                    )
                                                )
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }

                            case .single(.thread(let thread)):
                                Annotation(thread.title, coordinate: coordinate) {
                                    Button {
                                        onSelectThread(thread)
                                    } label: {
                                        MeguriPinConditionalPopIn(popsIn: displayed.popsIn) {
                                            MeguriFloatingMotion(seed: thread.id.hashValue) {
                                                BoardMapPin(
                                                    thread: thread,
                                                    isOutOfRange: !MeguriAccessPolicy.canOpenBoard(
                                                        thread,
                                                        currentCoordinate: currentCoordinate,
                                                        viewerID: viewerID,
                                                        subscriptionState: subscriptionState
                                                    )
                                                )
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }

                            case .cluster(let cluster):
                                Annotation("", coordinate: coordinate) {
                                    Button {
                                        zoomToSplit(cluster)
                                    } label: {
                                        MeguriPinConditionalPopIn(popsIn: displayed.popsIn) {
                                            MeguriFloatingMotion(seed: cluster.id.hashValue) {
                                                MeguriClusterPin(cluster: cluster)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                    }
                    .mapStyle(.standard(elevation: .flat, emphasis: .muted))
                    .onMapCameraChange(frequency: .onEnd) { context in
                        visibleSpanLatitudeDelta = context.region.span.latitudeDelta
                        onViewportChange(context.region)
                    }
                    .onAppear {
                        recomputeDisplayElements()
                    }
                    .onChange(of: clusterInputKey) { _, _ in
                        recomputeDisplayElements()
                    }
                    .simultaneousGesture(
                        SpatialTapGesture()
                            .onEnded { value in
                                guard pendingCreationCoordinate == nil else {
                                    return
                                }
                                guard !isAnnotationTap(
                                    at: value.location,
                                    in: proxy
                                ) else {
                                    return
                                }
                                guard let coordinate = proxy.convert(value.location, from: .local) else {
                                    return
                                }
                                onTapCoordinate(
                                    MegrumLocationCoordinate(
                                        latitude: coordinate.latitude,
                                        longitude: coordinate.longitude
                                    )
                                )
                            }
                    )
                    .overlay {
                        LinearGradient(
                            colors: [.white.opacity(0.80), .white.opacity(0.28), .white.opacity(0.04)],
                            startPoint: .top,
                            endPoint: .center
                        )
                        .allowsHitTesting(false)
                    }

                    if let pendingCreationCoordinate,
                       let point = proxy.convert(pendingCreationCoordinate.clLocationCoordinate, to: .local) {
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture(perform: onCancelPendingCreationCoordinate)
                            .transition(.opacity)
                            .zIndex(1)

                        MeguriMapCreationDropPin()
                            .id(pendingCreationCoordinate.creationPromptID)
                            .frame(width: 68, height: 72, alignment: .bottom)
                            .position(x: point.x, y: point.y - 36)
                            .transition(.opacity)
                            .zIndex(2)

                        let promptPosition = MeguriMapCreationPromptLayout.position(
                            for: point,
                            in: geometry.size
                        )
                        let promptPlacement = MeguriMapCreationPromptLayout.placement(
                            for: point,
                            in: geometry.size
                        )
                        let pointerOffset = MeguriMapCreationPromptLayout.pointerOffset(
                            for: point,
                            in: geometry.size
                        )

                        MeguriMapCreationPromptCallout(
                            placement: promptPlacement,
                            pointerOffset: pointerOffset,
                            onCreateGroom: onCreateGroomAtPendingCoordinate,
                            onCreateThread: onCreateThreadAtPendingCoordinate
                        )
                        .id(pendingCreationCoordinate.creationPromptID)
                        .position(x: promptPosition.x, y: promptPosition.y)
                        .transition(.opacity)
                        .zIndex(3)
                    }
                }
            }
        }
    }
}

private extension MeguriHomeMapBackdrop {
    func sourceAnchor(for groom: GroomPost, in proxy: MapProxy, containerSize: CGSize) -> UnitPoint {
        guard containerSize.width > 0,
              containerSize.height > 0,
              let point = proxy.convert(groom.coordinate, to: .local)
        else {
            return .center
        }
        return UnitPoint(
            x: min(max(point.x / containerSize.width, 0), 1),
            y: min(max(point.y / containerSize.height, 0), 1)
        )
    }

    /// クラスタタップ：数個程度に分解されるスパンまで、中間地点中心に拡大する。
    func zoomToSplit(_ cluster: MeguriMapClusterBuilder.Cluster) {
        let targetSpan = MeguriMapClusterBuilder.splitSpan(
            for: cluster,
            currentSpanLatitudeDelta: visibleSpanLatitudeDelta
        )
        withAnimation(.smooth(duration: 0.34)) {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(
                        latitude: cluster.latitude,
                        longitude: cluster.longitude
                    ),
                    span: MKCoordinateSpan(latitudeDelta: targetSpan, longitudeDelta: targetSpan)
                )
            )
        }
    }

    func isAnnotationTap(at location: CGPoint, in proxy: MapProxy) -> Bool {
        for displayed in displayedElements {
            let coordinate = CLLocationCoordinate2D(
                latitude: displayed.latitude,
                longitude: displayed.longitude
            )
            let hitWidth: CGFloat
            let hitHeight: CGFloat
            switch displayed.element {
            case .single(.groom):
                hitWidth = 54
                hitHeight = 64
            case .single(.thread):
                hitWidth = 58
                hitHeight = 66
            case .cluster:
                hitWidth = 58
                hitHeight = 62
            }
            guard let point = proxy.convert(coordinate, to: .local) else {
                continue
            }
            if abs(location.x - point.x) <= hitWidth, abs(location.y - point.y) <= hitHeight {
                return true
            }
        }
        return false
    }
}

/// popsIn が true の時だけポップイン演出を挟む（モーフで移動してくる
/// マーカーは位置アニメーションに任せる）。
struct MeguriPinConditionalPopIn<Content: View>: View {
    var popsIn: Bool
    @ViewBuilder var content: Content

    var body: some View {
        if popsIn {
            MeguriPinPopIn {
                content
            }
        } else {
            content
        }
    }
}
