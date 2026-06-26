import Foundation

extension HomeDiscoveryExperience {
    func openInitialSheetIfNeeded() {
        guard opensInitialHavesLookup, !didOpenInitialSheet else {
            return
        }
        didOpenInitialSheet = true
        selectedSheet = havesCandidates.first?.sheet
    }

    func openIndividualListingCreation() {
        guard let appState else {
            onOpenIndividualListings()
            return
        }

        showsIndividualListingCreation = true
        Task {
            if appState.oshiGroups.isEmpty || appState.oshiGenres.isEmpty {
                await appState.loadOshiGroups()
            }
            if appState.goodsTypes.isEmpty {
                await appState.loadGoodsTypes()
            }
        }
    }

    func openSearch(
        for candidate: HomeDiscoveryCandidate,
        selectedGoods: HomeMockGoods?,
        source: HomeDiscoveryCandidateSource
    ) {
        onOpenSearchWithCriteria(
            HomeDiscoverySearchRoutePolicy.criteria(
                for: candidate,
                selectedGoods: selectedGoods,
                source: source
            )
        )
    }

    func requestProposalPresentation(_ selection: HomeDiscoveryProposalSelection) {
        pendingProposalSelection = nil
        selectedSheet = nil
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: HomeDiscoveryDeferredPresentationPolicy.sheetDismissalDelayNanoseconds)
            onStartProposal(selection.applyingDefaultMailConditions(defaultExchangeSettings))
        }
    }

    func requestProfilePresentation(_ userID: UUID) {
        pendingProfileUserID = userID
        selectedSheet = nil
    }

    func requestProposalPresentationFromMutualMatch(_ selection: HomeDiscoveryProposalSelection) {
        selectedMutualMatchCandidate = nil
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: HomeDiscoveryDeferredPresentationPolicy.sheetDismissalDelayNanoseconds)
            onStartProposal(selection.applyingDefaultMailConditions(defaultExchangeSettings))
        }
    }

    func requestProfilePresentationFromMutualMatch(_ userID: UUID) {
        selectedMutualMatchCandidate = nil
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: HomeDiscoveryDeferredPresentationPolicy.sheetDismissalDelayNanoseconds)
            onOpenOwnerProfile(userID)
        }
    }

    func presentPendingProposalIfNeeded() {
        if let pendingProfileUserID {
            self.pendingProfileUserID = nil
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: HomeDiscoveryDeferredPresentationPolicy.sheetDismissalDelayNanoseconds)
                onOpenOwnerProfile(pendingProfileUserID)
            }
            return
        }

        guard let selection = pendingProposalSelection else {
            return
        }
        pendingProposalSelection = nil
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: HomeDiscoveryDeferredPresentationPolicy.sheetDismissalDelayNanoseconds)
            onStartProposal(selection.applyingDefaultMailConditions(defaultExchangeSettings))
        }
    }
}
