@testable import MegrumData
import XCTest

final class SupabaseTextNormalizerTests: XCTestCase {
    func testTrimmedRemovesOuterWhitespaceAndNewlines() {
        XCTAssertEqual(SupabaseTextNormalizer.trimmed("  会場前\n"), "会場前")
    }

    func testOptionalReturnsNilForNilOrBlankText() {
        XCTAssertNil(SupabaseTextNormalizer.optional(nil))
        XCTAssertNil(SupabaseTextNormalizer.optional(" \n\t "))
    }

    func testOptionalKeepsTrimmedNonEmptyText() {
        XCTAssertEqual(SupabaseTextNormalizer.optional(" 北口 "), "北口")
    }

    func testNonEmptyValuesTrimsAndRemovesBlankValues() {
        XCTAssertEqual(
            SupabaseTextNormalizer.nonEmptyValues([" https://example.com/a.jpg ", " ", "\nhttps://example.com/b.jpg\n"]),
            ["https://example.com/a.jpg", "https://example.com/b.jpg"]
        )
    }
}
