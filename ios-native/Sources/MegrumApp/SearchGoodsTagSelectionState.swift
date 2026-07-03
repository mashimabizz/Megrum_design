import Foundation

struct SearchGoodsTagSelectionState: Equatable {
    var searchText = ""

    var normalizedSearchText: String {
        searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "#＃"))
    }

    func filteredCandidateNames(from candidateNames: [String]) -> [String] {
        let normalized = normalizedSearchText
        guard !normalized.isEmpty else {
            return candidateNames
        }
        return candidateNames.filter { $0.localizedCaseInsensitiveContains(normalized) }
    }

    func canAddSearchText(selectedTags: Set<String>) -> Bool {
        let normalized = normalizedSearchText
        guard !normalized.isEmpty else {
            return false
        }
        return !containsTag(normalized, in: selectedTags)
    }

    func containsTag(_ tagName: String, in selectedTags: Set<String>) -> Bool {
        selectedTags.contains { $0.localizedCaseInsensitiveCompare(tagName) == .orderedSame }
    }

    mutating func clearSearch() {
        searchText = ""
    }
}
