import Foundation

struct HomeDiscoveryCandidateButtonPresentationState: Equatable {
    var selectedGoods: HomeMockGoods?

    mutating func hydrateIfNeeded(goods: [HomeMockGoods]) {
        selectedGoods = selectedGoods ?? goods.first
    }

    mutating func resetSelection(goods: [HomeMockGoods]) {
        selectedGoods = goods.first
    }

    mutating func select(_ goods: HomeMockGoods) {
        selectedGoods = goods
    }

    func resolvedSelectedGoods(in goods: [HomeMockGoods]) -> HomeMockGoods? {
        selectedGoods ?? goods.first
    }

    func cardTitle(
        candidateTitle: String,
        titleStyle: HomeDiscoveryCardTitleStyle,
        goods: [HomeMockGoods]
    ) -> String {
        if titleStyle == .memberTag {
            return candidateTitle
        }
        return HomeDiscoveryCardTitleFormatter.title(
            for: resolvedSelectedGoods(in: goods),
            fallback: candidateTitle,
            style: titleStyle
        )
    }
}
