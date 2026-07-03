enum ProposalMeetupCandidateSelectionReducer {
    static func selectedIndexAfterRemoving(
        removedIndex: Int,
        selectedIndex: Int,
        remainingCount: Int
    ) -> Int? {
        guard remainingCount > 0 else {
            return nil
        }
        if removedIndex < selectedIndex {
            return max(0, selectedIndex - 1)
        }
        if removedIndex == selectedIndex {
            return min(removedIndex, remainingCount - 1)
        }
        return selectedIndex
    }
}
