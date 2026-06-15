import Foundation

struct MatchRelationSelectionState: Equatable, Sendable {
    var selectedCandidateIDsByListingID: [UUID: Set<UUID>] = [:]
    var selectedHaveIDsByListingID: [UUID: Set<UUID>] = [:]
}

enum MatchRelationSelectionStateReducer {
    static func seedingInitialSelection(
        in state: MatchRelationSelectionState,
        details: [MatchRelationListingDetail],
        highlightedItemID: UUID,
        force: Bool
    ) -> MatchRelationSelectionState {
        guard force || state.selectedCandidateIDsByListingID.isEmpty else {
            return state
        }

        return MatchRelationSelectionState(
            selectedCandidateIDsByListingID: MatchRelationComposer.initialCandidateSelection(
                for: details,
                highlightedItemID: highlightedItemID
            ),
            selectedHaveIDsByListingID: MatchRelationComposer.initialHaveSelection(
                for: details,
                highlightedItemID: highlightedItemID
            )
        )
    }

    static func resettingCandidates(
        in state: MatchRelationSelectionState
    ) -> MatchRelationSelectionState {
        var next = state
        next.selectedCandidateIDsByListingID = [:]
        return next
    }

    static func togglingCandidate(
        listingID: UUID,
        candidateID: UUID,
        in state: MatchRelationSelectionState
    ) -> MatchRelationSelectionState {
        var next = state
        var ids = next.selectedCandidateIDsByListingID[listingID] ?? []
        if ids.contains(candidateID) {
            ids.remove(candidateID)
        } else {
            ids.insert(candidateID)
        }

        if ids.isEmpty {
            next.selectedCandidateIDsByListingID.removeValue(forKey: listingID)
        } else {
            next.selectedCandidateIDsByListingID[listingID] = ids
        }
        return next
    }

    static func togglingHave(
        listingID: UUID,
        haveID: UUID,
        in state: MatchRelationSelectionState
    ) -> MatchRelationSelectionState {
        var next = state
        var ids = next.selectedHaveIDsByListingID[listingID] ?? []
        if ids.contains(haveID) {
            ids.remove(haveID)
        } else {
            ids.insert(haveID)
        }
        next.selectedHaveIDsByListingID[listingID] = ids
        return next
    }
}
