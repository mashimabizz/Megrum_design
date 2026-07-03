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

    private let iconSize: CGFloat = 120

    var body: some View {
        GeometryReader { proxy in
            let iconCenter = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let spinnerCenterY = (iconCenter.y + (iconSize / 2) + proxy.size.height) / 2

            Color.white.ignoresSafeArea()

            Image("LaunchIcon", bundle: .main)
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .position(iconCenter)
                .accessibilityLabel(Text(title))

            ProgressView()
                .controlSize(.large)
                .tint(MegrumTheme.lavender)
                .position(x: iconCenter.x, y: spinnerCenterY)
                .accessibilityLabel("読み込み中")
        }
        .ignoresSafeArea()
    }
}

struct NativeLoadingFailureScreen: View {
    var title: String
    var message: String
    var onRetry: () async -> Void
    var onSignOut: () async -> Void

    @State private var presentationState = NativeLoadingFailurePresentationState()

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
                    Label(presentationState.retryTitle, systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(MegrumTheme.lavender)
                .disabled(presentationState.actionsDisabled)

                Button(role: .destructive, action: signOut) {
                    Label(presentationState.signOutTitle, systemImage: "rectangle.portrait.and.arrow.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(presentationState.actionsDisabled)
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
            presentationState.beginRetry()
            await onRetry()
            presentationState.finishRetry()
        }
    }

    private func signOut() {
        Task {
            presentationState.beginSignOut()
            await onSignOut()
            presentationState.finishSignOut()
        }
    }
}
