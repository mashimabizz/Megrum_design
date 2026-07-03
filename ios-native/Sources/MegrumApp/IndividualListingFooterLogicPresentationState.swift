import MegrumCore

struct IndividualListingFooterLogicPresentationState: Equatable {
    var isShowingMinimumPicker = false

    func minimumChoices(selectedCount: Int) -> [Int] {
        guard selectedCount >= 2 else {
            return []
        }
        return Array(1...selectedCount)
    }

    mutating func selectLogic(_ logic: ListingLogic) -> ListingLogic {
        if logic == .atLeast {
            isShowingMinimumPicker = true
        }
        return logic
    }

    mutating func dismissMinimumPicker() {
        isShowingMinimumPicker = false
    }
}
