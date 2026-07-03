struct WishCollectionPresentationState: Equatable {
    var selectedSection: WishCollectionSection = .wishes

    mutating func applyRequestedSection(_ section: WishCollectionSection?) -> Bool {
        guard let section else {
            return false
        }

        selectedSection = section
        return true
    }
}
