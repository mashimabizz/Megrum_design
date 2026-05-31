import MegrumDesign
import SwiftUI

enum AppDrawerDestination: String, Identifiable {
    case profile
    case notifications
    case oshiSettings
    case address
    case blockedUsers
    case settings

    var id: String { rawValue }

    static let primaryItems: [AppDrawerDestination] = [
        .profile,
        .notifications,
        .oshiSettings,
        .address,
        .blockedUsers,
        .settings
    ]

    var title: String {
        switch self {
        case .profile:
            "プロフィール"
        case .notifications:
            "通知"
        case .oshiSettings:
            "推し設定"
        case .address:
            "住所設定"
        case .blockedUsers:
            "ブロックした人"
        case .settings:
            "設定とプライバシー"
        }
    }

    var systemImage: String {
        switch self {
        case .profile:
            "person.crop.circle"
        case .notifications:
            "bell"
        case .oshiSettings:
            "sparkles"
        case .address:
            "shippingbox"
        case .blockedUsers:
            "person.crop.circle.badge.xmark"
        case .settings:
            "gearshape"
        }
    }

    func subtitle(notificationStatus: String, addressStatus: String) -> String {
        switch self {
        case .profile:
            "自分の表示を確認"
        case .notifications:
            notificationStatus
        case .oshiSettings:
            "グループ・メンバー"
        case .address:
            addressStatus
        case .blockedUsers:
            "一覧と解除"
        case .settings:
            "通知・アカウント"
        }
    }
}

@MainActor
struct AppDrawerOverlay: View {
    @Binding var isPresented: Bool
    @ObservedObject var appState: MegrumAppState
    var onSelectDestination: (AppDrawerDestination) -> Void
    var onSignOut: () async -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dragTranslation: CGFloat = 0
    @State private var isClosing = false

    private let drawerWidth: CGFloat = 318

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Color.black
                    .opacity(backdropOpacity)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        close()
                    }

                panel
                    .frame(width: min(drawerWidth, proxy.size.width * 0.84))
                    .frame(maxHeight: .infinity)
                    .background(.regularMaterial)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 34,
                            topTrailingRadius: 34,
                            style: .continuous
                        )
                    )
                    .shadow(color: Color.black.opacity(0.20), radius: 30, x: 10, y: 0)
                    .offset(x: drawerOffset)
                    .gesture(closeDragGesture)
            }
            .allowsHitTesting(isPresented)
            .animation(drawerAnimation, value: isPresented)
            .animation(drawerAnimation, value: dragTranslation)
            .onChange(of: isPresented) { _, newValue in
                if newValue {
                    isClosing = false
                    dragTranslation = 0
                }
            }
            .task {
                if appState.notifications.isEmpty {
                    await appState.loadNotifications()
                }
            }
        }
    }

    private var panel: some View {
        VStack(alignment: .leading, spacing: 0) {
            profileHeader

            VStack(spacing: 2) {
                ForEach(AppDrawerDestination.primaryItems) { destination in
                    drawerButton(
                        title: destination.title,
                        subtitle: destination.subtitle(
                            notificationStatus: notificationStatusText,
                            addressStatus: addressStatusText
                        ),
                        systemImage: destination.systemImage,
                        destination: destination,
                        badge: destination == .notifications ? appState.unreadNotificationCount : 0
                    )
                }
            }
            .padding(.horizontal, 18)

            Spacer(minLength: 18)

            Divider()
                .padding(.horizontal, 22)

            Button(role: .destructive) {
                guard !isClosing else {
                    return
                }
                isClosing = true
                Task {
                    await onSignOut()
                    close()
                }
            } label: {
                Label("ログアウト", systemImage: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 16)
            }
            .disabled(isClosing)
            .padding(.bottom, 22)
        }
        .padding(.top, 54)
    }

    private var profileHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [MegrumTheme.lavender, MegrumTheme.pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 74, height: 74)
                .overlay {
                    Text(profileInitial)
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(appState.viewer?.displayName ?? "Megrum")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text("@\(appState.viewer?.handle ?? "megrum")")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .lineLimit(1)
            }

            if let prefecture = appState.viewer?.prefecture, !prefecture.isEmpty {
                Text(prefecture)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.72), in: Capsule())
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }

    private func drawerButton(
        title: String,
        subtitle: String,
        systemImage: String,
        destination: AppDrawerDestination,
        badge: Int = 0
    ) -> some View {
        Button {
            select(destination)
        } label: {
            HStack(spacing: 16) {
                Image(systemName: systemImage)
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundStyle(MegrumTheme.ink)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                    Text(subtitle)
                        .font(.system(size: 12.5, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                if badge > 0 {
                    Text("\(badge)")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(MegrumTheme.pink, in: Capsule())
                }
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 8)
            .padding(.vertical, 11)
        }
        .buttonStyle(.plain)
        .disabled(isClosing)
        .accessibilityLabel(title)
    }

    private var closeDragGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                guard !isClosing else {
                    return
                }
                dragTranslation = min(0, value.translation.width)
            }
            .onEnded { value in
                guard !isClosing else {
                    return
                }
                if value.translation.width < -70 || value.predictedEndTranslation.width < -120 {
                    close()
                } else {
                    dragTranslation = 0
                }
            }
    }

    private var drawerOffset: CGFloat {
        (isPresented ? 0 : -drawerWidth) + dragTranslation
    }

    private var backdropOpacity: Double {
        let progress = max(0, min(1, 1 + Double(drawerOffset / drawerWidth)))
        return 0.18 * progress
    }

    private var drawerAnimation: Animation {
        reduceMotion ? .easeOut(duration: 0.12) : .interactiveSpring(response: 0.32, dampingFraction: 0.88)
    }

    private var profileInitial: String {
        guard let first = appState.viewer?.displayName.first else {
            return "M"
        }
        return String(first)
    }

    private var notificationStatusText: String {
        guard !appState.notifications.isEmpty else {
            return "未読なし"
        }
        if appState.unreadNotificationCount > 0 {
            return "未読 \(appState.unreadNotificationCount)件"
        }
        return "すべて既読"
    }

    private var addressStatusText: String {
        guard let address = appState.mailingAddress, address.isReady else {
            return "未登録"
        }
        return address.summary
    }

    private func select(_ destination: AppDrawerDestination) {
        guard !isClosing else {
            return
        }
        close {
            onSelectDestination(destination)
        }
    }

    private func close(completion: (() -> Void)? = nil) {
        isClosing = true
        dragTranslation = 0
        isPresented = false
        let delay = reduceMotion ? 0.08 : 0.18
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            isClosing = false
            completion?()
        }
    }
}

@MainActor
struct AppDrawerScreen: View {
    @ObservedObject var appState: MegrumAppState
    var onOpenNotificationDestination: (MegrumTab) -> Void
    var onSignOut: () async -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                NavigationLink {
                    OwnProfileScreen(appState: appState)
                } label: {
                    AppDrawerScreenRouteLabel(
                        title: "プロフィール",
                        subtitle: "自分の表示を確認",
                        systemImage: "person.crop.circle"
                    )
                }

                notificationLink

                NavigationLink {
                    AddressSettingsScreen(appState: appState)
                } label: {
                    AppDrawerScreenRouteLabel(
                        title: "住所設定",
                        subtitle: "取引に使う住所",
                        systemImage: "shippingbox"
                    )
                }

                NavigationLink {
                    BlockedUsersScreen(appState: appState)
                } label: {
                    AppDrawerScreenRouteLabel(
                        title: "ブロックした人",
                        subtitle: "一覧と解除",
                        systemImage: "person.crop.circle.badge.xmark"
                    )
                }

                NavigationLink {
                    SettingsScreen(
                        appState: appState,
                        onOpenNotificationDestination: { tab in
                            dismiss()
                            onOpenNotificationDestination(tab)
                        },
                        onSignOut: onSignOut
                    )
                } label: {
                    AppDrawerScreenRouteLabel(
                        title: "設定",
                        subtitle: "通知・住所・ブロック",
                        systemImage: "gearshape"
                    )
                }
            }

            Section {
                Button(role: .destructive) {
                    Task {
                        await onSignOut()
                        dismiss()
                    }
                } label: {
                    Label("ログアウト", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .navigationTitle("メニュー")
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
        .task {
            if appState.notifications.isEmpty {
                await appState.loadNotifications()
            }
        }
    }

    @ViewBuilder
    private var notificationLink: some View {
        let link = NavigationLink {
            NotificationCenterScreen(appState: appState) { tab in
                dismiss()
                onOpenNotificationDestination(tab)
            }
        } label: {
            Label {
                VStack(alignment: .leading, spacing: 3) {
                    Text("通知")
                        .font(.body.weight(.semibold))
                    Text(notificationStatusText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(MegrumTheme.muted)
                }
            } icon: {
                Image(systemName: "bell")
                    .foregroundStyle(MegrumTheme.lavender)
            }
        }

        if appState.unreadNotificationCount > 0 {
            link.badge(appState.unreadNotificationCount)
        } else {
            link
        }
    }

    private var notificationStatusText: String {
        guard !appState.notifications.isEmpty else {
            return "未読なし"
        }
        if appState.unreadNotificationCount > 0 {
            return "未読 \(appState.unreadNotificationCount)件"
        }
        return "すべて既読"
    }
}

private struct AppDrawerScreenRouteLabel: View {
    var title: String
    var subtitle: String
    var systemImage: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body.weight(.semibold))
                Text(subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MegrumTheme.muted)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(MegrumTheme.lavender)
        }
    }
}

extension View {
    @ViewBuilder
    func megrumHiddenNavigationBar() -> some View {
        #if os(iOS)
        self
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        #else
        self
        #endif
    }

    @ViewBuilder
    func megrumInlineNavigationTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    func megrumTextFieldStyle() -> some View {
        self
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(Color.white.opacity(0.58), lineWidth: 1)
            }
    }
}
