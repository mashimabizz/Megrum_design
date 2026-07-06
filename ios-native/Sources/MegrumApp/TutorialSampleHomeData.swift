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
    /// 「求められているグッズ」のサンプルで「0件」表示にならないよう、求められ件数も付与する。
    static var conditionSignals: [UUID: HomeCandidateConditionSignals] {
        var signals = HomeCandidateConditionSignalDefaults.previewSignals(
            matchedItems: matchedItems,
            possibleItems: possibleItems
        )
        var seenIDs = Set<UUID>()
        let orderedItems = (matchedItems + possibleItems).filter { seenIDs.insert($0.id).inserted }
        for (index, item) in orderedItems.enumerated() where signals[item.id]?.linkCounts.wishCount == 0 {
            signals[item.id]?.linkCounts.wishCount = index % 3 + 1
        }
        return signals
    }
}
