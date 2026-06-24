import Foundation
import MegrumCore
import SwiftUI

enum SearchLayoutMetrics {
    static let footerGlassGroupSpacing: CGFloat = 12
}

enum SearchCriteriaResolver {
    static func hasCriteria(query: String, activeFilterCount: Int) -> Bool {
        !query.isBlank || activeFilterCount > 0
    }
}

enum SearchBackSwipeResolver {
    static let minimumTranslation: CGFloat = 72
    static let minimumPredictedTranslation: CGFloat = 112
    static let horizontalDominance: CGFloat = 1.25
    static let nestedHorizontalScrollSuppressionInterval: TimeInterval = 0.75

    static func shouldDismiss(
        translation: CGSize,
        predictedEndTranslationWidth: CGFloat,
        isSuppressedByNestedHorizontalScroll: Bool = false
    ) -> Bool {
        guard !isSuppressedByNestedHorizontalScroll else {
            return false
        }
        let isRightSwipe = translation.width > 0
        let isHorizontal = abs(translation.width) > abs(translation.height) * horizontalDominance
        let isLongEnough = translation.width >= minimumTranslation
            || predictedEndTranslationWidth >= minimumPredictedTranslation
        return isRightSwipe && isHorizontal && isLongEnough
    }

    static func isNestedHorizontalScroll(translation: CGSize) -> Bool {
        abs(translation.width) > abs(translation.height) * horizontalDominance
    }

    static func isSuppressedByNestedHorizontalScroll(
        lastNestedHorizontalScrollDate: Date?,
        now: Date = Date()
    ) -> Bool {
        guard let lastNestedHorizontalScrollDate else {
            return false
        }
        return now.timeIntervalSince(lastNestedHorizontalScrollDate) <= nestedHorizontalScrollSuppressionInterval
    }
}

enum SearchQueryResolver {
    static func matchingGoodsTypeID(query: String, goodsTypes: [GoodsType]) -> UUID? {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else {
            return nil
        }
        return goodsTypes.first { goodsType in
            goodsType.name.localizedCaseInsensitiveCompare(normalizedQuery) == .orderedSame
        }?.id
    }

    static func matchingTagName(query: String, tagNames: [String]) -> String? {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else {
            return nil
        }
        return tagNames.first { tagName in
            tagName.localizedCaseInsensitiveCompare(normalizedQuery) == .orderedSame
        }
    }

    static func backendQuery(query: String, matchedGoodsTypeID: UUID?, matchedTagName: String?) -> String {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard matchedGoodsTypeID == nil, matchedTagName == nil else {
            return ""
        }
        return normalizedQuery
    }
}

enum SearchSuggestionTagPolicy {
    static func allowedRequestedTagNames(
        _ requestedTagNames: [String],
        candidateTagNames: [String],
        limit: Int = 2
    ) -> [String] {
        let candidatesByKey = Dictionary(
            candidateTagNames.map { ($0.lowercased(), $0) },
            uniquingKeysWith: { first, _ in first }
        )
        return requestedTagNames
            .prefix(limit)
            .compactMap { candidatesByKey[$0.lowercased()] }
    }
}

extension View {
    @ViewBuilder
    func searchScreenTabBarVisibility() -> some View {
        #if os(iOS)
        self.toolbar(.hidden, for: .tabBar)
        #else
        self
        #endif
    }
}
