import Foundation

extension SearchScreen {
    func applySuggestion(_ action: SearchSuggestionAction) {
        isApplyingSuggestion = true
        switch action {
        case .group(let groupID):
            selectedGroupID = groupID
            selectedMemberID = nil
        case .member(let groupID, let memberID):
            selectedGroupID = groupID
            selectedMemberID = memberID
        case .wish(let groupID, let memberID, let goodsTypeID, let tagNames):
            selectedGroupID = groupID
            selectedMemberID = memberID
            selectedGoodsTypeID = goodsTypeID
            if groupID == nil, memberID == nil, goodsTypeID == nil {
                selectedGoodsTagNames.formUnion(
                    SearchSuggestionTagPolicy.allowedRequestedTagNames(
                        tagNames,
                        candidateTagNames: availableGoodsTagNames
                    )
                )
            }
            conditionMatches.matchesWish = true
        case .goodsType(let goodsTypeID):
            selectedGoodsTypeID = goodsTypeID
        case .tag(let tagName):
            selectedGoodsTagNames.insert(tagName)
        case .payment(let method):
            selectedPaymentMethods.insert(method)
        case .meetupPrefecture(let prefecture):
            selectedMeetupPrefecture = prefecture
        case .query(let text):
            query = text
            queryDraft = text
        }
        scheduleSearch(delayNanoseconds: 0)
        finishSuggestionApplication()
    }

    func finishSuggestionApplication() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 30_000_000)
            isApplyingSuggestion = false
        }
    }
}
