import MegrumCore
import MegrumDesign
import MapKit
import SwiftUI

struct MeguriScreen: View {
    @ObservedObject var appState: MegrumAppState
    @StateObject private var locationState = MegrumLocationState()
    @State private var selectedThread: BoardThread?
    @State private var activeMap: MeguriMapKind?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                ScreenTitle(title: "グルーム", subtitle: "近くの投稿と掲示板")

                VStack(alignment: .leading, spacing: 14) {
                    SectionHeader(title: "グルーム", actionTitle: "地図で見る") {
                        activeMap = .grooms
                    }
                    GroomStrip(grooms: appState.grooms)
                }

                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        SectionHeader(title: "掲示板", actionTitle: "地図で見る") {
                            activeMap = .boards
                        }
                        if appState.isLoadingMeguri {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }

                    ForEach(appState.threads) { thread in
                        Button {
                            selectedThread = thread
                        } label: {
                            BoardThreadCard(thread: thread)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 112)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .megrumHiddenNavigationBar()
        .refreshable {
            await appState.loadMeguriFeed(
                latitude: locationState.coordinate?.latitude,
                longitude: locationState.coordinate?.longitude
            )
        }
        .task {
            locationState.requestCurrentLocation()
        }
        .onReceive(locationState.$coordinate.compactMap { $0 }) { coordinate in
            Task {
                await appState.loadMeguriFeed(latitude: coordinate.latitude, longitude: coordinate.longitude)
            }
        }
        .sheet(item: $selectedThread) { thread in
            NavigationStack {
                BoardThreadDetailScreen(appState: appState, thread: thread)
            }
        }
        .modifier(MeguriMapPresentationModifier(activeMap: $activeMap, appState: appState, locationState: locationState))
        .safeAreaInset(edge: .bottom, alignment: .trailing) {
            Button {
            } label: {
                Label("スレッドを立てる", systemImage: "plus")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .padding(.horizontal, 18)
                    .frame(height: 54)
                    .background(MegrumTheme.lavender, in: Capsule())
                    .foregroundStyle(.white)
                    .shadow(color: MegrumTheme.lavender.opacity(0.32), radius: 16, y: 8)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 20)
            .padding(.bottom, 10)
        }
    }
}

private struct MeguriMapPresentationModifier: ViewModifier {
    @Binding var activeMap: MeguriMapKind?
    @ObservedObject var appState: MegrumAppState
    @ObservedObject var locationState: MegrumLocationState

    func body(content: Content) -> some View {
        #if os(iOS)
        content.fullScreenCover(item: $activeMap) { kind in
            NavigationStack {
                MeguriMapScreen(kind: kind, appState: appState, locationState: locationState)
            }
        }
        #else
        content.sheet(item: $activeMap) { kind in
            NavigationStack {
                MeguriMapScreen(kind: kind, appState: appState, locationState: locationState)
            }
        }
        #endif
    }
}

private enum MeguriMapKind: String, Identifiable {
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
    @Environment(\.dismiss) private var dismiss
    @State private var cameraPosition: MapCameraPosition
    @State private var selectedGroom: GroomPost?
    @State private var selectedThread: BoardThread?

    init(kind: MeguriMapKind, appState: MegrumAppState, locationState: MegrumLocationState) {
        self.kind = kind
        self.appState = appState
        self.locationState = locationState
        _cameraPosition = State(initialValue: .region(MKCoordinateRegion(center: kind.initialCenter(userCoordinate: locationState.coordinate, grooms: appState.grooms, threads: appState.threads), span: kind.regionSpan)))
    }

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $cameraPosition, interactionModes: [.pan, .zoom, .rotate]) {
                MapCircle(center: centerCoordinate, radius: kind.radiusMeters)
                    .foregroundStyle(MegrumTheme.lavender.opacity(0.08))
                    .stroke(MegrumTheme.lavender.opacity(0.42), lineWidth: 1.5)

                switch kind {
                case .grooms:
                    ForEach(appState.grooms) { groom in
                        Annotation("グルーム", coordinate: groom.coordinate) {
                            Button {
                                selectedGroom = groom
                            } label: {
                                GroomMapPin(groom: groom)
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
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            .ignoresSafeArea()

            MapGlassHeader(title: kind.title) {
                dismiss()
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
        }
        .task {
            locationState.requestCurrentLocation()
            await appState.loadMeguriFeed(
                latitude: locationState.coordinate?.latitude,
                longitude: locationState.coordinate?.longitude
            )
            withAnimation(.smooth(duration: 0.28)) {
                cameraPosition = .region(MKCoordinateRegion(center: centerCoordinate, span: kind.regionSpan))
            }
        }
        .onReceive(locationState.$coordinate.compactMap { $0 }) { coordinate in
            Task {
                await appState.loadMeguriFeed(latitude: coordinate.latitude, longitude: coordinate.longitude)
            }
            withAnimation(.smooth(duration: 0.28)) {
                cameraPosition = .region(MKCoordinateRegion(center: coordinate.clLocationCoordinate, span: kind.regionSpan))
            }
        }
        .sheet(item: $selectedGroom) { groom in
            GroomMapDetailSheet(groom: groom)
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedThread) { thread in
            NavigationStack {
                BoardThreadDetailScreen(appState: appState, thread: thread)
            }
        }
    }

    private var centerCoordinate: CLLocationCoordinate2D {
        kind.initialCenter(userCoordinate: locationState.coordinate, grooms: appState.grooms, threads: appState.threads)
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

private struct GroomMapPin: View {
    var groom: GroomPost

    var body: some View {
        VStack(spacing: 0) {
            AsyncImage(url: groom.imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    LinearGradient(
                        colors: [MegrumTheme.sky, MegrumTheme.pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .overlay {
                        Image(systemName: "photo")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .frame(width: 58, height: 58)
            .clipShape(Circle())
            .overlay(Circle().stroke(.white, lineWidth: 3))
            .shadow(color: MegrumTheme.ink.opacity(0.22), radius: 12, y: 8)

            Triangle()
                .fill(.white)
                .frame(width: 14, height: 8)
                .offset(y: -1)
        }
        .accessibilityLabel("グルーム")
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

private struct BoardThreadDetailScreen: View {
    @ObservedObject var appState: MegrumAppState
    var thread: BoardThread
    @Environment(\.dismiss) private var dismiss
    @State private var draftReply = ""

    private var replies: [BoardReply] {
        appState.boardReplies(for: thread.id)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    BoardThreadCard(thread: thread)

                    HStack {
                        Text("返信")
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink)

                        if appState.loadingBoardRepliesThreadID == thread.id {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }

                    ForEach(replies) { reply in
                        BoardReplyBubble(
                            reply: reply,
                            isMine: reply.authorID == appState.viewer?.id
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 22)
            }

            BoardReplyInput(
                text: $draftReply,
                isSending: appState.sendingBoardReplyThreadID == thread.id
            ) {
                Task {
                    let sent = await appState.sendBoardReply(threadID: thread.id, body: draftReply, scope: thread.audience)
                    if sent {
                        draftReply = ""
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .navigationTitle("掲示板")
        .megrumInlineNavigationTitle()
        .task {
            await appState.loadBoardReplies(threadID: thread.id, scope: thread.audience)
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
    }
}

private struct BoardReplyBubble: View {
    var reply: BoardReply
    var isMine: Bool

    var body: some View {
        VStack(alignment: isMine ? .trailing : .leading, spacing: 4) {
            Text(reply.status == .deleted ? "削除済みです" : reply.body)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(isMine ? .white : MegrumTheme.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    isMine ? AnyShapeStyle(MegrumTheme.lavender) : AnyShapeStyle(.white.opacity(0.9)),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )

            Text(reply.createdAt.formatted(date: .omitted, time: .shortened))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: isMine ? .trailing : .leading)
    }
}

private struct BoardReplyInput: View {
    @Binding var text: String
    var isSending: Bool
    var onSend: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            TextField("返信を入力", text: $text, axis: .vertical)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .lineLimit(1...4)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            Button(action: onSend) {
                Group {
                    if isSending {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 17, weight: .heavy))
                    }
                }
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(MegrumTheme.lavender, in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
            .opacity(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
        }
    }
}

private struct SectionHeader: View {
    var title: String
    var actionTitle: String
    var action: () -> Void = {}

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 25, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Spacer()

            Button(actionTitle, action: action)
            .font(.system(size: 14, weight: .heavy, design: .rounded))
            .foregroundStyle(MegrumTheme.lavender)
        }
    }
}

private struct GroomStrip: View {
    var grooms: [GroomPost]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(grooms) { groom in
                    VStack(spacing: 8) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [MegrumTheme.sky, MegrumTheme.pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 72, height: 72)
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(.white)
                            }

                        Text("1km圏内")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                    }
                    .id(groom.id)
                }
            }
            .padding(.vertical, 2)
        }
    }
}

private struct BoardThreadCard: View {
    var thread: BoardThread

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(scopeText)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(MegrumTheme.lavender.opacity(0.12), in: Capsule())

                Spacer()
            }

            Text(thread.title)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Text(thread.body)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .lineLimit(2)
        }
        .padding(16)
        .background(.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: MegrumTheme.ink.opacity(0.06), radius: 14, y: 7)
    }

    private var scopeText: String {
        switch thread.audience {
        case .nearby3km:
            "3km圏内"
        case .samePrefecture:
            thread.prefecture ?? "都道府県"
        case .sameSpot:
            "スポット"
        case .global:
            "全体"
        }
    }
}

private struct BoardMapAnnotation: Identifiable {
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

private extension GroomPost {
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

    static var fallbackCenter: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: 35.681236, longitude: 139.767125)
    }
}
