import MegrumDesign
import SwiftUI

extension View {
    @ViewBuilder
    func rootVisualQAProposalPresentation<Content: View>(
        item: Binding<HomeRelationRoute?>,
        @ViewBuilder content: @escaping (HomeRelationRoute) -> Content
    ) -> some View {
        #if os(iOS)
        fullScreenCover(item: item, content: content)
        #else
        sheet(item: item, content: content)
        #endif
    }
}

struct NativeLoadingScreen: View {
    var title: String

    var body: some View {
        VStack(spacing: 14) {
            ProgressView()
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MegrumTheme.canvas.ignoresSafeArea())
    }
}

struct NativeLoadingFailureScreen: View {
    var title: String
    var message: String
    var onRetry: () async -> Void
    var onSignOut: () async -> Void

    @State private var isRetrying = false
    @State private var isSigningOut = false

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Color.orange)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Text(message)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 10) {
                Button(action: retry) {
                    Label(isRetrying ? "再読み込み中" : "再読み込み", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(MegrumTheme.lavender)
                .disabled(isRetrying || isSigningOut)

                Button(role: .destructive, action: signOut) {
                    Label(isSigningOut ? "ログアウト中" : "ログアウトしてやり直す", systemImage: "rectangle.portrait.and.arrow.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isRetrying || isSigningOut)
            }
            .controlSize(.large)
            .padding(.top, 6)
        }
        .padding(28)
        .frame(maxWidth: 420)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MegrumTheme.canvas.ignoresSafeArea())
    }

    private func retry() {
        Task {
            isRetrying = true
            await onRetry()
            isRetrying = false
        }
    }

    private func signOut() {
        Task {
            isSigningOut = true
            await onSignOut()
            isSigningOut = false
        }
    }
}
