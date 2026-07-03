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
