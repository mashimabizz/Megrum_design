@testable import MegrumApp
import XCTest

final class MegrumAppStateInputNormalizerTests: XCTestCase {
    func testTrimmedTextRemovesOuterWhitespace() {
        XCTAssertEqual(MegrumAppStateInputNormalizer.trimmedText("  サナ  \n"), "サナ")
    }

    func testOptionalTextTrimsBlankValues() {
        XCTAssertEqual(MegrumAppStateInputNormalizer.optionalText("  PayPay相談可 "), "PayPay相談可")
        XCTAssertNil(MegrumAppStateInputNormalizer.optionalText(" \n "))
        XCTAssertNil(MegrumAppStateInputNormalizer.optionalText(nil))
    }

    func testProfileHandleTrimsLowercasesAndDropsLeadingAtMarks() {
        XCTAssertEqual(MegrumAppStateInputNormalizer.profileHandle("  @@Megrum_User  "), "megrum_user")
        XCTAssertNil(MegrumAppStateInputNormalizer.profileHandle(" @@@ "))
    }

    func testProfileHandleValidationUsesProfileEditRules() {
        XCTAssertTrue(MegrumAppStateInputNormalizer.isValidProfileHandle("michi_1"))
        XCTAssertTrue(MegrumAppStateInputNormalizer.isValidProfileHandle("abc"))
        XCTAssertFalse(MegrumAppStateInputNormalizer.isValidProfileHandle("mi"))
        XCTAssertFalse(MegrumAppStateInputNormalizer.isValidProfileHandle("michi-name"))
        XCTAssertFalse(MegrumAppStateInputNormalizer.isValidProfileHandle("michi_name_12345678901"))
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

    func testGoodsQuantityClampsToSupportedRange() {
        XCTAssertEqual(MegrumAppStateInputNormalizer.goodsQuantity(-1), 1)
        XCTAssertEqual(MegrumAppStateInputNormalizer.goodsQuantity(12), 12)
        XCTAssertEqual(MegrumAppStateInputNormalizer.goodsQuantity(1_000), 999)
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
