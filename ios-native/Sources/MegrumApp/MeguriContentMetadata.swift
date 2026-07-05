import Foundation
import MegrumCore

struct MeguriContentMetadataDraft: Equatable, Sendable, Codable {
    var groupID: UUID?
    var characterID: UUID?
    var seriesName = ""

    var normalizedSeriesName: String? {
        let trimmed = seriesName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    mutating func selectGroup(_ group: OshiGroup?) {
        groupID = group?.id
        characterID = nil
    }

    mutating func selectCharacter(_ character: OshiCharacter?) {
        characterID = character?.id
    }
}

struct MeguriContentFilterState: Equatable, Sendable {
    var draft = MeguriContentMetadataDraft()

    var hasActiveFilters: Bool {
        draft.groupID != nil || draft.characterID != nil || draft.normalizedSeriesName != nil
    }

    func matches(groom: GroomPost) -> Bool {
        matches(groupID: groom.groupID, characterID: groom.characterID, seriesName: groom.seriesName)
    }

    func matches(thread: BoardThread) -> Bool {
        matches(groupID: thread.groupID, characterID: thread.characterID, seriesName: thread.seriesName)
    }

    mutating func reset() {
        draft = MeguriContentMetadataDraft()
    }

    private func matches(groupID: UUID?, characterID: UUID?, seriesName: String?) -> Bool {
        guard hasActiveFilters else {
            return true
        }
        if let selectedGroupID = draft.groupID, groupID != selectedGroupID {
            return false
        }
        if let selectedCharacterID = draft.characterID, characterID != selectedCharacterID {
            return false
        }
        if let selectedSeries = draft.normalizedSeriesName {
            guard let seriesName, seriesName.localizedCaseInsensitiveContains(selectedSeries) else {
                return false
            }
        }
        return true
    }
}
