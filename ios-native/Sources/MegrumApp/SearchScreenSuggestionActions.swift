import Foundation

extension SearchScreen {
    func applySuggestion(_ action: SearchSuggestionAction) {
        presentationState.beginSuggestionApplication()
        switch action {
        case .group(let groupID):
            filterDraft.selectedGroupID = groupID
            filterDraft.selectedMemberID = nil
        case .member(let groupID, let memberID):
            filterDraft.selectedGroupID = groupID
            filterDraft.selectedMemberID = memberID
        case .wish(let groupID, let memberID, let goodsTypeID, let tagNames):
            filterDraft.selectedGroupID = groupID
            filterDraft.selectedMemberID = memberID
            filterDraft.selectedGoodsTypeID = goodsTypeID
            if groupID == nil, memberID == nil, goodsTypeID == nil {
                filterDraft.selectedGoodsTagNames.formUnion(
                    SearchSuggestionTagPolicy.allowedRequestedTagNames(
                        tagNames,
                        candidateTagNames: availableGoodsTagNames
                    )
                )
            }
            filterDraft.conditionMatches.matchesWish = true
        case .goodsType(let goodsTypeID):
            filterDraft.selectedGoodsTypeID = goodsTypeID
        case .tag(let tagName):
            filterDraft.selectedGoodsTagNames.insert(tagName)
        case .payment(let method):
            filterDraft.selectedPaymentMethods.insert(method)
        case .meetupPrefecture(let prefecture):
            filterDraft.selectedMeetupPrefecture = prefecture
        case .query(let text):
            presentationState.setQuery(text)
        }
        scheduleSearch(delayNanoseconds: 0)
        finishSuggestionApplication()
    }

    func finishSuggestionApplication() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 30_000_000)
            presentationState.finishSuggestionApplication()
        }
    }
}
