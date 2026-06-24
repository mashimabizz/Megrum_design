@testable import MegrumApp
import MegrumCore
import MegrumData
import XCTest

final class SupabaseGoodsEntryPersistenceTests: XCTestCase {
    func testCreatePhotoURLsUsesUploadedPhotoOnlyWhenPresent() {
        XCTAssertEqual(SupabaseGoodsEntryPersistence.createPhotoURLs(uploadedPhotoURL: nil), [])
        XCTAssertEqual(
            SupabaseGoodsEntryPersistence.createPhotoURLs(
                uploadedPhotoURL: nil,
                copiedPhotoURLs: [
                    " https://example.com/copied.jpg ",
                    "",
                    "https://example.com/copied.jpg",
                    "not-a-url"
                ]
            ),
            ["https://example.com/copied.jpg"]
        )
        XCTAssertEqual(
            SupabaseGoodsEntryPersistence.createPhotoURLs(
                uploadedPhotoURL: "https://example.com/goods.jpg",
                copiedPhotoURLs: ["https://example.com/copied.jpg"]
            ),
            ["https://example.com/goods.jpg"]
        )
    }

    func testUpdateInputPrefersUploadedPhotoOverExistingPhotoURLs() {
        let groupID = UUID(uuidString: "00000000-0000-0000-0000-000000001001")!
        let memberID = UUID(uuidString: "00000000-0000-0000-0000-000000001002")!
        let goodsTypeID = UUID(uuidString: "00000000-0000-0000-0000-000000001003")!
        let input = GoodsEntryUpdateInput(
            title: "サナ トレカ",
            groupID: groupID,
            memberID: memberID,
            clearsMemberID: false,
            goodsTypeID: goodsTypeID,
            quantity: 2,
            status: .archived,
            photoURLs: ["https://example.com/old.jpg"],
            tagNames: ["2026 LIVE"],
            photoUpload: nil
        )

        let updateInput = SupabaseGoodsEntryPersistence.updateInput(
            from: input,
            uploadedPhotoURL: "https://example.com/new.jpg"
        )

        XCTAssertEqual(updateInput.title, "サナ トレカ")
        XCTAssertEqual(updateInput.groupID, groupID)
        XCTAssertEqual(updateInput.characterID, memberID)
        XCTAssertFalse(updateInput.clearsCharacterID)
        XCTAssertEqual(updateInput.goodsTypeID, goodsTypeID)
        XCTAssertEqual(updateInput.quantity, 2)
        XCTAssertEqual(updateInput.status, .archived)
        XCTAssertEqual(updateInput.photoURLs, ["https://example.com/new.jpg"])
        XCTAssertEqual(updateInput.tagNames, ["2026 LIVE"])
    }

    func testUpdateInputKeepsExistingPhotoURLsWhenNoUploadWasAdded() {
        let groupID = UUID(uuidString: "00000000-0000-0000-0000-000000001004")!
        let goodsTypeID = UUID(uuidString: "00000000-0000-0000-0000-000000001005")!
        let input = GoodsEntryUpdateInput(
            title: "既存グッズ",
            groupID: groupID,
            memberID: nil,
            clearsMemberID: true,
            goodsTypeID: goodsTypeID,
            quantity: 1,
            status: .active,
            photoURLs: ["https://example.com/old.jpg"],
            tagNames: nil,
            photoUpload: nil
        )

        let updateInput = SupabaseGoodsEntryPersistence.updateInput(
            from: input,
            uploadedPhotoURL: nil
        )

        XCTAssertEqual(updateInput.title, "既存グッズ")
        XCTAssertEqual(updateInput.groupID, groupID)
        XCTAssertNil(updateInput.characterID)
        XCTAssertTrue(updateInput.clearsCharacterID)
        XCTAssertEqual(updateInput.goodsTypeID, goodsTypeID)
        XCTAssertEqual(updateInput.quantity, 1)
        XCTAssertEqual(updateInput.status, GoodsInventoryStatus.active)
        XCTAssertEqual(updateInput.photoURLs, ["https://example.com/old.jpg"])
        XCTAssertNil(updateInput.tagNames)
    }
}
