import Foundation

enum ProposalCreateGoodsSelectionReducer {
    static func toggled(_ selectedIDs: Set<UUID>, id: UUID) -> Set<UUID> {
        if selectedIDs.contains(id) {
            return selectedIDs.subtracting([id])
        }
        return selectedIDs.union([id])
    }

    static func reconciled(
        selectedIDs: Set<UUID>,
        availableIDs: [UUID],
        fallbackIDs: [UUID]
    ) -> Set<UUID> {
        let availableIDSet = Set(availableIDs)
        let retainedIDs = selectedIDs.intersection(availableIDSet)
        guard retainedIDs.isEmpty else {
            return retainedIDs
        }
        return seeded(availableIDs: availableIDs, fallbackIDs: fallbackIDs)
    }

    static func seeded(
        selectedIDs: Set<UUID>,
        availableIDs: [UUID],
        fallbackIDs: [UUID]
    ) -> Set<UUID> {
        guard selectedIDs.isEmpty else {
            return selectedIDs
        }
        return seeded(availableIDs: availableIDs, fallbackIDs: fallbackIDs)
    }

    private static func seeded(availableIDs: [UUID], fallbackIDs: [UUID]) -> Set<UUID> {
        let availableIDSet = Set(availableIDs)
        let seededIDs = fallbackIDs.filter { availableIDSet.contains($0) }
        return Set(seededIDs)
    }
}
