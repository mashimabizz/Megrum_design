import SwiftUI

/// 初回ガイドツアーの進行状態を保持するコーディネータ。
/// タブ自動遷移・オーバーレイ表示・割り込み抑制はこの `currentStep` / `isActive` を参照して行う。
@MainActor
final class TutorialTourCoordinator: ObservableObject {
    @Published private(set) var currentStep: TutorialTourStep?

    var isActive: Bool { currentStep != nil }

    func start(at step: TutorialTourStep = .welcome) {
        currentStep = step
    }

    /// 全面タップ or 「次へ」で前進。最後のステップを越えたら完了扱いで閉じる。
    func advance() {
        guard let step = currentStep else { return }
        if let next = TutorialTourStep(rawValue: step.rawValue + 1) {
            currentStep = next
        } else {
            currentStep = nil
        }
    }

    /// スキップ（既読フラグ保存は呼び出し側の責務）。
    func skip() {
        currentStep = nil
    }

    /// 明示終了（既読フラグ保存は呼び出し側の責務）。
    func finish() {
        currentStep = nil
    }
}
