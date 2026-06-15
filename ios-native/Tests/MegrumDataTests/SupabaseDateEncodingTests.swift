@testable import MegrumData
import Foundation
import XCTest

final class SupabaseDateEncodingTests: XCTestCase {
    func testIsoTimestampUsesFractionalSeconds() {
        let date = Date(timeIntervalSince1970: 0.123)

        XCTAssertEqual(SupabaseDateEncoding.isoTimestamp(date), "1970-01-01T00:00:00.123Z")
    }
}
