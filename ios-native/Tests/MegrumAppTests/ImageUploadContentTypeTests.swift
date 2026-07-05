@testable import MegrumApp
import XCTest
#if canImport(UIKit)
import UIKit
#endif

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

    #if canImport(UIKit)
    func testPhotoUploadDownscalesLargeLibraryImages() throws {
        let originalData = try XCTUnwrap(makeJPEGData(size: CGSize(width: 3_000, height: 2_200)))

        let upload = normalizedPhotoUpload(from: originalData)
        let normalizedImage = try XCTUnwrap(UIImage(data: upload.data))

        XCTAssertEqual(upload.contentType, "image/jpeg")
        XCTAssertLessThanOrEqual(normalizedImage.pixelMaxSideForTest, 2_048)
        XCTAssertLessThanOrEqual(upload.data.count, goodsEditorMaxPhotoUploadBytes)
    }

    func testChatPhotoUploadUsesSmallerDisplaySize() throws {
        let originalData = try XCTUnwrap(makeJPEGData(size: CGSize(width: 2_600, height: 1_900)))

        let upload = normalizedChatPhotoUpload(from: originalData)
        let normalizedImage = try XCTUnwrap(UIImage(data: upload.data))

        XCTAssertEqual(upload.contentType, "image/jpeg")
        XCTAssertLessThanOrEqual(normalizedImage.pixelMaxSideForTest, 1_600)
        XCTAssertLessThanOrEqual(upload.data.count, SupabaseChatPhotoStorage.maxUploadBytes)
    }

    func testCameraPhotoUploadNormalizesPortraitOrientation() throws {
        let rawLandscapeImage = makeImage(size: CGSize(width: 1_200, height: 800))
        let cgImage = try XCTUnwrap(rawLandscapeImage.cgImage)
        let portraitOrientedImage = UIImage(cgImage: cgImage, scale: 1, orientation: .right)

        let data = try XCTUnwrap(normalizedCameraPhotoData(from: portraitOrientedImage))
        let normalizedImage = try XCTUnwrap(UIImage(data: data))

        XCTAssertEqual(normalizedImage.imageOrientation, .up)
        XCTAssertLessThan(normalizedImage.pixelWidthForTest, normalizedImage.pixelHeightForTest)
    }
    #endif
}

#if canImport(UIKit)
private func makeJPEGData(size: CGSize) -> Data? {
    makeImage(size: size).jpegData(compressionQuality: 0.95)
}

private func makeImage(size: CGSize) -> UIImage {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    format.opaque = true
    return UIGraphicsImageRenderer(size: size, format: format).image { context in
        UIColor.white.setFill()
        context.fill(CGRect(origin: .zero, size: size))
        for index in 0..<120 {
            let hue = CGFloat(index) / 120
            UIColor(hue: hue, saturation: 0.65, brightness: 0.92, alpha: 1).setFill()
            let rect = CGRect(
                x: CGFloat(index * 37).truncatingRemainder(dividingBy: size.width),
                y: CGFloat(index * 53).truncatingRemainder(dividingBy: size.height),
                width: size.width / 5,
                height: size.height / 7
            )
            context.fill(rect)
        }
    }
}

private extension UIImage {
    var pixelMaxSideForTest: CGFloat {
        if let cgImage {
            return CGFloat(max(cgImage.width, cgImage.height))
        }
        return max(size.width * scale, size.height * scale)
    }

    var pixelWidthForTest: CGFloat {
        if let cgImage {
            return CGFloat(cgImage.width)
        }
        return size.width * scale
    }

    var pixelHeightForTest: CGFloat {
        if let cgImage {
            return CGFloat(cgImage.height)
        }
        return size.height * scale
    }
}
#endif
