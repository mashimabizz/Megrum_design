import SwiftUI

extension View {
    @ViewBuilder
    func groomViewerImmersiveOverlay<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        sourceAnchor: UnitPoint = .center,
        onDismiss: @escaping () -> Void = {},
        @ViewBuilder content: @escaping (Item, @escaping () -> Void) -> Content
    ) -> some View {
        #if os(iOS)
        ZStack {
            self

            // セーフエリア無視の全画面コンテナを常設し、その中でトランジションさせる。
            // 条件付きビュー自体に ignoresSafeArea を付けると、トランジション終了時に
            // セーフエリア拡張が非アニメーションで適用されて画像位置が「かくっ」とズレる。
            // iter1226.444：さらに、ビューア内部のセーフエリア解決がトランジション中に
            // レイアウトを動かし「枠（スケール変形）と中身（レイアウト）が別々に動く」
            // ガクつきが出ていたため、中身は常設コンテナの実寸（最終フルスクリーンサイズ）で
            // **固定レイアウト**し、拡大縮小はスケール変形だけにする。
            GeometryReader { fullScreenProxy in
                ZStack {
                    if let presentedItem = item.wrappedValue {
                        Color.black
                            .allowsHitTesting(false)
                            .transition(.opacity)
                            .zIndex(9_998)

                        content(presentedItem) {
                            item.wrappedValue = nil
                            onDismiss()
                        }
                        .megrumGroomViewerImmersivePresentationChrome()
                        .frame(width: fullScreenProxy.size.width, height: fullScreenProxy.size.height)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.08, anchor: sourceAnchor).combined(with: .opacity),
                            removal: .scale(scale: 0.08, anchor: sourceAnchor).combined(with: .opacity)
                        ))
                        .zIndex(9_999)
                    }
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(item.wrappedValue != nil)
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.86), value: item.wrappedValue?.id)
        #else
        self.sheet(item: item, onDismiss: onDismiss) { presentedItem in
            content(presentedItem) {
                item.wrappedValue = nil
                onDismiss()
            }
        }
        #endif
    }

    @ViewBuilder
    func megrumGroomViewerImmersivePresentationChrome() -> some View {
        #if os(iOS)
        // preferredColorScheme(.dark) はシーン全体をダーク化して
        // 閉じた時にライトへ戻るちらつきを生むため、環境値でビューア
        // サブツリーだけをダーク扱いにする。
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.ignoresSafeArea(.container, edges: .top))
            .ignoresSafeArea(.container, edges: .top)
            .environment(\.colorScheme, .dark)
        #else
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.ignoresSafeArea())
        #endif
    }
}
