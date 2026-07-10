import SwiftUI

#if os(iOS)
import UIKit

/// ホーム左スワイプ→めぐりメッセージ一覧の指追従オープン用の状態（iter1226.427）。
/// オフセットはこのモデルを観測する最小のビューだけが再描画するため、
/// TabContentView 全体の再評価（カクつきの原因）を起こさない。
@MainActor
final class MeguriInboxOpenDragModel: ObservableObject {
    /// nil=ドラッグ外、値=一覧コンテンツのXオフセット（画面幅=閉 … 0=全開）。
    @Published var offset: CGFloat?
}

/// SwiftUI の DragGesture ではなく UIKit のパン認識を使う（iter1226.427）。
/// 認識が始まった瞬間に UIKit が配下のタッチをキャンセルするため、
/// チャットルーム行・グルームタイル・グッズ画像の上をなぞっても
/// タップが同時発火しない。縦スクロールは shouldBegin の水平判定で妨げない。
private struct MeguriInboxOpenPanAttachment: UIViewRepresentable {
    let model: MeguriInboxOpenDragModel
    let isEnabled: () -> Bool
    let onCommit: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(model: model, isEnabled: isEnabled, onCommit: onCommit)
    }

    func makeUIView(context: Context) -> AttachmentView {
        let view = AttachmentView()
        view.coordinator = context.coordinator
        return view
    }

    func updateUIView(_ uiView: AttachmentView, context: Context) {
        context.coordinator.isEnabled = isEnabled
        context.coordinator.onCommit = onCommit
    }

    /// ゼロサイズの背景ビュー。ホームコンテンツを包む先祖ビューへパンを取り付ける。
    final class AttachmentView: UIView {
        var coordinator: Coordinator?
        private var attachedPan: UIPanGestureRecognizer?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard window != nil, attachedPan == nil, let coordinator else {
                return
            }
            // ホームタブのコンテンツ全域でタッチを受けるため、十分に広い先祖へ付ける。
            var host: UIView? = superview
            while let current = host, current.bounds.width < UIScreen.main.bounds.width - 1 {
                host = current.superview
            }
            guard let target = host else {
                return
            }
            let pan = UIPanGestureRecognizer(target: coordinator, action: #selector(Coordinator.handlePan(_:)))
            pan.maximumNumberOfTouches = 1
            pan.delegate = coordinator
            target.addGestureRecognizer(pan)
            attachedPan = pan
        }

        deinit {
            if let attachedPan {
                attachedPan.view?.removeGestureRecognizer(attachedPan)
            }
        }
    }

    @MainActor
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        private let model: MeguriInboxOpenDragModel
        var isEnabled: () -> Bool
        var onCommit: () -> Void
        private var isTracking = false

        init(model: MeguriInboxOpenDragModel, isEnabled: @escaping () -> Bool, onCommit: @escaping () -> Void) {
            self.model = model
            self.isEnabled = isEnabled
            self.onCommit = onCommit
        }

        private var screenWidth: CGFloat {
            max(UIScreen.main.bounds.width, 320)
        }

        nonisolated func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer, let view = pan.view else {
                return false
            }
            let velocity = pan.velocity(in: view)
            let translation = pan.translation(in: view)
            // iter1226.430：スワイプした瞬間からパネルを出す。UIPan標準の約10pt
            // ヒステリシス後の初回判定で、左向きかつ水平優位ならすぐ開始する
            //（しきい値が高いと、判定失敗＝そのタッチでは二度と始まらないため
            // 「かなりスワイプしないと出ない」ように見えていた）。
            let isMovingLeft = translation.x < 0 || (translation.x == 0 && velocity.x < 0)
            let horizontalDominant = abs(translation.x) > abs(translation.y)
                || (translation == .zero && abs(velocity.x) > abs(velocity.y))
            guard isMovingLeft, horizontalDominant else {
                return false
            }
            return MainActor.assumeIsolated { isEnabled() }
        }

        @objc func handlePan(_ pan: UIPanGestureRecognizer) {
            guard let view = pan.view else {
                return
            }
            let translation = pan.translation(in: view)
            switch pan.state {
            case .began, .changed:
                isTracking = true
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    model.offset = min(max(screenWidth + translation.x, 0), screenWidth)
                }
            case .ended, .cancelled, .failed:
                guard isTracking else {
                    return
                }
                isTracking = false
                let velocity = pan.velocity(in: view)
                let shouldOpen = pan.state == .ended
                    && (-translation.x > MegrumSlidePresentationMetrics.minimumTranslation || velocity.x < -600)
                if shouldOpen {
                    onCommit()
                    withAnimation(MegrumSlidePresentationMetrics.animation) {
                        model.offset = 0
                    }
                } else {
                    withAnimation(MegrumSlidePresentationMetrics.animation) {
                        model.offset = screenWidth
                    }
                }
                // アニメ完了後にドラッグ用オフセットを解除（以後は isPresented ベースの表示へ）。
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) { [weak model] in
                    model?.offset = nil
                }
            default:
                break
            }
        }
    }
}

extension View {
    /// ホームタブのコンテンツに付ける：左スワイプでめぐりメッセージ一覧を指追従オープン。
    func meguriInboxOpenPanGesture(
        model: MeguriInboxOpenDragModel,
        isEnabled: @escaping () -> Bool,
        onCommit: @escaping () -> Void
    ) -> some View {
        background {
            MeguriInboxOpenPanAttachment(model: model, isEnabled: isEnabled, onCommit: onCommit)
                .frame(width: 0, height: 0)
                .allowsHitTesting(false)
        }
    }
}
#else
@MainActor
final class MeguriInboxOpenDragModel: ObservableObject {
    @Published var offset: CGFloat?
}

extension View {
    func meguriInboxOpenPanGesture(
        model: MeguriInboxOpenDragModel,
        isEnabled: @escaping () -> Bool,
        onCommit: @escaping () -> Void
    ) -> some View {
        self
    }
}
#endif
