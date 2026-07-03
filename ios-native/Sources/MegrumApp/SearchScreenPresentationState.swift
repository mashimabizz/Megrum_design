import Foundation

struct SearchScreenPresentationState: Equatable {
    var query = ""
    var queryDraft = ""
    var selectedSort: SearchResultSort = .newest
    var isApplyingSuggestion = false
    var appliedInitialCriteriaID: String?
    var isShowingFilters = false
    var lastWishSuggestionHorizontalScrollDate: Date?

    var hasSubmittedQuery: Bool {
        !query.isBlank
    }

    mutating func submitQuery() {
        query = queryDraft
    }

    mutating func setQuery(_ text: String) {
        query = text
        queryDraft = text
    }

    mutating func clearQuery() {
        setQuery("")
    }

    mutating func showFilters() {
        isShowingFilters = true
    }

    mutating func beginSuggestionApplication() {
        isApplyingSuggestion = true
    }

    mutating func finishSuggestionApplication() {
        isApplyingSuggestion = false
    }

    mutating func markWishSuggestionHorizontalScroll(now: Date = Date()) {
        lastWishSuggestionHorizontalScrollDate = now
    }

    func isBackSwipeSuppressed(now: Date = Date()) -> Bool {
        SearchBackSwipeResolver.isSuppressedByNestedHorizontalScroll(
            lastNestedHorizontalScrollDate: lastWishSuggestionHorizontalScrollDate,
            now: now
        )
    }

    mutating func applyInitialCriteriaIfNeeded(
        _ initialCriteria: SearchInitialCriteria?,
        filterDraft: inout SearchFilterDraft
    ) -> Bool {
        guard let initialCriteria,
              appliedInitialCriteriaID != initialCriteria.id
        else {
            return false
        }

        appliedInitialCriteriaID = initialCriteria.id
        setQuery(initialCriteria.query)
        filterDraft.selectedGroupID = initialCriteria.groupID
        filterDraft.selectedMemberID = initialCriteria.memberID
        filterDraft.selectedGoodsTypeID = initialCriteria.goodsTypeID
        filterDraft.selectedGoodsTagNames = Set(initialCriteria.tagNames)
        return true
    }
}
