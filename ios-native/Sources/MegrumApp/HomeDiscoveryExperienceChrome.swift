import MegrumDesign
import SwiftUI

extension HomeDiscoveryExperience {
    var pinnedHeader: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            HomeDiscoveryTabSwitcher(
                selection: $selectedPrimaryTab,
                swipeProgress: primaryTabSwipeProgress
            )
        }
            .padding(.top, 10)
            .padding(.bottom, 0)
            .frame(maxWidth: .infinity)
            .background {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .overlay(MegrumTheme.canvas.opacity(0.34))
                    .ignoresSafeArea(edges: .top)
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(.white.opacity(0.42))
                    .frame(height: 1)
            }
            .zIndex(10)
    }

    func primaryTabDragGesture(pageWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .local)
            .updating($primaryTabDragTranslation) { value, state, _ in
                guard abs(value.translation.width) > abs(value.translation.height) else {
                    return
                }
                state = value.translation.width
            }
    }

    private var header: some View {
        HStack {
            Button(action: onOpenSettings) {
                HomeDiscoveryViewerAvatar(viewer: viewer)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("メニューを開く")

            Spacer()

            Text("Megrum")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Spacer()

            Button {
                showsMatchHelp = true
            } label: {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(MegrumTheme.lavender)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("マッチ表示のヘルプを開く")
        }
        .padding(.vertical, 2)
    }

    private var primaryTabSwipeProgress: CGFloat {
        let selectedIndex = CGFloat(selectedPrimaryTab.index)
        let rawProgress = selectedIndex - (primaryTabDragTranslation / max(1, primaryTabPageWidth))
        let maximumProgress = CGFloat(HomeDiscoveryPrimaryTab.allCases.count - 1)
        return min(max(rawProgress, 0), maximumProgress)
    }
}

enum HomeDiscoveryHeaderMetrics {
    static let contentTopPadding: CGFloat = 122
}
