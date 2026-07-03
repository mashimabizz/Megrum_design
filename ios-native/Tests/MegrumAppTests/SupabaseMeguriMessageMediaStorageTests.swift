@testable import MegrumApp
import MegrumCore
import MegrumData
import XCTest

final class SupabaseMeguriMessageMediaStorageTests: XCTestCase {
    func testMakeUploadBuildsSenderScopedPhotoPathAndNormalizesContentType() throws {
        let input = MeguriPhotoMessageCreateInput(
            senderID: senderID,
            recipientID: recipientID,
            imageData: Data([1, 2, 3]),
            imageContentType: "image/png"
        )

        let upload = try SupabaseMeguriMessageMediaStorage.makeUpload(
            input: input,
            now: fixedDate,
            uuid: fixedUUID
        )

        XCTAssertEqual(upload.contentType, "image/png")
        XCTAssertEqual(
            upload.path,
            "00000000-0000-0000-0000-000000000001/message-1700000000000-00000000-0000-0000-0000-000000000802.png"
        )
    }

    func testMakeUploadDefaultsUnknownContentTypeToJPEG() throws {
        let input = MeguriPhotoMessageCreateInput(
            senderID: senderID,
            recipientID: recipientID,
            imageData: Data([1]),
            imageContentType: "image/heic"
        )

        let upload = try SupabaseMeguriMessageMediaStorage.makeUpload(
            input: input,
            now: fixedDate,
            uuid: fixedUUID
        )

        XCTAssertEqual(upload.contentType, "image/jpeg")
        XCTAssertTrue(upload.path.hasSuffix(".jpg"))
    }

    func testMakeUploadRejectsEmptyImage() {
        let input = MeguriPhotoMessageCreateInput(
            senderID: senderID,
            recipientID: recipientID,
            imageData: Data(),
            imageContentType: "image/png"
        )

        XCTAssertThrowsError(
            try SupabaseMeguriMessageMediaStorage.makeUpload(
                input: input,
                now: fixedDate,
                uuid: fixedUUID
            )
        ) { error in
            XCTAssertEqual(error as? SupabaseMeguriMessageMediaStorageError, .emptyImage)
        }
    }

    private var senderID: UUID {
        UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    }

    private var recipientID: UUID {
        UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
    }

    private var fixedUUID: UUID {
        UUID(uuidString: "00000000-0000-0000-0000-000000000802")!
    }

    private var fixedDate: Date {
        Date(timeIntervalSince1970: 1_700_000_000)
    }
}
