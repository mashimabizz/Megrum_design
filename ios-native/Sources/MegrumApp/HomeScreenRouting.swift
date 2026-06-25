import Foundation

@MainActor
extension HomeScreen {
    func startProposalFromDiscovery(_ selection: HomeDiscoveryProposalSelection) {
        guard let route = HomeDiscoveryProposalRouteResolver.route(
            selection: selection,
            viewerID: viewer?.id,
            matchedItems: matchedItems,
            possibleItems: possibleItems,
            inventoryItems: localModeState?.inventory ?? []
        ) else {
            return
        }
        proposalRoute = route
    }

    func openVisualQAInitialRouteIfNeeded() {
        guard !didOpenVisualQAInitialRoute,
              visualQAInitialScreen == .matchRelation || visualQAInitialScreen == .matchRelationCandidates
        else {
            return
        }
        guard let item = HomeRelationVisualQARouteResolver.targetItem(
            candidates: matchedItems,
            viewerID: viewer?.id
        ) else {
            return
        }
        didOpenVisualQAInitialRoute = true
        relationRoute = HomeRelationRoute(item: item, matchType: .perfect)
    }
}
