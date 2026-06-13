import MegrumCore
import MegrumDesign
import MapKit
import SwiftUI

struct MeguriHomeContent: View {
    @Binding var cameraPosition: MapCameraPosition
    var viewer: UserProfile?
    var grooms: [GroomPost]
    var threads: [BoardThread]
    var replyCounts: [UUID: Int]
    var isLoading: Bool
    var selectedScope: BoardThread.Audience
    var selectedPrefecture: String
    var notice: MegrumLocationNotice?
    @Binding var isBoardSheetExpanded: Bool
    var onOpenMap: () -> Void
    var onSelectGroom: (GroomPost) -> Void
    var onSelectThread: (BoardThread) -> Void
    var onNoticeAction: () -> Void
    var onChangeScope: (BoardThread.Audience) -> Void
    var onOpenPrefecture: () -> Void
    var onOpenGroomComposer: () -> Void
    var onOpenThreadComposer: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                MeguriHomeMapBackdrop(
                    cameraPosition: $cameraPosition,
                    grooms: grooms,
                    threads: threads,
                    onSelectGroom: onSelectGroom,
                    onSelectThread: onSelectThread
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    MeguriHomeTopBar()
                    .padding(.horizontal, 18)
                    .padding(.top, 28)

                    if let notice {
                        MeguriHomeNoticeCard(notice: notice, action: onNoticeAction)
                            .padding(.horizontal, 38)
                            .padding(.top, 18)
                    }

                    Spacer()

                    MeguriBoardBottomSheet(
                        isExpanded: $isBoardSheetExpanded,
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
                    .frame(height: isBoardSheetExpanded ? proxy.size.height * 0.76 : proxy.size.height * 0.48)
                    .animation(.smooth(duration: 0.24), value: isBoardSheetExpanded)
                }
            }
        }
    }
}

struct MeguriHomeMapBackdrop: View {
    @Binding var cameraPosition: MapCameraPosition
    var grooms: [GroomPost]
    var threads: [BoardThread]
    var onSelectGroom: (GroomPost) -> Void
    var onSelectThread: (BoardThread) -> Void

    var body: some View {
        Map(position: $cameraPosition, interactionModes: [.pan, .zoom]) {
            ForEach(grooms) { groom in
                Annotation("グルーム", coordinate: groom.coordinate) {
                    Button {
                        onSelectGroom(groom)
                    } label: {
                        GroomThumbnailCircle(url: groom.imageURL, size: 60)
                            .overlay(Circle().stroke(.white, lineWidth: 4))
                            .shadow(color: MegrumTheme.ink.opacity(0.18), radius: 14, y: 8)
                    }
                    .buttonStyle(.plain)
                }
            }

            ForEach(threads.compactMap(BoardMapAnnotation.init(thread:))) { annotation in
                Annotation(annotation.thread.title, coordinate: annotation.coordinate) {
                    Button {
                        onSelectThread(annotation.thread)
                    } label: {
                        VStack(spacing: 0) {
                            Text(annotation.thread.shortMapTitle)
                                .font(.system(size: 15, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .frame(height: 56)
                                .background(MegrumTheme.lavender, in: Circle())
                                .shadow(color: MegrumTheme.lavender.opacity(0.28), radius: 14, y: 8)
                            Circle()
                                .fill(MegrumTheme.lavender)
                                .frame(width: 10, height: 10)
                                .offset(y: -2)
                        }
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

struct MeguriHomeTopBar: View {
    var body: some View {
        ZStack {
            Text("めぐり")
                .font(.system(size: 23, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
        }
        .frame(height: 40)
        .frame(maxWidth: .infinity)
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
                    Text("現在地を確認中")
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
