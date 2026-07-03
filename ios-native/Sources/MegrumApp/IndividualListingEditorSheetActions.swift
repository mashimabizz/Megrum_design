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
        presentationState.clearSaveError()
        guard let input = draft.createInput(inventory: appState.inventory, wishes: appState.wishes) else {
            presentationState.setSaveError(
                stepValidationMessage
                ?? IndividualListingEditorSaveFailurePresentation.fallbackMessage
            )
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
                presentationState.setSaveError(
                    appState.errorMessage
                    ?? IndividualListingEditorSaveFailurePresentation.fallbackMessage
                )
            }
            return
        }
        if let created = await appState.createIndividualListingRecord(input) {
            onCreatedListing?(created)
            finishSuccessfulSave()
        } else {
            presentationState.setSaveError(
                appState.errorMessage
                ?? IndividualListingEditorSaveFailurePresentation.fallbackMessage
            )
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
            presentationState.selectStep(targetStep)
        }
    }

    func primaryAction() {
        guard stepValidationMessage == nil else {
            return
        }
        switch presentationState.step {
        case .haves:
            withAnimation(.smooth(duration: 0.2)) {
                presentationState.selectStep(.options)
            }
        case .options:
            withAnimation(.smooth(duration: 0.2)) {
                presentationState.selectStep(.exchange)
            }
        case .exchange:
            draft.includesExchangeConditionSummary = true
            Task {
                await save()
            }
        }
    }

    func addCurrentOption() {
        guard presentationState.step == .options, stepValidationMessage == nil else {
            return
        }
        guard let item = makeCurrentOptionReviewItem(title: presentationState.nextOptionTitle) else {
            return
        }
        presentationState.appendStagedOption(item)
        draft.resetCurrentOptionSelection()
        showOptionAddedToast(for: item)
    }

    func deleteOptionReviewItem(_ item: IndividualListingOptionReviewItem) {
        switch item.source {
        case .staged:
            presentationState.deleteStagedOption(id: item.id)
        case .current:
            clearCurrentOption()
        }
    }

    func clearCurrentOption() {
        draft.resetCurrentOptionSelection()
    }

    func showOptionAddedToast(for item: IndividualListingOptionReviewItem) {
        let toastID = UUID()
        withAnimation(.snappy(duration: 0.18)) {
            presentationState.showOptionAddedToast(for: item, toastID: toastID)
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            guard presentationState.optionToastID == toastID else {
                return
            }
            withAnimation(.snappy(duration: 0.18)) {
                presentationState.clearOptionToast(ifMatching: toastID)
            }
        }
    }

    func seedDraftDefaultsIfNeeded() {
        if presentationState.step != .haves,
           draft.selectedHaveIDs.isEmpty,
           let firstHave = appState.inventory.first(where: { draft.maxHaveQuantity(for: $0) > 0 }) {
            draft.toggleHave(firstHave.id, maxQuantity: draft.maxHaveQuantity(for: firstHave))
        }
        if presentationState.step == .exchange, draft.optionKind == .wish, draft.selectedWishIDs.isEmpty, let firstWish = appState.wishes.first {
            draft.toggleWish(firstWish.id)
        }
    }
}
