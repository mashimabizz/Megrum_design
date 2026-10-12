import MegrumDesign
import SwiftUI

struct HomeExchangeSettingsBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                MegrumTheme.canvas,
                MegrumTheme.lavender.opacity(0.12),
                Color.white
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct HomeExchangeSettingsHeader: View {
    var onClose: () -> Void

    var body: some View {
        ZStack {
            Text("交換条件")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .frame(maxWidth: .infinity)

            HStack {
                Button("閉じる", action: onClose)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .padding(.horizontal, 14)
                    .frame(height: 36)
                    .background(MegrumTheme.ink.opacity(0.045), in: Capsule())

                Spacer(minLength: 0)
            }
        }
    }
}

struct HomeExchangeSettingsInstructionBanner: View {
    var body: some View {
        Label {
            Text("日付タップで場所とメモ、横ドラッグで複数日程を追加できます")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(MegrumTheme.ink.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(MegrumTheme.lavender)
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
        .background(MegrumTheme.lavender.opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct HomeExchangeSettingsSaveFooter: View {
    var isSaving = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isSaving {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                }
                Text("保存")
            }
        }
        .buttonStyle(.megrumPrimary)
        .disabled(isSaving)
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(.ultraThinMaterial)
    }
}

extension View {
    @ViewBuilder
    func homeExchangeSettingsNavigationBarHidden() -> some View {
        #if os(iOS)
        toolbar(.hidden, for: .navigationBar)
        #else
        self
        #endif
    }
}
