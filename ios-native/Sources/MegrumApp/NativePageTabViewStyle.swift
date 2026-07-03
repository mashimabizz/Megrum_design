import SwiftUI

extension View {
    @ViewBuilder
    func megrumPageTabViewStyle() -> some View {
        #if os(iOS)
        self.tabViewStyle(.page(indexDisplayMode: .never))
        #else
        self
        #endif
    }

    @ViewBuilder
    func megrumHiddenBottomScrollEdgeEffect() -> some View {
        #if os(iOS)
        if #available(iOS 26.0, *) {
            self.scrollEdgeEffectHidden(for: .bottom)
        } else {
            self
        }
        #else
        self
        #endif
    }

}

/// Progressive blur pinned over the status bar: fully frosted at the screen
/// edge, fading to clear so it reads as transparent until content scrolls
/// beneath it.
struct MegrumStatusBarProgressiveBlur: View {
    var topSafeAreaInset: CGFloat

    private var bandHeight: CGFloat {
        topSafeAreaInset + 16
    }

    var body: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .mask {
                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0.72), location: 0),
                        .init(color: .black.opacity(0.72), location: 0.5),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .frame(height: bandHeight)
            .offset(y: -topSafeAreaInset)
            .allowsHitTesting(false)
    }
}
