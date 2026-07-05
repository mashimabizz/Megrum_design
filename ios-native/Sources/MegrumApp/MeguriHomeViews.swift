import MegrumCore
import MegrumDesign
import MapKit
import SwiftUI

struct MeguriHomeContent: View {
    @Binding var cameraPosition: MapCameraPosition
    var viewer: UserProfile?
    var meguriProfile: MeguriProfile?
    var grooms: [GroomPost]
    var mapGrooms: [GroomPost]
    var threads: [BoardThread]
    var currentCoordinate: MegrumLocationCoordinate?
    var subscriptionState: UserSubscriptionState
    var notice: MegrumLocationNotice?
    var isRequestingLocation: Bool
    var unreadMessageCount: Int
    var isContentFilterActive: Bool
    @Binding var selectedMapKind: MeguriMapKind
    var onOpenContentFilter: () -> Void
    var onRecenterMap: () -> Void
    var onOpenMessages: () -> Void
    var onSelectGroom: (GroomPost, UnitPoint) -> Void
    var onSelectThread: (BoardThread) -> Void
    var onTapMapCoordinate: (MegrumLocationCoordinate) -> Void
    var pendingCreationCoordinate: MegrumLocationCoordinate?
    var onCreateGroomAtPendingCoordinate: () -> Void
    var onCreateThreadAtPendingCoordinate: () -> Void
    var onCancelPendingCreationCoordinate: () -> Void
    var onNoticeAction: () -> Void
    var onOpenGroomArchive: () -> Void
    var onOpenMeguriProfile: () -> Void
    var onOpenNotificationSettings: () -> Void = {}
    var isLoadingViewport = false
    var onViewportChange: (MKCoordinateRegion) -> Void = { _ in }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                MeguriHomeMapBackdrop(
                    cameraPosition: $cameraPosition,
                    selectedKind: selectedMapKind,
                    grooms: mapGrooms,
                    threads: threads,
                    currentCoordinate: currentCoordinate,
                    viewerID: viewer?.id,
                    subscriptionState: subscriptionState,
                    onSelectGroom: onSelectGroom,
                    onSelectThread: onSelectThread,
                    onTapCoordinate: onTapMapCoordinate,
                    pendingCreationCoordinate: pendingCreationCoordinate,
                    onCreateGroomAtPendingCoordinate: onCreateGroomAtPendingCoordinate,
                    onCreateThreadAtPendingCoordinate: onCreateThreadAtPendingCoordinate,
                    onCancelPendingCreationCoordinate: onCancelPendingCreationCoordinate,
                    onViewportChange: onViewportChange
                )
                .ignoresSafeArea()

                if isLoadingViewport {
                    MeguriViewportLoadingToast()
                        .padding(.bottom, MeguriHomeUtilityLayout.bottomPadding(safeAreaBottom: proxy.safeAreaInsets.bottom) + 66)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }

                VStack(spacing: 0) {
                    HStack(alignment: .top, spacing: 10) {
                        VStack(spacing: 10) {
                            MeguriHomeFilterButton(
                                isActive: isContentFilterActive,
                                action: onOpenContentFilter
                            )
                            MeguriHomeNotificationSettingsButton(action: onOpenNotificationSettings)
                        }
                        MeguriHomeMapKindCycleButton(selectedKind: $selectedMapKind)
                        Spacer()
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, MeguriHomeTopControlsLayout.topPadding(safeAreaTop: proxy.safeAreaInsets.top))

                    if let notice {
                        MeguriHomeNoticeCard(notice: notice, action: onNoticeAction)
                            .padding(.horizontal, 38)
                            .padding(.top, 14)
                    }

                    Spacer()
                }

                MeguriHomeBottomUtilityRow(
                    unreadMessageCount: unreadMessageCount,
                    isRequestingLocation: isRequestingLocation,
                    onOpenMessages: onOpenMessages,
                    onRecenterMap: onRecenterMap,
                    onOpenGroomArchive: onOpenGroomArchive
                )
                .padding(.horizontal, 18)
                .padding(.bottom, MeguriHomeUtilityLayout.bottomPadding(safeAreaBottom: proxy.safeAreaInsets.bottom))
            }
            .animation(.easeInOut(duration: 0.25), value: isLoadingViewport)
        }
    }
}

private struct MeguriHomeFilterButton: View {
    var isActive: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(isActive ? .white : MegrumTheme.lavender)
                .frame(width: 48, height: 48)
                .background {
                    if isActive {
                        Circle()
                            .fill(MegrumTheme.lavender)
                    } else {
                        Circle()
                            .fill(.regularMaterial)
                    }
                }
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.66), lineWidth: 1)
                }
                .shadow(color: MegrumTheme.ink.opacity(0.12), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("めぐりの表示をフィルター")
    }
}

/// ビューポート読み込み中のコンパクトなトースト（タブバー上・フェード表示）。
private struct MeguriViewportLoadingToast: View {
    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.mini)
                .tint(.white)
            Text("読み込み中…")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(MegrumTheme.ink.opacity(0.82), in: Capsule())
        .shadow(color: MegrumTheme.ink.opacity(0.2), radius: 12, y: 6)
        .accessibilityLabel("地図の内容を読み込み中")
    }
}

private struct MeguriHomeNotificationSettingsButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(width: 48, height: 48)
                .background {
                    Circle()
                        .fill(.regularMaterial)
                }
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.66), lineWidth: 1)
                }
                .shadow(color: MegrumTheme.ink.opacity(0.12), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("グルームとチャットルームの通知設定")
    }
}

private struct MeguriHomeMapKindCycleButton: View {
    @Binding var selectedKind: MeguriMapKind

    var body: some View {
        Button {
            withAnimation(.smooth(duration: 0.18)) {
                selectedKind = selectedKind.nextHomeKind
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: selectedKind.homeSystemImage)
                    .font(.system(size: 18, weight: .heavy))
                Text(selectedKind.homeDisplayLabel)
                    .font(.system(size: 12, weight: .black, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(height: 48)
            .padding(.horizontal, 16)
            .background(
                LinearGradient(
                    colors: selectedKind.homeAccentColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .stroke(.white.opacity(0.74), lineWidth: 1)
            }
            .shadow(color: selectedKind.homeShadowColor.opacity(0.24), radius: 14, y: 7)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("めぐり地図の表示を\(selectedKind.homeDisplayLabel)に切り替え中")
    }
}

private struct MeguriHomeBottomUtilityRow: View {
    var unreadMessageCount: Int
    var isRequestingLocation: Bool
    var onOpenMessages: () -> Void
    var onRecenterMap: () -> Void
    var onOpenGroomArchive: () -> Void

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(spacing: 12) {
                MeguriMapRecenterButton(
                    isRequesting: isRequestingLocation,
                    size: 54,
                    iconSize: 20,
                    action: onRecenterMap
                )

                MeguriMessageInboxButton(
                    unreadCount: unreadMessageCount,
                    size: 88,
                    iconSize: 34,
                    action: onOpenMessages
                )

                MeguriGroomArchiveButton(action: onOpenGroomArchive)
                    .frame(width: 88, alignment: .center)
            }

            Spacer()
        }
    }
}

private struct MeguriHomeSelfProfileButton: View {
    var viewer: UserProfile?
    var meguriProfile: MeguriProfile?
    var action: () -> Void

    private var displayName: String {
        meguriProfile?.displayName.nilIfBlank
            ?? viewer?.displayName.nilIfBlank
            ?? "めぐり"
    }

    private var avatarID: String {
        meguriProfile?.avatarID.nilIfBlank ?? "avatar_1"
    }

    var body: some View {
        Button(action: action) {
            MeguriProfileAvatarView(
                avatarID: avatarID,
                avatarURL: meguriProfile?.avatarURL,
                fallback: displayName,
                size: 54
            )
            .overlay {
                Circle()
                    .stroke(.white.opacity(0.82), lineWidth: 2)
            }
            .shadow(color: MegrumTheme.ink.opacity(0.18), radius: 14, y: 7)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("めぐりプロフィールを設定")
    }
}

private extension MeguriMapKind {
    var homeAccentColors: [Color] {
        switch self {
        case .all:
            [Color(red: 0.21, green: 0.77, blue: 0.82), Color(red: 0.16, green: 0.72, blue: 0.54)]
        case .grooms:
            [Color(red: 1.00, green: 0.52, blue: 0.55), Color(red: 1.00, green: 0.70, blue: 0.30)]
        case .boards:
            [Color(red: 0.27, green: 0.56, blue: 1.00), Color(red: 0.35, green: 0.79, blue: 0.96)]
        }
    }

    var homeShadowColor: Color {
        switch self {
        case .all:
            Color(red: 0.08, green: 0.58, blue: 0.52)
        case .grooms:
            Color(red: 0.94, green: 0.34, blue: 0.38)
        case .boards:
            Color(red: 0.12, green: 0.43, blue: 0.90)
        }
    }
}
