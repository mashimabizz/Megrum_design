import Foundation

struct TagCandidatePreviewSelectionState: Equatable {
    var previewedName: String?

    func isPreviewing(_ name: String) -> Bool {
        previewedName == name
    }

    func isSelected(_ name: String, selectedNames: [String]) -> Bool {
        selectedNames.contains { $0.caseInsensitiveCompare(name) == .orderedSame }
    }

    func isDisabled(_ name: String, selectedNames: [String], maxSelection: Int) -> Bool {
        !isSelected(name, selectedNames: selectedNames) && selectedNames.count >= maxSelection
    }

    mutating func preview(_ name: String) {
        previewedName = name
    }

    mutating func clearPreview(ifMatches name: String) {
        if previewedName == name {
            previewedName = nil
        }
    }
}
