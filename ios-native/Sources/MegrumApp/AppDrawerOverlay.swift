import MegrumCore
import MegrumDesign
import SwiftUI

@MainActor
struct AppDrawerOverlay: View {
    @Binding var isPresented: Bool
    var presentationProgress: CGFloat
    var drawerWidth: CGFloat
    @ObservedObject var appState: MegrumAppState
    var onSelectDestination: (AppDrawerDestination) -> Void
    var onSignOut: () async -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(HomeExchangeSettingsStorageKeys.preference) private var exchangePreferenceRawValue = HomeDefaultExchangeSettings.standard.preference.rawValue
    @AppStorage(HomeExchangeSettingsStorageKeys.requiresSamePrefecture) private var exchangeRequiresSamePrefecture = HomeDefaultExchangeSettings.standard.requiresSamePrefecture
    @AppStorage(HomeExchangeSettingsStorageKeys.requiresDateOverlap) private var exchangeRequiresDateOverlap = HomeDefaultExchangeSettings.standard.requiresDateOverlap
    @AppStorage(HomeExchangeSettingsStorageKeys.localPrefecture) private var exchangeLocalPrefecture = HomeDefaultExchangeSettings.standard.localPrefecture
    @AppStorage(HomeExchangeSettingsStorageKeys.localDateKeys) private var exchangeLocalDateKeysRawValue = ""
    @AppStorage(HomeExchangeSettingsStorageKeys.mailShippingFee) private var exchangeMailShippingFeeRawValue = HomeDefaultExchangeSettings.standard.mailShippingFee.rawValue
    @AppStorage(HomeExchangeSettingsStorageKeys.mailShippingDays) private var exchangeMailShippingDaysRawValue = HomeDefaultExchangeSettings.standard.mailShippingDays.rawValue
    @AppStorage(HomeExchangeSettingsStorageKeys.configuredAt) private var exchangeConfiguredAt = 0.0
    @State private var isClosing = false
    @State private var isSuppressingDrawerItemTap = false

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
                        badgeText: drawerBadgeText(for: destination)
                    )
                }
            }
            .padding(.horizontal, 18)

            VStack(spacing: 2) {
                ForEach(AppDrawerDestination.plusItems) { destination in
                    drawerButton(
                        title: destination.title,
                        systemImage: destination.systemImage,
                        destination: destination
                    )
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)

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
        badgeText: String? = nil,
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

                if let badgeText, !badgeText.isEmpty {
                    Text(badgeText)
                        .font(.caption.weight(.black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(drawerBadgeTint(for: badgeText), in: Capsule())
                }
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 3)
            .frame(minHeight: isCompact ? 40 : 46)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(drawerItemDragSuppressionGesture)
        .disabled(isClosing)
        .accessibilityLabel(title)
        .accessibilityIdentifier("app-drawer-\(destination.rawValue)")
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

    private func drawerBadgeText(for destination: AppDrawerDestination) -> String? {
        switch destination {
        case .notifications:
            return appState.unreadNotificationCount > 0 ? "\(appState.unreadNotificationCount)" : nil
        case .paymentSettings:
            return AppDrawerSettingsBadgePolicy.paymentBadgeText(
                methods: PaymentSettingsResolver.methods(settings: appState.paymentSettings, viewer: appState.viewer),
                hasAnyStoredData: PaymentSettingsResolver.hasAnyData(settings: appState.paymentSettings, viewer: appState.viewer)
            )
        case .exchangeSettings:
            return exchangeSettingsBadgeText
        default:
            return nil
        }
    }

    private func drawerBadgeTint(for value: String) -> Color {
        value.allSatisfy(\.isNumber) ? MegrumTheme.pink : MegrumTheme.conditionWarning
    }

    private var exchangeSettingsBadgeText: String? {
        let settings = HomeDefaultExchangeSettings(
            preferenceRawValue: exchangePreferenceRawValue,
            requiresSamePrefecture: exchangeRequiresSamePrefecture,
            requiresDateOverlap: exchangeRequiresDateOverlap,
            localPrefecture: exchangeLocalPrefecture,
            localDateKeysRawValue: exchangeLocalDateKeysRawValue,
            mailShippingFeeRawValue: exchangeMailShippingFeeRawValue,
            mailShippingDaysRawValue: exchangeMailShippingDaysRawValue
        )
        let hasSavedPreference = UserDefaults.standard.object(forKey: HomeExchangeSettingsStorageKeys.preference) != nil
        return AppDrawerSettingsBadgePolicy.exchangeBadgeText(
            settings: settings,
            isExplicitlyConfigured: exchangeConfiguredAt > 0 || hasSavedPreference
        )
    }

    private func select(_ destination: AppDrawerDestination) {
        guard !isClosing, !isSuppressingDrawerItemTap else {
            return
        }
        close {
            onSelectDestination(destination)
        }
    }

    private var drawerItemDragSuppressionGesture: some Gesture {
        DragGesture(minimumDistance: AppDrawerGestureResolver.drawerItemTapSuppressionDistance)
            .onChanged { value in
                guard AppDrawerGestureResolver.shouldSuppressDrawerItemTap(translation: value.translation) else {
                    return
                }
                isSuppressingDrawerItemTap = true
            }
            .onEnded { value in
                guard AppDrawerGestureResolver.shouldSuppressDrawerItemTap(translation: value.translation) else {
                    isSuppressingDrawerItemTap = false
                    return
                }
                isSuppressingDrawerItemTap = true
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + AppDrawerGestureResolver.drawerItemTapSuppressionDuration
                ) {
                    isSuppressingDrawerItemTap = false
                }
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
