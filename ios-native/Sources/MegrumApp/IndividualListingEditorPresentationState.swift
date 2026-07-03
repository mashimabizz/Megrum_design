import Foundation

struct IndividualListingEditorPresentationState: Equatable {
    var step: IndividualListingEditorStep
    var havesTab: IndividualListingHavesStep.Tab
    var haveSelectionFilter = IndividualListingSelectionFilter()
    var wishSelectionFilter = IndividualListingSelectionFilter()
    var stagedOptionSummaries: [IndividualListingOptionReviewItem] = []
    var showsOptionReview = false
    var optionToastMessage: String?
    var optionToastID = UUID()
    var saveErrorMessage: String?

    init(
        step: IndividualListingEditorStep,
        havesTab: IndividualListingHavesStep.Tab = .goods
    ) {
        self.step = step
        self.havesTab = havesTab
    }

    init(initialStep: IndividualListingEditorStep, draft: IndividualListingDraft) {
        self.init(
            step: initialStep,
            havesTab: draft.haveOfferKind == .cash ? .cash : .goods
        )
    }

    var nextOptionTitle: String {
        "選択肢\(stagedOptionSummaries.count + 1)"
    }

    mutating func selectStep(_ targetStep: IndividualListingEditorStep) {
        step = targetStep
    }

    mutating func showOptionReview() {
        showsOptionReview = true
    }

    mutating func appendStagedOption(_ item: IndividualListingOptionReviewItem) {
        stagedOptionSummaries.append(item)
    }

    mutating func deleteStagedOption(id itemID: UUID) {
        stagedOptionSummaries = IndividualListingOptionReviewReducer.deleting(
            itemID: itemID,
            from: stagedOptionSummaries
        )
    }

    mutating func clearSaveError() {
        saveErrorMessage = nil
    }

    mutating func setSaveError(_ message: String?) {
        saveErrorMessage = message
    }

    mutating func showOptionAddedToast(
        for item: IndividualListingOptionReviewItem,
        toastID: UUID = UUID()
    ) {
        optionToastID = toastID
        optionToastMessage = item.addedToastMessage
    }

    mutating func clearOptionToast(ifMatching toastID: UUID) {
        guard optionToastID == toastID else {
            return
        }
        optionToastMessage = nil
    }
}
