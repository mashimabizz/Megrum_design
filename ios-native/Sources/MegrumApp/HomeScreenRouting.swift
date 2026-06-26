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
        presentProposalRoute(route)
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
        presentRelationRoute(HomeRelationRoute(item: item, matchType: .perfect))
    }

    private func presentRelationRoute(_ route: HomeRelationRoute) {
        if let onOpenRelationRoute {
            onOpenRelationRoute(route)
        } else {
            relationRoute = route
        }
    }

    private func presentProposalRoute(_ route: HomeProposalRoute) {
        if let onOpenProposalRoute {
            onOpenProposalRoute(route)
        } else {
            proposalRoute = route
        }
    }
}
