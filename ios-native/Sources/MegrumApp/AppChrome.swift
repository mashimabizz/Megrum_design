import MegrumDesign
import SwiftUI

enum AppDrawerDestination: String, Identifiable {
    case profile
    case notifications
    case profileEdit
    case oshiSettings
    case schedules
    case settings
    case help

    var id: String { rawValue }

    static let primaryItems: [AppDrawerDestination] = [
        .profile,
        .notifications,
        .oshiSettings,
        .schedules
    ]

    static let compactItems: [AppDrawerDestination] = [
        .settings,
        .help
    ]

    var title: String {
        switch self {
        case .profile:
            "プロフィール"
        case .notifications:
            "通知"
        case .profileEdit:
            "プロフィール編集"
        case .oshiSettings:
            "推し設定"
        case .schedules:
            "スケジュール"
        case .settings:
            "設定とプライバシー"
        case .help:
            "ヘルプ"
        }
    }

    var systemImage: String {
        switch self {
        case .profile:
            "star"
        case .notifications:
            "bell"
        case .profileEdit:
            "square.and.pencil"
        case .oshiSettings:
            "sparkles"
        case .schedules:
            "calendar"
        case .settings:
            "checkmark.shield"
        case .help:
            "doc.text"
        }
    }
}

enum AppDrawerVisualMetrics {
    static let minimumDrawerWidth: CGFloat = 320
    static let maximumDrawerWidth: CGFloat = 380
    static let drawerWidthRatio: CGFloat = 0.9
    static let foregroundOpenRatio: CGFloat = 0.68
    static let foregroundOpenInset: CGFloat = 34
    static let foregroundCornerRadius: CGFloat = 18
    static let whiteoutOpacity: CGFloat = 0.18
    static let foregroundShadowOpacity: CGFloat = 0.16
    static let foregroundShadowRadius: CGFloat = 18
    static let closedEdgeGestureWidth: CGFloat = 28

    static func drawerWidth(screenWidth: CGFloat) -> CGFloat {
        min(maximumDrawerWidth, max(minimumDrawerWidth, screenWidth * drawerWidthRatio))
    }

    static func openOffset(screenWidth: CGFloat) -> CGFloat {
        let width = drawerWidth(screenWidth: screenWidth)
        return min(width - foregroundOpenInset, screenWidth * foregroundOpenRatio)
    }

    static func drawerOffset(drawerWidth: CGFloat, progress: CGFloat) -> CGFloat {
        -drawerWidth * (1 - clampedProgress(progress))
    }

    static func presentationProgress(
        isPresented: Bool,
        dragTranslation: CGFloat,
        drawerTravel: CGFloat
    ) -> CGFloat {
        guard drawerTravel > 0 else {
            return isPresented ? 1 : 0
        }
        let baseOffset = isPresented ? drawerTravel : 0
        let gestureOffset = isPresented ? min(0, dragTranslation) : max(0, dragTranslation)
        let revealed = min(drawerTravel, max(0, baseOffset + gestureOffset))
        return revealed / drawerTravel
    }

    static func clampedProgress(_ progress: CGFloat) -> CGFloat {
        min(1, max(0, progress))
    }
}

enum AppDrawerGestureResolver {
    static let closedStartMinimumDistance: CGFloat = 5
    static let openStartMinimumDistance: CGFloat = 6
    static let closedHorizontalDominance: CGFloat = 1
    static let openHorizontalDominance: CGFloat = 1
    static let openThresholdRatio: CGFloat = 0.24
    static let predictedMomentumBonus: CGFloat = 32

    static func activeTranslation(isPresented: Bool, translation: CGSize) -> CGFloat? {
        guard isHorizontalSwipe(translation, isPresented: isPresented) else {
            return nil
        }
        if isPresented {
            guard translation.width < 0 else {
                return nil
            }
            return translation.width
        }

        guard translation.width > 0 else {
            return nil
        }
        return translation.width
    }

    static func targetVisibility(
        isPresented: Bool,
        translation: CGSize,
        predictedEndTranslationWidth: CGFloat,
        drawerWidth: CGFloat
    ) -> Bool? {
        guard isHorizontalSwipe(translation, isPresented: isPresented) else {
            return nil
        }

        let absX = abs(translation.width)
        let threshold = drawerWidth * openThresholdRatio
        let fastEnough = abs(predictedEndTranslationWidth) >= absX + predictedMomentumBonus

        if isPresented {
            let shouldClose = translation.width <= -threshold || (translation.width < 0 && fastEnough)
            return !shouldClose
        }

        let shouldOpen = translation.width >= threshold || (translation.width > 0 && fastEnough)
        return shouldOpen
    }

    private static func isHorizontalSwipe(_ translation: CGSize, isPresented: Bool) -> Bool {
        let absX = abs(translation.width)
        let absY = abs(translation.height)
        let minimumDistance = isPresented ? openStartMinimumDistance : closedStartMinimumDistance
        let dominance = isPresented ? openHorizontalDominance : closedHorizontalDominance
        return absX > minimumDistance && absX > absY * dominance
    }
}

@MainActor
struct AppDrawerOverlay: View {
    @Binding var isPresented: Bool
    var presentationProgress: CGFloat
    var drawerWidth: CGFloat
    @ObservedObject var appState: MegrumAppState
    var onSelectDestination: (AppDrawerDestination) -> Void
    var onSignOut: () async -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isClosing = false

    var body: some View {
        panel
            .frame(width: drawerWidth)
            .frame(maxHeight: .infinity)
            .background(Color.white)
            .opacity(drawerOpacity)
            .offset(x: drawerOffset)
        .allowsHitTesting(presentationProgress > 0.001)
        .onChange(of: isPresented) { _, newValue in
            if newValue {
                isClosing = false
            }
        }
        .task {
            if appState.notifications.isEmpty {
                await appState.loadNotifications()
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
                .padding(.bottom, 10)

            VStack(spacing: 4) {
                ForEach(AppDrawerDestination.compactItems) { destination in
                    drawerButton(
                        title: destination.title,
                        systemImage: destination.systemImage,
                        destination: destination,
                        isCompact: true
                    )
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 8)

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
                    .font(.system(size: 16.5, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
            }
            .disabled(isClosing)
            .padding(.bottom, 22)
        }
        .padding(.top, 28)
    }

    private var profileHeader: some View {
        VStack(alignment: .leading, spacing: 5) {
            ProfileVisualAvatar(
                url: appState.viewer?.avatarURL,
                fallback: appState.viewer?.displayName ?? appState.viewer?.handle ?? "M",
                size: 64
            )
                .padding(.bottom, 9)

            Text(appState.viewer?.displayName ?? "Megrum")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text("@\(appState.viewer?.handle ?? "preview_hana")")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .lineLimit(1)

            Text(profileAreaText)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .lineLimit(1)
                .padding(.top, 6)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 22)
    }

    private func drawerButton(
        title: String,
        systemImage: String,
        destination: AppDrawerDestination,
        badge: Int = 0,
        isCompact: Bool = false
    ) -> some View {
        Button {
            select(destination)
        } label: {
            HStack(spacing: isCompact ? 16 : 18) {
                Image(systemName: systemImage)
                    .font(.system(size: isCompact ? 21 : 25, weight: .semibold))
                    .foregroundStyle(MegrumTheme.ink)
                    .frame(width: 25)

                Text(title)
                    .font(.system(size: isCompact ? 16.5 : 20, weight: isCompact ? .bold : .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

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
            .padding(.horizontal, 3)
            .frame(minHeight: isCompact ? 40 : 46)
        }
        .buttonStyle(.plain)
        .disabled(isClosing)
        .accessibilityLabel(title)
    }

    private var drawerOpacity: Double {
        let raw = AppDrawerVisualMetrics.clampedProgress(presentationProgress) / 0.3
        return Double(min(1, max(0, raw)))
    }

    private var drawerOffset: CGFloat {
        AppDrawerVisualMetrics.drawerOffset(
            drawerWidth: drawerWidth,
            progress: presentationProgress
        )
    }

    private var drawerAnimation: Animation {
        reduceMotion ? .easeOut(duration: 0.12) : .interactiveSpring(response: 0.32, dampingFraction: 0.88)
    }

    private var profileAreaText: String {
        var parts: [String] = []
        if let prefecture = appState.viewer?.prefecture.nilIfBlank {
            parts.append(prefecture)
        }
        if let ageText = appState.viewer?.ageText {
            parts.append(ageText)
        }
        guard !parts.isEmpty else {
            return "エリア未設定"
        }
        return parts.joined(separator: " ・ ")
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
        withAnimation(drawerAnimation) {
            isPresented = false
        }
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
