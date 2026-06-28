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
                .font(.title2.weight(.black))
                .foregroundStyle(MegrumTheme.ink)
                .frame(maxWidth: .infinity)

            HStack {
                Button("閉じる", action: onClose)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(MegrumTheme.ink)
                    .padding(.horizontal, 17)
                    .frame(minHeight: 44)
                    .background(Color.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 20))
                    .shadow(color: MegrumTheme.lavender.opacity(0.10), radius: 16, y: 8)

                Spacer(minLength: 0)
            }
        }
    }
}

struct HomeExchangeSettingsInstructionBanner: View {
    var body: some View {
        Label {
            Text("日付タップで場所とメモ、横ドラッグで複数日程を追加できます")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(MegrumTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "hand.tap.fill")
                .font(.title3.weight(.bold))
                .foregroundStyle(MegrumTheme.lavender)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        .background(Color.white.opacity(0.74), in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(MegrumTheme.lavender.opacity(0.14), lineWidth: 1)
        }
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
                    .font(.title3.weight(.black))
            }
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(
                LinearGradient(
                    colors: [MegrumTheme.lavender, MegrumTheme.lavender.opacity(0.82)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 18)
            )
            .shadow(color: MegrumTheme.lavender.opacity(0.28), radius: 18, y: 10)
        }
        .buttonStyle(.plain)
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
