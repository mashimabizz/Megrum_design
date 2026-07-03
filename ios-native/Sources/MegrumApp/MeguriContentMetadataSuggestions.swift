import Foundation
import MegrumCore

enum MeguriContentMetadataSuggestions {
    static func preferredGroups(
        groups: [OshiGroup],
        selections: [UserOshiSelection]
    ) -> [OshiGroup] {
        let preferredIDs = orderedUnique(selections.compactMap(\.groupID))
        return preferredIDs.compactMap { id in
            groups.first { $0.id == id }
        }
    }

    static func preferredCharacters(
        characters: [OshiCharacter],
        selections: [UserOshiSelection],
        groupID: UUID?
    ) -> [OshiCharacter] {
        guard let groupID else {
            return []
        }
        let preferredIDs = orderedUnique(
            selections
                .filter { $0.groupID == groupID }
                .compactMap(\.characterID)
        )
        return preferredIDs.compactMap { id in
            characters.first { $0.id == id }
        }
    }

    static func seriesCandidates(
        inventory: [GoodsItem],
        wishes: [WishItem],
        groupID: UUID?,
        characterID: UUID?
    ) -> [String] {
        let inventoryMatches = inventory.filter {
            matches(itemGroupID: $0.groupID, itemCharacterID: $0.memberID, groupID: groupID, characterID: characterID)
        }
        let wishMatches = wishes.filter {
            matches(itemGroupID: $0.groupID, itemCharacterID: $0.memberID, groupID: groupID, characterID: characterID)
        }
        return orderedUnique(
            inventoryMatches.flatMap { $0.tags.map(\.name) }
                + wishMatches.flatMap { $0.tags.map(\.name) }
        )
    }

    static func filteredSeriesCandidates(_ candidates: [String], query: String) -> [String] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else {
            return candidates
        }
        return candidates.filter { $0.localizedCaseInsensitiveContains(normalizedQuery) }
    }

    static func filteredGroups(_ groups: [OshiGroup], query: String) -> [OshiGroup] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else {
            return groups
        }
        return groups.filter { $0.name.localizedCaseInsensitiveContains(normalizedQuery) }
    }

    private static func matches(
        itemGroupID: UUID?,
        itemCharacterID: UUID?,
        groupID: UUID?,
        characterID: UUID?
    ) -> Bool {
        if let groupID, itemGroupID != groupID {
            return false
        }
        if let characterID, itemCharacterID != characterID {
            return false
        }
        return true
    }

    private static func orderedUnique<T: Hashable>(_ values: [T]) -> [T] {
        var seen = Set<T>()
        var result: [T] = []
        for value in values where seen.insert(value).inserted {
            result.append(value)
        }
        return result
    }
}
