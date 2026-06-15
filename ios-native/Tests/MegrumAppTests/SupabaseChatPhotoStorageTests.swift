@testable import MegrumApp
import MegrumCore
import MegrumData
import XCTest

final class SupabaseChatPhotoStorageTests: XCTestCase {
    func testMakeUploadBuildsDeterministicPhotoPathAndNormalizesContentType() throws {
        let input = TradePhotoMessageCreateInput(
            proposalID: proposalID,
            imageData: Data([1, 2, 3]),
            imageContentType: "image/png",
            messageType: .photo
        )

        let upload = try SupabaseChatPhotoStorage.makeUpload(
            input: input,
            now: fixedDate,
            uuid: fixedUUID
        )

        XCTAssertEqual(upload.contentType, "image/png")
        XCTAssertEqual(
            upload.path,
            "00000000-0000-0000-0000-000000000801/photo-1700000000000-00000000-0000-0000-0000-000000000802.png"
        )
    }

    func testMakeUploadUsesOutfitPrefixAndWebPExtension() throws {
        let input = TradePhotoMessageCreateInput(
            proposalID: proposalID,
            imageData: Data([1]),
            imageContentType: "image/webp",
            messageType: .outfitPhoto
        )

        let upload = try SupabaseChatPhotoStorage.makeUpload(
            input: input,
            now: fixedDate,
            uuid: fixedUUID
        )

        XCTAssertEqual(upload.contentType, "image/webp")
        XCTAssertEqual(
            upload.path,
            "00000000-0000-0000-0000-000000000801/outfit-1700000000000-00000000-0000-0000-0000-000000000802.webp"
        )
    }

    func testMakeUploadDefaultsUnknownContentTypeToJPEG() throws {
        let input = TradePhotoMessageCreateInput(
            proposalID: proposalID,
            imageData: Data([1]),
            imageContentType: "image/heic",
            messageType: .photo
        )

        let upload = try SupabaseChatPhotoStorage.makeUpload(
            input: input,
            now: fixedDate,
            uuid: fixedUUID
        )

        XCTAssertEqual(upload.contentType, "image/jpeg")
        XCTAssertTrue(upload.path.hasSuffix(".jpg"))
    }

    func testMakeUploadRejectsNonPhotoMessageType() {
        let input = TradePhotoMessageCreateInput(
            proposalID: proposalID,
            imageData: Data([1]),
            imageContentType: "image/png",
            messageType: .text
        )

        XCTAssertThrowsError(
            try SupabaseChatPhotoStorage.makeUpload(
                input: input,
                now: fixedDate,
                uuid: fixedUUID
            )
        ) { error in
            XCTAssertEqual(error as? SupabaseMessageClientError, .invalidPhotoMessageType)
        }
    }

    func testMakeUploadRejectsOversizedImage() {
        let input = TradePhotoMessageCreateInput(
            proposalID: proposalID,
            imageData: Data(count: SupabaseChatPhotoStorage.maxUploadBytes + 1),
            imageContentType: "image/png",
            messageType: .photo
        )

        XCTAssertThrowsError(
            try SupabaseChatPhotoStorage.makeUpload(
                input: input,
                now: fixedDate,
                uuid: fixedUUID
            )
        ) { error in
            XCTAssertEqual(error as? SupabaseProposalClientError, .imageTooLarge)
        }
    }

    private var proposalID: UUID {
        UUID(uuidString: "00000000-0000-0000-0000-000000000801")!
    }

    private var fixedUUID: UUID {
        UUID(uuidString: "00000000-0000-0000-0000-000000000802")!
    }

    private var fixedDate: Date {
        Date(timeIntervalSince1970: 1_700_000_000)
    }
}
