import MegrumCore
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

            GroomViewerImmersiveHost(
                item: item,
                sourceAnchor: sourceAnchor,
                onDismiss: onDismiss,
                content: content
            )
        }
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

/// iter1226.448：ホストの開くアニメーションが実際に完了したかをビューアへ伝える。
/// nil = ホスト以外の提示（fullScreenCover等）で、ビューア側はタイマーでフォールバックする。
private struct GroomViewerOpenSettledKey: EnvironmentKey {
    static let defaultValue: Bool? = nil
}

extension EnvironmentValues {
    var megrumGroomViewerOpenSettled: Bool? {
        get { self[GroomViewerOpenSettledKey.self] }
        set { self[GroomViewerOpenSettledKey.self] = newValue }
    }
}

#if os(iOS)
/// iter1226.447：開くアニメーション開始前に準備を待つ対象（主画像）を伝えるための契約。
/// 準拠していない Item は従来どおり即開く。
protocol GroomViewerImmersiveItem {
    var openReadyImageURL: URL? { get }
}

extension GroomPost: GroomViewerImmersiveItem {
    var openReadyImageURL: URL? { imageURL }
}

/// グルームビューアの没入表示ホスト（iter1226.445 全面書き換え）。
///
/// 以前は `.transition(.scale)` ＋ コンテナの `.animation(_:value:)` で開閉していたが、
/// 挿入直後に走るビューア内部のレイアウト確定（セーフエリアの多段解決・scaledToFit の
/// 再計算など）まで環境アニメーションで**補間**されてしまい、「枠はスケール変形・中身は
/// レイアウトアニメ」で別々に動くガクつきが出ていた（録画のフレーム計測で、写真の
/// アスペクト比がアニメ中に 1.31→1.366 へ変化していたのが証拠）。
///
/// 対策として、開閉を **progress 駆動の明示 scaleEffect（純粋なレンダ変形）** に変更：
/// - 中身は常設フルスクリーンコンテナの実寸で**最初から最終レイアウト**（レイアウトは一切アニメしない）
/// - `compositingGroup` で面全体を1枚に合成してから拡大縮小（枠と中身が完全に一体）
/// - 環境アニメーション（.animation(value:)）は使わない
private struct GroomViewerImmersiveHost<Item: Identifiable, Content: View>: View {
    @Binding var item: Item?
    var sourceAnchor: UnitPoint
    var onDismiss: () -> Void
    @ViewBuilder var content: (Item, @escaping () -> Void) -> Content

    /// 表示中アイテム（閉じアニメーションの間も保持して面を描き続ける）。
    @State private var presentedItem: Item?
    /// 0=閉じた状態、1=全開。これだけをアニメーションする。
    @State private var progress: Double = 0
    /// 開く準備待ちの世代（連打・閉じで古い待ちを破棄する）。
    @State private var openGeneration: Int = 0
    /// 開くスプリングが実際に完了したか（ビューアの「重い処理の解禁」タイミングを同期させる）。
    @State private var hasOpenSettled = false

    private static var openAnimation: Animation {
        // iter1226.450：開閉を速く（response 0.34→0.26）。めぐり/マップ経路の開き心地を機敏に。
        .spring(response: 0.26, dampingFraction: 0.85)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if let presentedItem {
                    Color.black
                        .opacity(progress)
                        .allowsHitTesting(false)

                    content(presentedItem) {
                        dismissFromContent()
                    }
                    .environment(\.megrumGroomViewerOpenSettled, hasOpenSettled)
                    .megrumGroomViewerImmersivePresentationChrome()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .groomOpenMetricsProbe("hostFace")
                    .compositingGroup()
                    .scaleEffect(0.08 + 0.92 * progress, anchor: sourceAnchor)
                    .opacity(progress)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(item != nil)
        .onAppear {
            // タブ復帰などで表示状態のまま再マウントされた場合は即・全開で復元する。
            if let item {
                presentedItem = item
                progress = 1
                hasOpenSettled = true
            }
        }
        .onChange(of: item?.id) { _, newID in
            if newID != nil, let newItem = item {
                GroomOpenMetricsLog.emit("host", "open-request")
                presentedItem = newItem
                hasOpenSettled = false
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    progress = 0
                }
                // iter1226.447：主画像がキャッシュ済みになるまで開くアニメーションを待つ
                //（最大0.6秒）。「枠が先に開き、写真が後から違う大きさで現れる」事象を
                // 構造的に防ぐ。progress=0 の間もコンテンツはマウント済みなので、
                // 内部レイアウトはこの間に確定する。
                let generation = openGeneration + 1
                openGeneration = generation
                Task { @MainActor in
                    if let url = (newItem as? GroomViewerImmersiveItem)?.openReadyImageURL {
                        _ = await GroomImageMemoryStore.shared.ensureLoaded(
                            url: url,
                            timeoutNanoseconds: 900_000_000
                        )
                    }
                    guard openGeneration == generation, item?.id != nil else {
                        return
                    }
                    GroomOpenMetricsLog.emit("host", "animate-open")
                    withAnimation(Self.openAnimation) {
                        progress = 1
                    } completion: {
                        guard openGeneration == generation else { return }
                        GroomOpenMetricsLog.emit("host", "open-settled")
                        hasOpenSettled = true
                    }
                }
            } else if newID == nil {
                openGeneration += 1
                hasOpenSettled = false
                withAnimation(Self.openAnimation) {
                    progress = 0
                } completion: {
                    if item == nil {
                        presentedItem = nil
                    }
                }
            }
        }
    }

    private func dismissFromContent() {
        item = nil
        onDismiss()
    }
}
#endif
