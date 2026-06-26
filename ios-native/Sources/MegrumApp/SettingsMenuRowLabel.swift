import MegrumDesign
import SwiftUI

struct SettingsMenuRowLabel: View {
    var title: String
    var subtitle: String
    var systemImage: String
    var badgeCount: Int = 0

    var body: some View {
        Label {
            if badgeCount > 0 {
                HStack(spacing: 10) {
                    SettingsMenuRowTextStack(title: title, subtitle: subtitle)
                    Spacer()
                    SettingsMenuRowBadge(count: badgeCount)
                }
            } else {
                SettingsMenuRowTextStack(title: title, subtitle: subtitle)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(MegrumTheme.lavender)
        }
    }
}

private struct SettingsMenuRowTextStack: View {
    var title: String
    var subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.body.weight(.semibold))
            Text(subtitle)
                .font(.caption.weight(.semibold))
                .foregroundStyle(MegrumTheme.muted)
        }
    }
}

private struct SettingsMenuRowBadge: View {
    var count: Int

    var body: some View {
        Text("\(count)")
            .font(.caption.weight(.black))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(MegrumTheme.pink, in: Capsule())
    }
}

struct SettingsSignOutButtonRow: View {
    var isSigningOut: Bool
    var onTap: () -> Void

    var body: some View {
        Button(role: .destructive, action: onTap) {
            HStack {
                Label("ログアウト", systemImage: "rectangle.portrait.and.arrow.right")
                if isSigningOut {
                    Spacer()
                    ProgressView()
                        .controlSize(.small)
                }
            }
        }
        .disabled(isSigningOut)
    }
}

struct SettingsPushNotificationRow: View {
    var statusText: String
    var isEnabled: Bool
    var isLoading: Bool
    var isSaving: Bool
    var onToggle: @MainActor (Bool) -> Void

    var body: some View {
        HStack(spacing: 12) {
            SettingsMenuRowLabel(
                title: "モバイル通知",
                subtitle: statusText,
                systemImage: "iphone.radiowaves.left.and.right"
            )

            Spacer(minLength: 12)

            if isLoading {
                ProgressView()
                    .controlSize(.small)
            } else {
                Toggle(
                    "モバイル通知",
                    isOn: Binding(
                        get: { isEnabled },
                        set: { enabled in
                            onToggle(enabled)
                        }
                    )
                )
                .labelsHidden()
                .disabled(isSaving)
            }
        }
    }
}
