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

    private var header: some View {
        HStack {
            HStack {
                Button(action: onOpenSettings) {
                    HomeDiscoveryViewerAvatar(viewer: viewer)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("メニューを開く")

                Spacer(minLength: 0)
            }
            .frame(width: 94)

            Spacer()

            MegrumWordmark(width: 116)

            Spacer()

            HStack(spacing: 6) {
                Button(action: onOpenSearch) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(MegrumTheme.lavender)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("検索")

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
            .frame(width: 94)
        }
        .padding(.vertical, 2)
    }

    private var primaryTabSwipeProgress: CGFloat {
        CGFloat(selectedPrimaryTab.index)
    }
}

enum HomeDiscoveryHeaderMetrics {
    static let contentTopPadding: CGFloat = 122
    static let contentBottomPadding: CGFloat = FloatingActionLayoutMetrics.contentBottomPadding + 120
    static let pullRefreshIndicatorTopPadding: CGFloat = 114
}
