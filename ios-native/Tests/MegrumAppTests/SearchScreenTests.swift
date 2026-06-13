@testable import MegrumApp
import XCTest

final class SearchScreenTests: XCTestCase {
    func testSearchTitleUsesCompactPageHeadingSize() {
        XCTAssertEqual(SearchLayoutMetrics.titleFontSize, 42)
    }

    func testSearchFooterUsesGroupedGlassSpacing() {
        XCTAssertEqual(SearchLayoutMetrics.footerGlassGroupSpacing, 12)
    }

    func testSearchCriteriaRequiresQueryOrFilter() {
        XCTAssertFalse(SearchCriteriaResolver.hasCriteria(query: "", activeFilterCount: 0))
        XCTAssertFalse(SearchCriteriaResolver.hasCriteria(query: " \n ", activeFilterCount: 0))
        XCTAssertTrue(SearchCriteriaResolver.hasCriteria(query: "トレカ", activeFilterCount: 0))
        XCTAssertTrue(SearchCriteriaResolver.hasCriteria(query: "", activeFilterCount: 1))
    }
}
