import SwiftUI

extension IndividualListingEditorSheet {
    var stepValidationMessage: String? {
        IndividualListingEditorStepValidationPolicy.message(
            for: step,
            draft: draft,
            inventory: appState.inventory,
            wishes: appState.wishes
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
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )
    }

    var optionReviewItems: [IndividualListingOptionReviewItem] {
        var items = stagedOptionSummaries
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
