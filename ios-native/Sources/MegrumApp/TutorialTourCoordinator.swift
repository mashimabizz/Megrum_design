import SwiftUI

/// ツアーの再生範囲。ヘルプからの部分再生では1章だけ再生して終わる。
enum TutorialPlaybackScope: Equatable {
    case full
    case chapter(TutorialChapter)
}

/// 初回ガイドツアーの進行状態を保持するコーディネータ（章×ビートモデル）。
/// タブ自動遷移・オーバーレイ表示・割り込み抑制はこの `currentBeat` / `isActive` を参照して行う。
@MainActor
final class TutorialTourCoordinator: ObservableObject {
    @Published private(set) var currentBeat: TutorialBeat?
    private(set) var scope: TutorialPlaybackScope = .full

    var isActive: Bool { currentBeat != nil }

    /// 全体進捗（上部プログレスバー用、0.0〜1.0）。章再生時は章内進捗。
    var overallProgress: Double {
        guard let beat = currentBeat else { return 0 }
        switch scope {
        case .full:
            guard !TutorialScript.beats.isEmpty else { return 0 }
            return Double(TutorialScript.index(of: beat) + 1) / Double(TutorialScript.beats.count)
        case .chapter:
            let progress = TutorialScript.chapterProgress(of: beat)
            return Double(progress.index) / Double(max(1, progress.count))
        }
    }

    /// 1つ前のビートへ戻れるか（章再生では章の先頭まで）。
    var canRetreat: Bool {
        guard let beat = currentBeat, let index = TutorialScript.beats.firstIndex(of: beat), index > 0 else {
            return false
        }
        let previous = TutorialScript.beats[index - 1]
        if case .chapter(let chapter) = scope {
            return previous.chapter == chapter
        }
        return true
    }

    func start(at beat: TutorialBeat? = nil, scope: TutorialPlaybackScope = .full) {
        self.scope = scope
        currentBeat = beat ?? TutorialScript.beats.first
    }

    /// ヘルプからの章別再生：その章の先頭から再生し、章が終わったら閉じる。
    func startChapter(_ chapter: TutorialChapter) {
        let head = TutorialScript.beats.first { $0.chapter == chapter }
        start(at: head, scope: .chapter(chapter))
    }

    /// 全面タップ or 「次へ」で前進。範囲の最後を越えたら完了扱いで閉じる。
    func advance() {
        guard let beat = currentBeat, let index = TutorialScript.beats.firstIndex(of: beat) else { return }
        guard index + 1 < TutorialScript.beats.count else {
            currentBeat = nil
            return
        }
        let next = TutorialScript.beats[index + 1]
        if case .chapter(let chapter) = scope, next.chapter != chapter {
            currentBeat = nil
            return
        }
        currentBeat = next
    }

    /// 吹き出しの「戻る」：1つ前のビートへ（範囲の先頭では何もしない）。
    func retreat() {
        guard canRetreat,
              let beat = currentBeat,
              let index = TutorialScript.beats.firstIndex(of: beat)
        else { return }
        currentBeat = TutorialScript.beats[index - 1]
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
