@testable import MegrumApp
import MegrumCore
import XCTest

final class SupabaseProfilePhotoStorageTests: XCTestCase {
    func testMakeUploadBuildsDeterministicJPEGPathAndNormalizesAlias() throws {
        let upload = GoodsPhotoUpload(data: Data([0xFF, 0xD8, 0xFF]), contentType: " image/jpg ")

        let preparedUpload = try SupabaseProfilePhotoStorage.makeUpload(
            upload,
            userID: userID,
            now: fixedDate,
            uuid: fixedUUID
        )

        XCTAssertEqual(preparedUpload.contentType, "image/jpeg")
        XCTAssertEqual(
            preparedUpload.path,
            "00000000-0000-0000-0000-000000000901/1700000000000_00000000-0000-0000-0000-000000000902.jpg"
        )
    }

    func testMakeUploadUsesSupportedContentTypeExtensions() throws {
        let cases: [(String, String, String)] = [
            ("image/png", "image/png", "png"),
            ("image/webp", "image/webp", "webp"),
            ("image/gif", "image/gif", "gif")
        ]

        for (inputContentType, expectedContentType, expectedExtension) in cases {
            let upload = GoodsPhotoUpload(data: Data([1]), contentType: inputContentType)
            let preparedUpload = try SupabaseProfilePhotoStorage.makeUpload(
                upload,
                userID: userID,
                now: fixedDate,
                uuid: fixedUUID
            )

            XCTAssertEqual(preparedUpload.contentType, expectedContentType)
            XCTAssertTrue(preparedUpload.path.hasSuffix(".\(expectedExtension)"))
        }
    }

    func testMakeUploadRejectsUnsupportedContentType() {
        let upload = GoodsPhotoUpload(data: Data([1]), contentType: "image/heic")

        XCTAssertThrowsError(
            try SupabaseProfilePhotoStorage.makeUpload(
                upload,
                userID: userID,
                now: fixedDate,
                uuid: fixedUUID
            )
        ) { error in
            XCTAssertEqual(error as? ProfilePhotoUploadError, .unsupportedImageContentType)
        }
    }

    func testMakeUploadRejectsOversizedImage() {
        let upload = GoodsPhotoUpload(
            data: Data(count: SupabaseProfilePhotoStorage.maxUploadBytes + 1),
            contentType: "image/jpeg"
        )

        XCTAssertThrowsError(
            try SupabaseProfilePhotoStorage.makeUpload(
                upload,
                userID: userID,
                now: fixedDate,
                uuid: fixedUUID
            )
        ) { error in
            XCTAssertEqual(error as? ProfilePhotoUploadError, .imageTooLarge)
        }
    }

    private var userID: UUID {
        UUID(uuidString: "00000000-0000-0000-0000-000000000901")!
    }

    private var fixedUUID: UUID {
        UUID(uuidString: "00000000-0000-0000-0000-000000000902")!
    }

    private var fixedDate: Date {
        Date(timeIntervalSince1970: 1_700_000_000)
    }
}
