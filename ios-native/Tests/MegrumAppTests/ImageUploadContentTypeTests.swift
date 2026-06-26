@testable import MegrumApp
import XCTest

final class ImageUploadContentTypeTests: XCTestCase {
    func testPhotoMessageContentTypeDetectsPngAndWebP() {
        XCTAssertEqual(
            inferredPhotoMessageContentType(from: Data([0x89, 0x50, 0x4E, 0x47, 0, 0, 0, 0])),
            "image/png"
        )
        XCTAssertEqual(
            inferredPhotoMessageContentType(from: Data("RIFFxxxxWEBP".utf8)),
            "image/webp"
        )
    }

    func testPhotoMessageContentTypeFallsBackToJpeg() {
        XCTAssertEqual(
            inferredPhotoMessageContentType(from: Data([0xFF, 0xD8, 0xFF])),
            "image/jpeg"
        )
        XCTAssertEqual(
            inferredPhotoMessageContentType(from: Data([0x47, 0x49, 0x46, 0x38])),
            "image/jpeg"
        )
        XCTAssertEqual(inferredPhotoMessageContentType(from: Data()), "image/jpeg")
    }

    func testChatPhotoUploadKeepsDisplayableFormatsAndConvertsGifToJpegFallback() {
        let png = normalizedChatPhotoUpload(from: Data([0x89, 0x50, 0x4E, 0x47]))
        let gif = normalizedChatPhotoUpload(from: Data([0x47, 0x49, 0x46, 0x38]))

        XCTAssertEqual(png.contentType, "image/png")
        XCTAssertEqual(gif.contentType, "image/jpeg")
    }

    func testEvidenceContentTypeUsesSharedInference() {
        XCTAssertEqual(
            inferredEvidenceImageContentType(from: Data("RIFFxxxxWEBP".utf8)),
            inferredPhotoMessageContentType(from: Data("RIFFxxxxWEBP".utf8))
        )
    }
}
