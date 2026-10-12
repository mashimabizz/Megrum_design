import Foundation

struct GoodsBulkTagSheetState: Equatable {
    var tagDraft = ""
    var selectedCandidateNames: [String] = []

    var trimmedTag: String {
        tagDraft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canApply: Bool {
        !trimmedTag.isEmpty
    }

    /// 入力中のインクリメンタル絞り込み（空なら全候補）。iter1226.412。
    func filteredCandidates(from candidateNames: [String]) -> [String] {
        let query = trimmedTag
        guard !query.isEmpty else {
            return candidateNames
        }
        let matched = candidateNames.filter {
            $0.range(of: query, options: [.caseInsensitive]) != nil
        }
        // 絞り込みで全滅した場合は誤入力の可能性が高いので全候補に戻す（選び直しやすさ優先）。
        return matched.isEmpty ? candidateNames : matched
    }

    /// 「◯◯を新しいシリーズとして追加」行を出すか＝入力があり既存候補と完全一致しない。iter1226.412。
    func showsNewSeriesRow(in candidateNames: [String]) -> Bool {
        let query = trimmedTag
        guard !query.isEmpty else {
            return false
        }
        return !candidateNames.contains { $0.caseInsensitiveCompare(query) == .orderedSame }
    }

    mutating func toggleCandidateTag(_ name: String) {
        if selectedCandidateNames.contains(where: { $0.caseInsensitiveCompare(name) == .orderedSame }) {
            selectedCandidateNames = []
            if trimmedTag.caseInsensitiveCompare(name) == .orderedSame {
                tagDraft = ""
            }
        } else {
            selectedCandidateNames = [name]
            tagDraft = name
        }
    }
}
