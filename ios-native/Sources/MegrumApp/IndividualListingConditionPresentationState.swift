struct IndividualListingConditionPresentationState: Equatable {
    var isShowingMemberPicker = false
    var isShowingTagSheet = false

    mutating func showMemberPicker() {
        isShowingMemberPicker = true
    }

    mutating func dismissMemberPicker() {
        isShowingMemberPicker = false
    }

    mutating func showTagSheet() {
        isShowingTagSheet = true
    }
}
