import Foundation

extension SearchScreen {
    func applySuggestion(_ action: SearchSuggestionAction) {
        MegrumHaptics.buttonTap()
        presentationState.beginSuggestionApplication()
        switch action {
        case .group(let groupID):
            filterDraft.selectedGroupIDs = [groupID]
            filterDraft.selectedMemberIDs = []
        case .member(let groupID, let memberID):
            filterDraft.selectedGroupIDs = [groupID]
            filterDraft.selectedMemberIDs = [memberID]
        case .wish(let groupID, let memberID, let goodsTypeID, let tagNames):
            filterDraft.selectedGroupIDs = groupID.map { [$0] } ?? []
            filterDraft.selectedMemberIDs = memberID.map { [$0] } ?? []
            filterDraft.selectedGoodsTypeIDs = goodsTypeID.map { [$0] } ?? []
            if groupID == nil, memberID == nil, goodsTypeID == nil {
                filterDraft.selectedGoodsTagNames.formUnion(
                    SearchSuggestionTagPolicy.allowedRequestedTagNames(
                        tagNames,
                        candidateTagNames: availableGoodsTagNames
                    )
                )
            }
        case .goodsType(let goodsTypeID):
            filterDraft.selectedGoodsTypeIDs = [goodsTypeID]
        case .tag(let tagName):
            filterDraft.selectedGoodsTagNames.insert(tagName)
        case .payment(let method):
            filterDraft.selectedPaymentMethods.insert(method)
        case .meetupPrefecture(let prefecture):
            filterDraft.selectedMeetupPrefecture = prefecture
        case .query(let text):
            presentationState.setQuery(text)
        case .listing(let listingID):
            // 自分の個別募集の「求めるもの」を検索条件へ変換して探す。
            if let listing = appState.listings.first(where: { $0.id == listingID }) {
                let criteria = ListingSearchCriteriaBuilder.criteria(for: listing, wishes: appState.wishes)
                filterDraft.selectedGroupIDs = criteria.groupIDs
                filterDraft.selectedMemberIDs = criteria.memberIDs
                filterDraft.selectedGoodsTypeIDs = criteria.goodsTypeIDs
                filterDraft.selectedGoodsTagNames = criteria.tagNames
                filterDraft.wantsCashOK = criteria.wantsCashOK
            }
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
