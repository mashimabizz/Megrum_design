@testable import MegrumData
import XCTest

final class SupabaseImageContentTypeNormalizerTests: XCTestCase {
    func testLenientNormalizerKeepsSupportedMapImageTypes() {
        XCTAssertEqual(SupabaseImageContentTypeNormalizer.lenient("image/png"), "image/png")
        XCTAssertEqual(SupabaseImageContentTypeNormalizer.lenient("IMAGE/WEBP"), "image/webp")
    }

    func testLenientNormalizerFallsBackToJPEGForOtherInputs() {
        XCTAssertEqual(SupabaseImageContentTypeNormalizer.lenient("image/jpeg"), "image/jpeg")
        XCTAssertEqual(SupabaseImageContentTypeNormalizer.lenient("image/jpg"), "image/jpeg")
        XCTAssertEqual(SupabaseImageContentTypeNormalizer.lenient("image/gif"), "image/jpeg")
        XCTAssertEqual(SupabaseImageContentTypeNormalizer.lenient(" image/png "), "image/jpeg")
    }

    func testLenientFileExtensionMatchesNormalizedContentType() {
        XCTAssertEqual(SupabaseImageContentTypeNormalizer.lenientFileExtension(for: "image/png"), "png")
        XCTAssertEqual(SupabaseImageContentTypeNormalizer.lenientFileExtension(for: "image/webp"), "webp")
        XCTAssertEqual(SupabaseImageContentTypeNormalizer.lenientFileExtension(for: "image/jpeg"), "jpg")
        XCTAssertEqual(SupabaseImageContentTypeNormalizer.lenientFileExtension(for: "image/gif"), "jpg")
    }
}
