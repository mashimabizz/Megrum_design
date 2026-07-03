import Foundation

struct HomeMutualMatchDetailPresentationState {
    var selectedPairID: String?
    var nestedPresentation: HomeDiscoveryNestedPresentation?
    var addedExtraSelections: [HomeDiscoveryProposalSelection] = []

    var addedExtraCandidateIDs: Set<UUID> {
        Set(addedExtraSelections.flatMap(\.receiverGoodsIDs))
    }

    mutating func selectPair(id: String) {
        selectedPairID = id
    }

    mutating func showNestedSheet(_ sheet: HomeDiscoverySheet) {
        nestedPresentation = .discoverySheet(sheet)
    }

    mutating func showNestedProfile(_ route: PublicProfileRoute) {
        nestedPresentation = .publicProfile(route)
    }

    mutating func addExtraProposalSelectionAndDismiss(_ selection: HomeDiscoveryProposalSelection) {
        addedExtraSelections.append(selection)
        nestedPresentation = nil
    }

    mutating func closeNestedPresentation() {
        nestedPresentation = nil
    }

    mutating func seedInitialSelectionIfNeeded(
        hasSelectedPair: Bool,
        preferredPairID: String?
    ) {
        guard !hasSelectedPair else {
            return
        }
        selectedPairID = preferredPairID
    }

    func proposalSelection(_ selection: HomeDiscoveryProposalSelection) -> HomeDiscoveryProposalSelection {
        selection.includingExtraSelections(addedExtraSelections)
    }
}
