import Foundation
import MegrumData

/// 相手の求め（個別募集の選択肢／ほしいもの）と、自分のグッズの一致「確度」。
/// - confirmed：相手が指定した全軸（メンバー・種別・シリーズ）が自分側も記載あり＆一致（＝断定）。
/// - tentative：不一致は無いが、相手が指定した軸のどれかが自分側で無記載（＝断定できない「？」）。
/// nil は非マッチ（別値がある／グループや数量が合わない）。iter1226.363。
enum HomeCandidateMatchConfidence: Equatable, Sendable {
    case confirmed
    case tentative
}

enum HomeCandidateMatchConfidencePolicy {
    /// 1軸の判定。相手が指定していなければ問わない（ok）、自分が無記載なら不確定、別値なら不一致。
    enum AxisResult: Equatable {
        case ok
        case tentative
        case mismatch
    }

    static func idAxis(expected: UUID?, actual: UUID?) -> AxisResult {
        guard let expected else {
            return .ok
        }
        guard let actual else {
            return .tentative
        }
        return expected == actual ? .ok : .mismatch
    }

    static func seriesAxis(wanted: Set<String>, itemTags: Set<String>) -> AxisResult {
        guard !wanted.isEmpty else {
            return .ok
        }
        guard !itemTags.isEmpty else {
            return .tentative
        }
        return wanted.isDisjoint(with: itemTags) ? .mismatch : .ok
    }

    /// メンバー指定/除外。指定なし=ok、自分が無記載=不確定、それ以外は含む/含まないで判定。
    static func memberAxis(wishMemberIds: [UUID], excludes: Bool, actual: UUID?) -> AxisResult {
        guard !wishMemberIds.isEmpty else {
            return .ok
        }
        guard let actual else {
            return .tentative
        }
        let contains = wishMemberIds.contains(actual)
        if excludes {
            return contains ? .mismatch : .ok
        }
        return contains ? .ok : .mismatch
    }

    /// 全軸を統合。不一致が1つでもあれば非マッチ、不確定が1つでもあれば不確定、全部okなら確定。
    static func combine(_ axes: [AxisResult]) -> HomeCandidateMatchConfidence? {
        if axes.contains(.mismatch) {
            return nil
        }
        return axes.contains(.tentative) ? .tentative : .confirmed
    }

    static func better(
        _ lhs: HomeCandidateMatchConfidence?,
        _ rhs: HomeCandidateMatchConfidence
    ) -> HomeCandidateMatchConfidence {
        if lhs == .confirmed || rhs == .confirmed {
            return .confirmed
        }
        return .tentative
    }
}
