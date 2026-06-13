@testable import MegrumApp
import XCTest

final class MegrumAppStateInputNormalizerTests: XCTestCase {
    func testProfileHandleTrimsLowercasesAndDropsLeadingAtMarks() {
        XCTAssertEqual(MegrumAppStateInputNormalizer.profileHandle("  @@Megrum_User  "), "megrum_user")
        XCTAssertNil(MegrumAppStateInputNormalizer.profileHandle(" @@@ "))
    }

    func testPostalCodeKeepsFirstSevenDigits() {
        XCTAssertEqual(MegrumAppStateInputNormalizer.postalCode("〒100-0001"), "1000001")
        XCTAssertEqual(MegrumAppStateInputNormalizer.postalCode("100000199"), "1000001")
    }

    func testPrefectureTrimsBlankValues() {
        XCTAssertEqual(MegrumAppStateInputNormalizer.prefecture(" Tokyo "), "Tokyo")
        XCTAssertNil(MegrumAppStateInputNormalizer.prefecture("  \n "))
        XCTAssertNil(MegrumAppStateInputNormalizer.prefecture(nil))
    }

    func testTagNamesTrimHashesDeduplicateAndCapCount() {
        let tags = MegrumAppStateInputNormalizer.tagNames([
            " #SANA ",
            "sana",
            "＃MOMO",
            "",
            "#DAHYUN",
            "#MINA",
            "#JIHYO",
            "#TZUYU"
        ])

        XCTAssertEqual(tags, ["SANA", "MOMO", "DAHYUN", "MINA", "JIHYO"])
    }

    func testTagNamesClipLongValues() {
        let clipped = MegrumAppStateInputNormalizer.tagNames([String(repeating: "a", count: 60)])

        XCTAssertEqual(clipped.first?.count, 50)
    }
}
