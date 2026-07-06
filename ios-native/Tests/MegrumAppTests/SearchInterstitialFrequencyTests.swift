import Foundation
import XCTest
@testable import MegrumApp

final class SearchInterstitialFrequencyTests: XCTestCase {
    func testInterstitialShowsOnSecondSearchAndEveryTwoAfter() {
        XCTAssertFalse(SearchInterstitialFrequencyPolicy.shouldShowInterstitial(searchCountToday: 0))
        XCTAssertFalse(SearchInterstitialFrequencyPolicy.shouldShowInterstitial(searchCountToday: 1))
        XCTAssertTrue(SearchInterstitialFrequencyPolicy.shouldShowInterstitial(searchCountToday: 2))
        XCTAssertFalse(SearchInterstitialFrequencyPolicy.shouldShowInterstitial(searchCountToday: 3))
        XCTAssertTrue(SearchInterstitialFrequencyPolicy.shouldShowInterstitial(searchCountToday: 4))
        XCTAssertFalse(SearchInterstitialFrequencyPolicy.shouldShowInterstitial(searchCountToday: 5))
        XCTAssertTrue(SearchInterstitialFrequencyPolicy.shouldShowInterstitial(searchCountToday: 6))
    }

    func testDailyCountResetsWhenDayChanges() {
        let defaults = UserDefaults(suiteName: "search-interstitial-tests")!
        defaults.removePersistentDomain(forName: "search-interstitial-tests")

        let calendar = Calendar(identifier: .gregorian)
        let day1 = DateComponents(calendar: calendar, year: 2026, month: 7, day: 6, hour: 10).date!
        let day1Later = DateComponents(calendar: calendar, year: 2026, month: 7, day: 6, hour: 23).date!
        let day2 = DateComponents(calendar: calendar, year: 2026, month: 7, day: 7, hour: 0, minute: 5).date!

        XCTAssertEqual(SearchDailyCountStore.incrementedCount(now: day1, calendar: calendar, defaults: defaults), 1)
        XCTAssertEqual(SearchDailyCountStore.incrementedCount(now: day1Later, calendar: calendar, defaults: defaults), 2)
        XCTAssertEqual(SearchDailyCountStore.incrementedCount(now: day2, calendar: calendar, defaults: defaults), 1)
    }
}
