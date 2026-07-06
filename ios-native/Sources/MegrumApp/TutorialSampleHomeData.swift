import Foundation
import MegrumCore

/// ガイドツアー中だけホームに流し込むサンプル候補。
/// `PreviewMegrumRepository.loadHomeCandidateSections()` と同じ組み立てで、
/// 実データ（新規ユーザーは空）を汚さずに「候補が並んだ本物のレイアウト」を見せる。
enum TutorialSampleHomeData {
    static var matchedItems: [GoodsItem] {
        NativePreviewData.homeMatchedItems
    }

    static var possibleItems: [GoodsItem] {
        NativePreviewData.homePossibleItems
    }

    /// マッチ判定フィルタ（isMemberTagMatchEligible 等）を通すため、候補とペアで必要になるシグナル。
    static var conditionSignals: [UUID: HomeCandidateConditionSignals] {
        HomeCandidateConditionSignalDefaults.previewSignals(
            matchedItems: matchedItems,
            possibleItems: possibleItems
        )
    }
}
