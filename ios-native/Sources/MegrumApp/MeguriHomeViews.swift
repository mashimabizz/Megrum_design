import MegrumCore
import MegrumDesign
import MapKit
import SwiftUI

struct MeguriHomeContent: View {
    @Binding var cameraPosition: MapCameraPosition
    var viewer: UserProfile?
    var grooms: [GroomPost]
    var mapGrooms: [GroomPost]
    var threads: [BoardThread]
    var replyCounts: [UUID: Int]
    var currentCoordinate: MegrumLocationCoordinate?
    var isLoading: Bool
    var selectedScope: BoardThread.Audience
    var selectedPrefecture: String
    var notice: MegrumLocationNotice?
    var isRequestingLocation: Bool
    @Binding var boardSheetDetent: MeguriBoardSheetDetent
    var onOpenMap: () -> Void
    var onRecenterMap: () -> Void
    var onSelectGroom: (GroomPost) -> Void
    var onSelectThread: (BoardThread) -> Void
    var onNoticeAction: () -> Void
    var onChangeScope: (BoardThread.Audience) -> Void
    var onOpenPrefecture: () -> Void
    var onOpenGroomComposer: () -> Void
    var onOpenThreadComposer: () -> Void
    var onOpenGroomArchive: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                MeguriHomeMapBackdrop(
                    cameraPosition: $cameraPosition,
                    grooms: mapGrooms,
                    threads: threads,
                    currentCoordinate: currentCoordinate,
                    viewerID: viewer?.id,
                    onSelectGroom: onSelectGroom,
                    onSelectThread: onSelectThread
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        VStack(spacing: 10) {
                            MeguriMapRecenterButton(
                                isRequesting: isRequestingLocation,
                                action: onRecenterMap
                            )
                            MeguriGroomArchiveButton(action: onOpenGroomArchive)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 78)

                    if let notice {
                        MeguriHomeNoticeCard(notice: notice, action: onNoticeAction)
                            .padding(.horizontal, 38)
                            .padding(.top, 14)
                    }

                    Spacer()
                }

                MeguriBoardBottomSheet(
                    detent: $boardSheetDetent,
                    viewportHeight: proxy.size.height,
                    threads: threads,
                    grooms: grooms,
                    replyCounts: replyCounts,
                    isLoading: isLoading,
                    selectedScope: selectedScope,
                    selectedPrefecture: selectedPrefecture,
                    onChangeScope: onChangeScope,
                    onOpenPrefecture: onOpenPrefecture,
                    onOpenGroomComposer: onOpenGroomComposer,
                    onOpenThreadComposer: onOpenThreadComposer,
                    onOpenThread: onSelectThread
                )
                .frame(height: MeguriBoardSheetLayout.expandedHeight(in: proxy.size.height), alignment: .top)
            }
        }
    }
}

struct MeguriHomeMapBackdrop: View {
    @Binding var cameraPosition: MapCameraPosition
    var grooms: [GroomPost]
    var threads: [BoardThread]
    var currentCoordinate: MegrumLocationCoordinate?
    var viewerID: UUID?
    var onSelectGroom: (GroomPost) -> Void
    var onSelectThread: (BoardThread) -> Void

    var body: some View {
        Map(position: $cameraPosition, interactionModes: [.pan, .zoom]) {
            if let currentCoordinate {
                MapCircle(
                    center: currentCoordinate.clLocationCoordinate,
                    radius: MeguriAccessPolicy.groomOpenRadiusMeters
                )
                .foregroundStyle(MegrumTheme.lavender.opacity(0.08))
                .stroke(MegrumTheme.lavender.opacity(0.48), lineWidth: 1.8)
            }

            ForEach(grooms) { groom in
                Annotation("グルーム", coordinate: groom.coordinate) {
                    Button {
                        onSelectGroom(groom)
                    } label: {
                        GroomMapPin(
                            groom: groom,
                            isOutOfRange: !MeguriAccessPolicy.canOpenGroom(
                                groom,
                                currentCoordinate: currentCoordinate,
                                viewerID: viewerID
                            )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            ForEach(threads.compactMap(BoardMapAnnotation.init(thread:))) { annotation in
                Annotation(annotation.thread.title, coordinate: annotation.coordinate) {
                    Button {
                        onSelectThread(annotation.thread)
                    } label: {
                        BoardMapPin(
                            thread: annotation.thread,
                            isOutOfRange: !MeguriAccessPolicy.canOpenBoard(
                                annotation.thread,
                                currentCoordinate: currentCoordinate,
                                viewerID: viewerID
                            )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .mapStyle(.standard(elevation: .flat, emphasis: .muted))
        .overlay {
            LinearGradient(
                colors: [.white.opacity(0.80), .white.opacity(0.28), .white.opacity(0.04)],
                startPoint: .top,
                endPoint: .center
            )
            .allowsHitTesting(false)
        }
    }
}

struct MeguriMapRecenterButton: View {
    var isRequesting: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isRequesting {
                    ProgressView()
                        .controlSize(.small)
                        .tint(MegrumTheme.lavender)
                } else {
                    Image(systemName: "location.fill")
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(MegrumTheme.lavender)
                }
            }
            .frame(width: 48, height: 48)
            .background(.regularMaterial, in: Circle())
            .overlay {
                Circle()
                    .stroke(.white.opacity(0.66), lineWidth: 1)
            }
            .shadow(color: MegrumTheme.ink.opacity(0.12), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("現在地へ移動")
    }
}

struct MeguriGroomArchiveButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "archivebox.fill")
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(width: 48, height: 48)
                .background(.regularMaterial, in: Circle())
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.66), lineWidth: 1)
                }
                .shadow(color: MegrumTheme.ink.opacity(0.12), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("グルームアーカイブを開く")
    }
}

struct MeguriHomeNoticeCard: View {
    var notice: MegrumLocationNotice
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "location.fill")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(MegrumTheme.lavender)
                    .frame(width: 48, height: 48)
                    .background(MegrumTheme.lavender.opacity(0.12), in: Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                    Text(notice.message)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .lineLimit(2)
                }
                Spacer()
            }
            .padding(14)
            .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: MegrumTheme.ink.opacity(0.09), radius: 14, y: 8)
        }
        .buttonStyle(.plain)
    }

    private var title: String {
        if notice.message.contains("掲示板") || notice.message.contains("投稿") {
            return "投稿できませんでした"
        }
        if notice.message.contains("読み込") {
            return "読み込めませんでした"
        }
        return "現在地を確認中"
    }
}

struct MeguriNoticeBanner: View {
    var message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "location.slash")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(MegrumTheme.lavender)

            Text(message)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 6)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(MegrumTheme.lavender.opacity(0.14), lineWidth: 1)
        }
    }
}

private struct MeguriAvatarCircle: View {
    var profile: UserProfile?
    var size: CGFloat

    var body: some View {
        Circle()
            .fill(MegrumTheme.lavender.opacity(0.16))
            .frame(width: size, height: size)
            .overlay {
                if let avatarURL = profile?.avatarURL {
                    AsyncImage(url: avatarURL) { phase in
                        switch phase {
                        case let .success(image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            Text(profile?.displayName.first.map(String.init) ?? "M")
                                .font(.system(size: 20, weight: .black, design: .rounded))
                                .foregroundStyle(MegrumTheme.lavender)
                        }
                    }
                    .clipShape(Circle())
                } else {
                    Text(profile?.displayName.first.map(String.init) ?? "M")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                }
            }
            .overlay(Circle().stroke(MegrumTheme.lavender.opacity(0.78), lineWidth: 2))
    }
}

private extension BoardThread {
    var shortMapTitle: String {
        if title.contains("物販") {
            return "物販列"
        }
        if title.contains("駅") || title.contains("広場") {
            return "駅前広場"
        }
        return String(title.prefix(4))
    }
}
