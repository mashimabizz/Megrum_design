import MegrumDesign
import SwiftUI

extension HomeDiscoveryExperience {
    func pinnedHeader(isCollapsed: Bool) -> some View {
        VStack(spacing: 0) {
            if !isCollapsed {
                header
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                    .transition(MegrumTopChromeCollapseAnimation.titleTransition)
            }
        }
            .padding(.top, 10)
            .padding(.bottom, 0)
            .frame(maxWidth: .infinity)
            .megrumTranslucentTopChromeBackground()
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
    static let contentTopPadding: CGFloat = 82
    static let contentBottomPadding: CGFloat = FloatingActionLayoutMetrics.contentBottomPadding + 120
    static let pullRefreshIndicatorTopPadding: CGFloat = 74
}

/// 候補が1件もない時（新規ユーザー等）の導線カード。
/// 推しを増やすか、ほしいものを登録すればマッチ候補が並び始めることを伝える。
struct HomeEmptyCandidateCTACard: View {
    var onAddOshi: () -> Void
    var onAddWish: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(MegrumTheme.lavender)
                Text("マッチ候補を見つけよう")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
            }

            Text("推しを設定したり、ほしいものを登録すると、あなたに合う交換相手の候補がここに並びます。")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                Button {
                    MegrumHaptics.performButtonTap(onAddOshi)
                } label: {
                    Label("推しを追加する", systemImage: "star.fill")
                        .font(.system(size: 13.5, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(MegrumTheme.lavender, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    MegrumHaptics.performButtonTap(onAddWish)
                } label: {
                    Label("ほしいものを登録", systemImage: "heart.fill")
                        .font(.system(size: 13.5, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(.white, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .strokeBorder(MegrumTheme.lavender.opacity(0.4), lineWidth: 1.2)
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(MegrumTheme.lavender.opacity(0.16), lineWidth: 1)
        }
    }
}
