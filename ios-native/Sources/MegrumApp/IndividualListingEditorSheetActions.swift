import MegrumCore
import SwiftUI

extension IndividualListingEditorSheet {
    func loadConditionCharacters(_ group: OshiGroup) {
        Task {
            await appState.loadOshiCharacters(group: group)
        }
    }

    func loadSelectedConditionCharacters() {
        guard let group = appState.oshiGroups.first(where: { $0.id == draft.conditionGroupID }) else {
            return
        }
        loadConditionCharacters(group)
    }

    func createOshiRequest(_ payload: OshiRequestSheetPayload) {
        Task {
            _ = await appState.createOshiRequest(
                OshiRequestCreateInput(
                    requestedName: payload.name,
                    requestedKind: payload.kind,
                    requestedGenreID: payload.genreID,
                    note: payload.note
                )
            )
            await appState.loadOshiGroups()
        }
    }

    func save() async {
        saveErrorMessage = nil
        guard let input = draft.createInput(inventory: appState.inventory, wishes: appState.wishes) else {
            saveErrorMessage = stepValidationMessage
                ?? IndividualListingEditorSaveFailurePresentation.fallbackMessage
            return
        }
        if case .edit(let listing) = draft.mode {
            let primaryOptionID = listing.options.sorted { $0.position < $1.position }.first?.id
            if let updated = await appState.updateIndividualListing(
                listingID: listing.id,
                primaryOptionID: primaryOptionID,
                input: input,
                status: draft.status
            ) {
                onLocalEditSaved?(updated)
                finishSuccessfulSave()
            } else {
                saveErrorMessage = appState.errorMessage
                    ?? IndividualListingEditorSaveFailurePresentation.fallbackMessage
            }
            return
        }
        let saved = await appState.createIndividualListing(input)
        if saved {
            finishSuccessfulSave()
        } else {
            saveErrorMessage = appState.errorMessage
                ?? IndividualListingEditorSaveFailurePresentation.fallbackMessage
        }
    }

    func finishSuccessfulSave() {
        dismiss()
        onSaved?()
    }

    func goBack() {
        dismiss()
    }

    func selectStep(_ targetStep: IndividualListingEditorStep) {
        withAnimation(.smooth(duration: 0.2)) {
            step = targetStep
        }
    }

    func primaryAction() {
        guard stepValidationMessage == nil else {
            return
        }
        switch step {
        case .haves:
            withAnimation(.smooth(duration: 0.2)) {
                step = .options
            }
        case .options:
            withAnimation(.smooth(duration: 0.2)) {
                step = .exchange
            }
        case .exchange:
            draft.includesExchangeConditionSummary = true
            Task {
                await save()
            }
        }
    }

    func addCurrentOption() {
        guard step == .options, stepValidationMessage == nil else {
            return
        }
        guard let item = makeCurrentOptionReviewItem(title: "選択肢\(stagedOptionSummaries.count + 1)") else {
            return
        }
        stagedOptionSummaries.append(item)
        draft.resetCurrentOptionSelection()
        showOptionAddedToast(for: item)
    }

    func deleteOptionReviewItem(_ item: IndividualListingOptionReviewItem) {
        switch item.source {
        case .staged:
            stagedOptionSummaries = IndividualListingOptionReviewReducer.deleting(
                itemID: item.id,
                from: stagedOptionSummaries
            )
        case .current:
            clearCurrentOption()
        }
    }

    func clearCurrentOption() {
        draft.resetCurrentOptionSelection()
    }

    func showOptionAddedToast(for item: IndividualListingOptionReviewItem) {
        let toastID = UUID()
        optionToastID = toastID
        withAnimation(.snappy(duration: 0.18)) {
            optionToastMessage = item.addedToastMessage
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            guard optionToastID == toastID else {
                return
            }
            withAnimation(.snappy(duration: 0.18)) {
                optionToastMessage = nil
            }
        }
    }

    func seedDraftDefaultsIfNeeded() {
        if step != .haves,
           draft.selectedHaveIDs.isEmpty,
           let firstHave = appState.inventory.first(where: { draft.maxHaveQuantity(for: $0) > 0 }) {
            draft.toggleHave(firstHave.id, maxQuantity: draft.maxHaveQuantity(for: firstHave))
        }
        if step == .exchange, draft.optionKind == .wish, draft.selectedWishIDs.isEmpty, let firstWish = appState.wishes.first {
            draft.toggleWish(firstWish.id)
        }
    }
}
