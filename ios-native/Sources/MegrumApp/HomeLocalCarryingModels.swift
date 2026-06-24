import Foundation
import MegrumCore

struct HomeLocalCarryingCandidate: Identifiable, Equatable, Hashable {
    var id: UUID
    var title: String
    var subtitle: String
    var quantity: Int
    var imageURL: URL?

    static func candidates(from items: [GoodsItem], viewerID: UUID?) -> [HomeLocalCarryingCandidate] {
        var seen = Set<UUID>()
        return items.compactMap { item in
            if let viewerID, item.ownerID != viewerID {
                return nil
            }
            guard seen.insert(item.id).inserted else {
                return nil
            }
            return HomeLocalCarryingCandidate(item: item)
        }
    }

    static func sourceItems(
        inventory: [GoodsItem],
        matchedItems: [GoodsItem],
        possibleItems: [GoodsItem]
    ) -> [GoodsItem] {
        guard !inventory.isEmpty else {
            return matchedItems + possibleItems
        }
        return inventory
    }

    init(item: GoodsItem) {
        self.id = item.id
        self.title = item.title
        self.subtitle = Self.subtitle(for: item)
        self.quantity = item.quantity
        self.imageURL = item.imageURL
    }

    private static func subtitle(for item: GoodsItem) -> String {
        let tagLine = item.tags.prefix(2).map(\.name).joined(separator: " / ")
        if !tagLine.isEmpty {
            return tagLine
        }
        if item.quantity > 1 {
            return "\(item.quantity)点"
        }
        return "譲る候補"
    }
}

struct HomeLocalCarryingSummary: Equatable {
    var selectedCount: Int
    var availableCount: Int
    var selectedTitles: [String]

    init(candidates: [HomeLocalCarryingCandidate], selectedIDs: Set<UUID>) {
        let selected = candidates.filter { selectedIDs.contains($0.id) }
        self.selectedCount = selected.count
        self.availableCount = candidates.count
        self.selectedTitles = selected.prefix(2).map(\.title)
    }

    var countText: String {
        if availableCount == 0 {
            return "持参 0件"
        }
        return "持参 \(selectedCount)/\(availableCount)件"
    }

    var titleText: String {
        if selectedTitles.isEmpty {
            return availableCount == 0 ? "譲る候補なし" : "持参グッズ未選択"
        }
        return selectedTitles.joined(separator: "、")
    }
}

enum HomeLocalCarryingSelectionCodec {
    static func decode(_ value: String) -> Set<UUID> {
        Set(
            value
                .split(separator: ",")
                .compactMap { UUID(uuidString: String($0)) }
        )
    }

    static func encode(_ ids: Set<UUID>) -> String {
        ids
            .map { $0.uuidString.lowercased() }
            .sorted()
            .joined(separator: ",")
    }
}
