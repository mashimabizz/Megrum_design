import Foundation

/// ユーザーID（handle）の重複チェックと代替候補の純ロジック（iter1226.422）。
/// 「megrum → megrum_xxxx に勝手に変わる」を廃止し、重複時はNG＋空いている候補を提示する。
public struct AccountHandleAvailability: Equatable, Sendable {
    public var isAvailable: Bool
    public var suggestions: [String]

    public init(isAvailable: Bool, suggestions: [String]) {
        self.isAvailable = isAvailable
        self.suggestions = suggestions
    }
}

enum AccountHandleSuggestionLogic {
    static let maxHandleLength = 20
    static let suggestionLimit = 3

    /// 入力IDに似た候補（数字サフィックス）を生成する。20文字制限を超える分は基部を詰める。
    static func candidates(for base: String) -> [String] {
        let suffixes = (1...9).map(String.init) + ["01", "02", "03", "2026"]
        var seen = Set<String>()
        var results: [String] = []
        for suffix in suffixes {
            let trimmedBase = String(base.prefix(maxHandleLength - suffix.count))
            guard trimmedBase.count >= 2 else {
                continue
            }
            let candidate = trimmedBase + suffix
            if candidate != base, seen.insert(candidate).inserted {
                results.append(candidate)
            }
        }
        return results
    }

    /// 使用済みIDの集合（小文字）を除いた候補を、生成順に最大 limit 件返す。
    static func availableSuggestions(
        for base: String,
        takenLowercased: Set<String>,
        limit: Int = suggestionLimit
    ) -> [String] {
        candidates(for: base)
            .filter { !takenLowercased.contains($0.lowercased()) }
            .prefix(limit)
            .map { $0 }
    }
}
