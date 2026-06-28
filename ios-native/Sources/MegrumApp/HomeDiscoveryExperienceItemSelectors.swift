import Foundation
import MegrumCore

extension HomeDiscoveryExperience {
    var candidateSorter: HomeDiscoveryCandidateSorter {
        HomeDiscoveryCandidateSorter(conditionSignalsByItemID: displayConditionSignalsByItemID)
    }

    func partnerItems(from items: [GoodsItem]) -> [GoodsItem] {
        guard let viewerID = viewer?.id else {
            return deduplicated(items)
        }
        return deduplicated(items.filter { $0.ownerID != viewerID })
    }

    func ownItems(from items: [GoodsItem]) -> [GoodsItem] {
        guard let viewerID = viewer?.id else {
            return []
        }
        return deduplicated(items.filter { $0.ownerID == viewerID })
    }

    private func deduplicated(_ items: [GoodsItem]) -> [GoodsItem] {
        var seen: Set<UUID> = []
        var result: [GoodsItem] = []
        for item in items where seen.insert(item.id).inserted {
            result.append(item)
        }
        return result
    }
}
