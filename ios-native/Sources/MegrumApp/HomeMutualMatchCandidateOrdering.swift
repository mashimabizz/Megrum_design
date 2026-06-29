import Foundation
import MegrumCore

enum HomeMutualMatchCandidateOrdering {
    static func prioritized(
        _ candidates: [HomeMutualMatchCandidateData],
        limit: Int = 12
    ) -> [HomeMutualMatchCandidateData] {
        candidates
            .sorted { lhs, rhs in
                let lhsScore = HomeMutualMatchCandidateSignals.attentionScore(lhs.attentionKinds)
                let rhsScore = HomeMutualMatchCandidateSignals.attentionScore(rhs.attentionKinds)
                if lhsScore == rhsScore {
                    return lhs.id.uuidString < rhs.id.uuidString
                }
                return lhsScore < rhsScore
            }
            .prefix(limit)
            .map { $0 }
    }
}
