import Foundation
import MegrumCore

extension HomeDiscoveryExperience {
    func openInitialSheetIfNeeded() {
        guard opensInitialHavesLookup,
              !didOpenInitialSheet,
              let sheet = havesCandidates.first?.sheet
        else {
            return
        }
        didOpenInitialSheet = true
        selectedSheet = sheet
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

    func handleCreatedListingShare(_ listing: IndividualListing) {
        guard let appState else {
            return
        }
        // ガイドツアー中は共有プロンプトを出さない。
        guard !appState.isTutorialActive else {
            return
        }
        Task { @MainActor in
            if !appState.hasLoadedPaymentSettings {
                await appState.loadPaymentSettings(reportsFailure: false)
            }
            let displayName = viewerDisplayNameForSharePost()
            let snapshot = IndividualListingShareSnapshotFactory.make(
                listing: listing,
                displayName: displayName,
                inventory: appState.inventory,
                wishes: appState.wishes,
                groups: appState.oshiGroups,
                goodsTypes: appState.goodsTypes,
                paymentMethodsText: paymentMethodsTextForSharePost()
            )
            sharePostErrorMessage = nil
            isPreparingSharePost = false
            sharePromptContext = GoodsSharePostContext(
                kind: .individualListing,
                items: [],
                displayName: displayName,
                listingSnapshot: snapshot
            )
        }
    }

    func dismissSharePrompt() {
        guard !isPreparingSharePost else {
            return
        }
        sharePromptContext = nil
        sharePostErrorMessage = nil
    }

    #if os(iOS)
    func startGoodsSharePost() {
        guard let sharePromptContext, !isPreparingSharePost else {
            return
        }
        isPreparingSharePost = true
        sharePostErrorMessage = nil

        Task { @MainActor in
            do {
                shareActivityPayload = try await GoodsSharePostRenderer.payload(for: sharePromptContext)
                isPreparingSharePost = false
            } catch {
                isPreparingSharePost = false
                sharePostErrorMessage = "ポスト画像を作成できませんでした。時間をおいてもう一度お試しください。"
            }
        }
    }
    #else
    func startGoodsSharePost() {
        sharePostErrorMessage = "この端末ではXへの共有を利用できません。"
    }
    #endif

    private func viewerDisplayNameForSharePost() -> String {
        [
            viewer?.displayName,
            viewer?.handle,
            appState?.viewer?.displayName,
            appState?.viewer?.handle
        ]
        .compactMap(normalizedShareDisplayName)
        .first ?? "Megrumユーザー"
    }

    private func normalizedShareDisplayName(_ value: String?) -> String? {
        value?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfBlank
    }

    private func paymentMethodsTextForSharePost() -> String {
        GoodsSharePostTextBuilder.paymentMethodsText(
            methods: PaymentSettingsResolver.methods(
                settings: appState?.paymentSettings,
                viewer: appState?.viewer ?? viewer
            ),
            otherNote: PaymentSettingsResolver.otherNote(
                settings: appState?.paymentSettings,
                viewer: appState?.viewer ?? viewer
            )
        )
    }
}
