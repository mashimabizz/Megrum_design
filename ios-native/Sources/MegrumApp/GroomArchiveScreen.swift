import CoreLocation
import MapKit
import MegrumCore
import MegrumDesign
import SwiftUI

struct GroomArchiveScreen: View {
    @ObservedObject var appState: MegrumAppState
    var currentCoordinate: MegrumLocationCoordinate?
    @Environment(\.dismiss) private var dismiss
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedGroom: GroomPost?

    private var archivedGrooms: [GroomPost] {
        GroomArchiveOrdering.sorted(appState.ownGroomArchive)
    }

    var body: some View {
        ZStack(alignment: .top) {
            GroomArchiveMap(
                cameraPosition: $cameraPosition,
                grooms: archivedGrooms,
                currentCoordinate: currentCoordinate,
                onSelect: { selectedGroom = $0 }
            )
            .ignoresSafeArea()

            GroomArchiveHeader(
                count: archivedGrooms.count,
                isLoading: appState.isLoadingGroomArchive,
                onClose: { dismiss() }
            )
            .padding(.horizontal, 18)
            .padding(.top, 14)

            if archivedGrooms.isEmpty, !appState.isLoadingGroomArchive {
                GroomArchiveEmptyState()
                    .padding(.horizontal, 28)
                    .frame(maxHeight: .infinity)
            }

            VStack {
                Spacer()
                GroomArchiveThumbnailRail(
                    grooms: archivedGrooms,
                    selectedGroomID: selectedGroom?.id,
                    onSelect: { selectedGroom = $0 }
                )
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
            }
        }
        .background(MegrumTheme.canvas)
        .task {
            await appState.loadGroomArchive()
            updateCameraPosition()
        }
        .onChange(of: archivedGrooms) { _, _ in
            updateCameraPosition()
        }
        #if os(iOS)
        .fullScreenCover(item: $selectedGroom) { groom in
            GroomArchiveStoryScreen(
                grooms: archivedGrooms,
                initialGroom: groom,
                appState: appState
            )
        }
        #else
        .sheet(item: $selectedGroom) { groom in
            GroomArchiveStoryScreen(
                grooms: archivedGrooms,
                initialGroom: groom,
                appState: appState
            )
        }
        #endif
    }

    private func updateCameraPosition() {
        cameraPosition = .region(
            GroomArchiveMapRegion.region(
                for: archivedGrooms,
                currentCoordinate: currentCoordinate
            )
        )
    }
}

private struct GroomArchiveMap: View {
    @Binding var cameraPosition: MapCameraPosition
    var grooms: [GroomPost]
    var currentCoordinate: MegrumLocationCoordinate?
    var onSelect: (GroomPost) -> Void

    var body: some View {
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

            ForEach(grooms) { groom in
                Annotation("過去のグルーム", coordinate: groom.coordinate) {
                    Button {
                        onSelect(groom)
                    } label: {
                        GroomArchiveMapPin(groom: groom)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .mapStyle(.standard(elevation: .flat, emphasis: .muted))
        .overlay {
            LinearGradient(
                colors: [.white.opacity(0.72), .white.opacity(0.16), .white.opacity(0.04)],
                startPoint: .top,
                endPoint: .center
            )
            .allowsHitTesting(false)
        }
    }
}

private struct GroomArchiveMapPin: View {
    var groom: GroomPost

    var body: some View {
        VStack(spacing: 0) {
            GroomThumbnailCircle(url: groom.imageURL, size: 62)
                .overlay {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [MegrumTheme.lavender, MegrumTheme.pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 4
                        )
                }
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(MegrumTheme.ink, in: Circle())
                        .offset(x: 4, y: 4)
                }
                .shadow(color: MegrumTheme.ink.opacity(0.22), radius: 12, y: 8)

            GroomArchiveTriangle()
                .fill(MegrumTheme.lavender)
                .frame(width: 14, height: 8)
                .offset(y: -1)
        }
        .accessibilityLabel("過去のグルーム")
    }
}

private struct GroomArchiveHeader: View {
    var count: Int
    var isLoading: Bool
    var onClose: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onClose) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(MegrumTheme.ink)
                    .frame(width: 46, height: 46)
                    .background(.regularMaterial, in: Circle())
                    .overlay(Circle().stroke(.white.opacity(0.7), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("戻る")

            VStack(alignment: .leading, spacing: 2) {
                Text("グルームアーカイブ")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Text(isLoading ? "読み込み中" : "\(count)件")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            }

            Spacer()

            if isLoading {
                ProgressView()
                    .tint(MegrumTheme.lavender)
                    .frame(width: 42, height: 42)
                    .background(.regularMaterial, in: Circle())
            }
        }
    }
}

private struct GroomArchiveEmptyState: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "archivebox")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(width: 64, height: 64)
                .background(.white.opacity(0.94), in: Circle())
                .shadow(color: MegrumTheme.ink.opacity(0.08), radius: 12, y: 7)

            Text("過去のグルームはまだありません")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Text("投稿したグルームがここに地図で残ります。")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .multilineTextAlignment(.center)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.65), lineWidth: 1)
        }
    }
}

private struct GroomArchiveThumbnailRail: View {
    var grooms: [GroomPost]
    var selectedGroomID: UUID?
    var onSelect: (GroomPost) -> Void

    var body: some View {
        if !grooms.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(grooms) { groom in
                        Button {
                            onSelect(groom)
                        } label: {
                            GroomArchiveThumbnail(groom: groom, isSelected: groom.id == selectedGroomID)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
            }
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.66), lineWidth: 1))
            .shadow(color: MegrumTheme.ink.opacity(0.12), radius: 18, y: 10)
        }
    }
}

private struct GroomArchiveThumbnail: View {
    var groom: GroomPost
    var isSelected: Bool

    var body: some View {
        VStack(spacing: 6) {
            GroomThumbnailCircle(url: groom.imageURL, size: 54)
                .overlay {
                    Circle()
                        .stroke(isSelected ? MegrumTheme.lavender : .white, lineWidth: isSelected ? 3 : 2)
                }

            Text(groom.createdAt.formatted(date: .numeric, time: .omitted))
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink.opacity(0.78))
                .lineLimit(1)
        }
        .frame(width: 68)
    }
}

private struct GroomArchiveStoryScreen: View {
    var grooms: [GroomPost]
    var initialGroom: GroomPost
    @ObservedObject var appState: MegrumAppState
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int
    @State private var dragOffset: CGSize = .zero
    @State private var showsInsights = false

    init(grooms: [GroomPost], initialGroom: GroomPost, appState: MegrumAppState) {
        let sortedGrooms = GroomArchiveOrdering.sorted(grooms.isEmpty ? [initialGroom] : grooms)
        self.grooms = sortedGrooms
        self.initialGroom = initialGroom
        self.appState = appState
        _currentIndex = State(initialValue: sortedGrooms.firstIndex(where: { $0.id == initialGroom.id }) ?? 0)
    }

    private var currentGroom: GroomPost {
        grooms[max(0, min(currentIndex, grooms.count - 1))]
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            AsyncImage(url: currentGroom.imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .id(currentGroom.id)
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                case .failure:
                    GroomImageFailureView(message: "画像を読み込めませんでした", foregroundColor: .white)
                default:
                    ProgressView()
                        .tint(.white)
                        .controlSize(.large)
                }
            }
            .padding(.horizontal, 8)
            .offset(y: dragOffset.height * 0.20)
            .scaleEffect(max(0.92, 1 - abs(dragOffset.height) / 900))

            HStack(spacing: 0) {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { move(by: -1) }

                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { move(by: 1) }
            }

            VStack(spacing: 0) {
                HStack(spacing: 6) {
                    ForEach(grooms.indices, id: \.self) { index in
                        Capsule()
                            .fill(index <= currentIndex ? .white : .white.opacity(0.28))
                            .frame(height: 3)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 14)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(currentGroom.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                        Text("上にスワイプで反応を見る")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .opacity(0.72)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.black.opacity(0.28), in: Capsule())

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(.black.opacity(0.28), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("閉じる")
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)

                Spacer()

                GroomArchiveInsightPill(
                    likeCount: appState.groomReactions(for: currentGroom.id).count,
                    commentCount: appState.groomReplies(for: currentGroom.id).count,
                    action: { showsInsights = true }
                )
                .padding(.horizontal, 22)
                .padding(.bottom, 28)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 12)
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { value in
                    if value.translation.height < -76 {
                        showsInsights = true
                    } else if value.translation.height > 110 {
                        dismiss()
                    }
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                        dragOffset = .zero
                    }
                }
        )
        .sheet(isPresented: $showsInsights) {
            GroomArchiveInsightsSheet(groom: currentGroom, appState: appState)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private func move(by delta: Int) {
        let nextIndex = currentIndex + delta
        guard grooms.indices.contains(nextIndex) else {
            if delta > 0 {
                dismiss()
            }
            return
        }
        withAnimation(.smooth(duration: 0.18)) {
            currentIndex = nextIndex
        }
    }
}

private struct GroomArchiveInsightPill: View {
    var likeCount: Int
    var commentCount: Int
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Capsule()
                    .fill(.white.opacity(0.72))
                    .frame(width: 42, height: 4)

                Label("\(likeCount)", systemImage: "heart.fill")
                Label("\(commentCount)", systemImage: "bubble.left.fill")
            }
            .font(.system(size: 14, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .frame(height: 54)
            .frame(maxWidth: .infinity)
            .background(.black.opacity(0.34), in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.18), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("いいねとコメントを見る")
    }
}

private struct GroomArchiveInsightsSheet: View {
    var groom: GroomPost
    @ObservedObject var appState: MegrumAppState

    private var likes: [GroomReaction] {
        appState.groomReactions(for: groom.id).sorted { $0.createdAt > $1.createdAt }
    }

    private var replies: [GroomReply] {
        appState.groomReplies(for: groom.id).sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack(spacing: 12) {
                    GroomThumbnailCircle(url: groom.imageURL, size: 54)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("反応")
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink)
                        Text(groom.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                    }
                }

                GroomArchiveReactionSection(
                    title: "いいね",
                    systemImage: "heart.fill",
                    emptyText: "まだいいねはありません",
                    isEmpty: likes.isEmpty
                ) {
                    ForEach(likes) { reaction in
                        GroomArchiveUserReactionRow(
                            userID: reaction.userID,
                            profile: appState.publicProfilesByUserID[reaction.userID]?.profile,
                            subtitle: reaction.createdAt.formatted(date: .abbreviated, time: .shortened),
                            commentBody: nil
                        )
                    }
                }

                GroomArchiveReactionSection(
                    title: "コメント",
                    systemImage: "bubble.left.fill",
                    emptyText: "まだコメントはありません",
                    isEmpty: replies.isEmpty
                ) {
                    ForEach(replies) { reply in
                        GroomArchiveUserReactionRow(
                            userID: reply.senderID,
                            profile: appState.publicProfilesByUserID[reply.senderID]?.profile,
                            subtitle: reply.createdAt.formatted(date: .abbreviated, time: .shortened),
                            commentBody: reply.body
                        )
                    }
                }
            }
            .padding(22)
        }
        .background(MegrumTheme.canvas)
    }
}

private struct GroomArchiveReactionSection<Content: View>: View {
    var title: String
    var systemImage: String
    var emptyText: String
    var isEmpty: Bool
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            if isEmpty {
                Text(emptyText)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                content
            }
        }
    }
}

private struct GroomArchiveUserReactionRow: View {
    var userID: UUID
    var profile: UserProfile?
    var subtitle: String
    var commentBody: String?

    private var displayName: String {
        profile?.displayName.nilIfBlank
            ?? profile?.handle.nilIfBlank
            ?? "ユーザー"
    }

    private var handleText: String? {
        profile?.handle.nilIfBlank.map { "@\($0)" }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            GroomArchiveUserAvatar(profile: profile, fallback: displayName)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 7) {
                    Text(displayName)
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    if let handleText {
                        Text(handleText)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                    }
                }
                Text(subtitle)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                if let commentBody, !commentBody.isBlank {
                    Text(commentBody)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink.opacity(0.86))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(MegrumTheme.lavender.opacity(0.10), lineWidth: 1)
        }
    }
}

private struct GroomArchiveUserAvatar: View {
    var profile: UserProfile?
    var fallback: String

    var body: some View {
        AsyncImage(url: profile?.avatarURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            default:
                Text(String(fallback.prefix(1)))
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 42, height: 42)
        .background(MegrumTheme.lavender, in: Circle())
        .clipShape(Circle())
    }
}

private enum GroomArchiveMapRegion {
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
                latitudeDelta: min(max(region.span.latitudeDelta, 0.014), 0.18),
                longitudeDelta: min(max(region.span.longitudeDelta, 0.014), 0.18)
            )
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

private struct GroomArchiveTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
