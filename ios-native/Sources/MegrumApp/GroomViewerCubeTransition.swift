import Foundation

/// グルームビューアの投稿者切替（直方体＝キューブ回転）を、
/// タップ・スワイプ・自動送りで共通化した遷移状態（iter1226.467）。
///
/// 以前はタップ経路だけ `captureViewerSnapshot()`（`UIGraphicsImageRenderer` +
/// `window.drawHierarchy` の全画面ラスタライズ）を同期実行し、さらに回転を
/// 始める前に `currentIndex` を変更していた。そのため回転前に全画面再評価・
/// `.task` 再発火・進捗リセットが走り、カクついていた。
///
/// 本状態はスワイプ経路と同じく「source/target の実ビューを回し、完了時にだけ
/// `currentIndex` を commit する」方式へ統一する。スナップショットは使わない。
///
/// UIKit 非依存（UIImage を持たない）なので、判定ロジックをホスト側テストで
/// 直接検証できる。
struct GroomViewerCubeTransition: Equatable {
    /// 遷移の発生源。進捗の進め方（指追従 or 時間アニメーション）が異なる。
    enum Origin: Equatable {
        /// 横スワイプ（指追従で progress を更新）。
        case gesture
        /// 左右タップ（progress を 0→1 へアニメーション）。
        case tap
        /// ストーリー自動送り（tap と同じくアニメーション）。
        case automatic
    }

    /// 回転開始時に表示していた面（＝現在の `currentIndex`）。commit まで変えない。
    var sourceIndex: Int
    /// 回転後に表示する面（切替先）。
    var targetIndex: Int
    /// +1 = 次へ（左方向へ抜ける）／-1 = 前へ。
    var direction: Int
    /// 0（source が正面）〜 1（target が正面）。
    var progress: Double
    var origin: Origin
    var id = UUID()
}

/// タップ／自動送り時の切替判断（純粋関数・テスト対象）。
enum GroomViewerCubeMoveDecision: Equatable {
    /// 回転せず `currentIndex` を即変更（同一投稿者・Reduce Motion・未settled）。
    case immediate(index: Int)
    /// 投稿者境界：キューブ回転を開始する（この時点では index を変えない）。
    case transition(source: Int, target: Int, direction: Int)
    /// 末尾から先へ進もうとした：ビューアを閉じる。
    case dismiss
    /// 何もしない（範囲外の戻り／回転中の追加操作＝直列化）。
    case ignore
}

/// タップ／自動送りの切替判断と、スワイプの確定判定を担う純粋ロジック。
/// View（`GroomViewerScreen`）の状態遷移をテスト可能にするために切り出す。
enum GroomViewerCubeTransitionPlanner {
    /// タップ／自動送りで隣の面へ動く時の判断。
    /// - `hasActiveTransition` が true（回転中）の間は連打を無視して二重遷移を防ぐ。
    /// - 投稿者が変わり、かつ Reduce Motion でなく開くアニメが落ち着いていれば回転。
    /// - それ以外（同一投稿者・Reduce Motion・未settled）は即切替。
    static func decideMove(
        authorIDs: [UUID],
        currentIndex: Int,
        delta: Int,
        reduceMotion: Bool,
        isOpeningSettled: Bool,
        hasActiveTransition: Bool
    ) -> GroomViewerCubeMoveDecision {
        // 回転中の追加タップは無視（遷移を直列化して二重遷移を防ぐ）。
        if hasActiveTransition {
            return .ignore
        }
        let nextIndex = currentIndex + delta
        guard authorIDs.indices.contains(nextIndex) else {
            // 末尾から先へ進む＝閉じる。先頭から前へは何もしない。
            return delta > 0 ? .dismiss : .ignore
        }
        guard authorIDs.indices.contains(currentIndex) else {
            return .immediate(index: nextIndex)
        }
        let switchesAuthor = authorIDs[nextIndex] != authorIDs[currentIndex]
        if switchesAuthor, !reduceMotion, isOpeningSettled {
            return .transition(
                source: currentIndex,
                target: nextIndex,
                direction: delta >= 0 ? 1 : -1
            )
        }
        return .immediate(index: nextIndex)
    }

    /// スワイプで指を離した時、切替を確定するか（従来のしきい値ロジックを純粋関数化）。
    static func swipeCommits(progress: Double, predicted: Double) -> Bool {
        progress > GroomViewerCubeGeometry.commitProgressThreshold
            || predicted > GroomViewerCubeGeometry.commitPredictedThreshold
    }
}
