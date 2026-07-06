import SwiftUI

/// 初回ガイドツアーの進行状態を保持するコーディネータ（章×ビートモデル）。
/// タブ自動遷移・オーバーレイ表示・割り込み抑制はこの `currentBeat` / `isActive` を参照して行う。
@MainActor
final class TutorialTourCoordinator: ObservableObject {
    @Published private(set) var currentBeat: TutorialBeat?

    var isActive: Bool { currentBeat != nil }

    /// 全体進捗（上部プログレスバー用、0.0〜1.0）。
    var overallProgress: Double {
        guard let beat = currentBeat, !TutorialScript.beats.isEmpty else { return 0 }
        return Double(TutorialScript.index(of: beat) + 1) / Double(TutorialScript.beats.count)
    }

    func start(at beat: TutorialBeat? = nil) {
        currentBeat = beat ?? TutorialScript.beats.first
    }

    /// 全面タップ or 「次へ」で前進。最後のビートを越えたら完了扱いで閉じる。
    func advance() {
        guard let beat = currentBeat, let index = TutorialScript.beats.firstIndex(of: beat) else { return }
        if index + 1 < TutorialScript.beats.count {
            currentBeat = TutorialScript.beats[index + 1]
        } else {
            currentBeat = nil
        }
    }

    /// 現在の章をとばして次章の先頭へ。最終章なら終了。
    func skipChapter() {
        guard let beat = currentBeat else { return }
        if let next = TutorialScript.firstBeatOfNextChapter(after: beat) {
            currentBeat = next
        } else {
            currentBeat = nil
        }
    }

    /// ツアー全体をスキップ（既読フラグ保存は呼び出し側の責務）。
    func skip() {
        currentBeat = nil
    }

    /// 明示終了（既読フラグ保存は呼び出し側の責務）。
    func finish() {
        currentBeat = nil
    }
}
