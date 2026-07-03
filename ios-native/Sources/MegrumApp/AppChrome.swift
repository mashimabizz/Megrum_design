import MegrumDesign
import SwiftUI

private struct MegrumPinnedTopChromeInsetKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    /// Total height (status bar included) of translucent chrome pinned over
    /// scroll content by `megrumPinnedTranslucentTopChrome`. Scroll content
    /// inside pads its top by this amount so it starts below the chrome.
    var megrumPinnedTopChromeInset: CGFloat {
        get { self[MegrumPinnedTopChromeInsetKey.self] }
        set { self[MegrumPinnedTopChromeInsetKey.self] = newValue }
    }
}

private struct MegrumPinnedTopChromeHeightKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

extension View {
    @ViewBuilder
    func megrumHiddenNavigationBar() -> some View {
        #if os(iOS)
        self
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        #else
        self
        #endif
    }

    @ViewBuilder
    func megrumVisibleNavigationBar() -> some View {
        #if os(iOS)
        self
            .toolbar(.visible, for: .navigationBar)
        #else
        self
        #endif
    }

    @ViewBuilder
    func megrumInlineNavigationTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    /// Translucent glass behind pinned top chrome (title / tabs): scroll
    /// content stays visible through it, and the glass extends up through the
    /// status bar area.
    func megrumTranslucentTopChromeBackground() -> some View {
        background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.72)
                .ignoresSafeArea(edges: .top)
        }
    }

    /// Extends self under the top safe area and pins translucent chrome over
    /// it. The chrome's bottom edge in screen coordinates (status bar
    /// included) is reported through `bottomEdge` so scroll content — which
    /// now starts at the screen top — can inset itself below the chrome while
    /// still sliding beneath it.
    func megrumPinnedTranslucentTopChrome<Chrome: View>(
        bottomEdge: Binding<CGFloat>,
        @ViewBuilder chrome: () -> Chrome
    ) -> some View {
        ignoresSafeArea(.container, edges: .top)
            .overlay(alignment: .top) {
                chrome()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .megrumTranslucentTopChromeBackground()
                    .background {
                        GeometryReader { geometry in
                            Color.clear.preference(
                                key: MegrumPinnedTopChromeHeightKey.self,
                                value: geometry.frame(in: .global).maxY
                            )
                        }
                    }
            }
            .onPreferenceChange(MegrumPinnedTopChromeHeightKey.self) { newValue in
                Task { @MainActor in
                    bottomEdge.wrappedValue = newValue
                }
            }
    }

    func megrumTextFieldStyle() -> some View {
        self
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(MegrumTheme.ink)
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(Color.white.opacity(0.58), lineWidth: 1)
            }
    }
}
