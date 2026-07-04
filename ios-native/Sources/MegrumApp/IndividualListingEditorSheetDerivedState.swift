import MegrumCore
import SwiftUI

extension IndividualListingEditorSheet {
    var stagedOptionInputs: [IndividualListingOptionInput] {
        presentationState.stagedOptionSummaries.compactMap(\.payload)
    }

    var stepValidationMessage: String? {
        IndividualListingEditorStepValidationPolicy.message(
            for: presentationState.step,
            draft: draft,
            inventory: appState.inventory,
            wishes: appState.wishes,
            stagedOptions: stagedOptionInputs
        )
    }

    var isSaving: Bool {
        switch draft.mode {
        case .create:
            return appState.isCreatingIndividualListing
        case .edit(let listing):
            return appState.updatingIndividualListingID == listing.id
        }
    }

    var saveErrorBinding: Binding<Bool> {
        Binding(
            get: { presentationState.saveErrorMessage != nil },
            set: { if !$0 { presentationState.clearSaveError() } }
        )
    }

    var optionReviewItems: [IndividualListingOptionReviewItem] {
        var items = presentationState.stagedOptionSummaries
        if let current = makeCurrentOptionReviewItem(
            title: items.isEmpty ? "編集中の選択肢" : "編集中",
            source: .current
        ) {
            items.append(current)
        }
        return items
    }

    func makeCurrentOptionReviewItem(
        title: String,
        source: IndividualListingOptionReviewSource = .staged
    ) -> IndividualListingOptionReviewItem? {
        IndividualListingOptionReviewItemFactory.make(
            title: title,
            source: source,
            draft: draft,
            wishes: appState.wishes,
            groups: appState.oshiGroups,
            goodsTypes: appState.goodsTypes,
            characters: appState.oshiCharacters
        )
    }
}
