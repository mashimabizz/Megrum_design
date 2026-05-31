@testable import MegrumApp
import Foundation
import MegrumCore
import XCTest

final class GoodsEditorDraftTests: XCTestCase {
    func testCreateInputUsesResolvedTitleAndBoundsQuantity() throws {
        let groupID = UUID()
        let goodsTypeID = UUID()
        var draft = GoodsEditorDraft(mode: .create, entryKind: .inventory)
        draft.groupID = groupID
        draft.goodsTypeID = goodsTypeID
        draft.quantity = 1_200

        let input = try XCTUnwrap(
            draft.createInput(groupName: "TWICE", memberName: nil, goodsTypeName: "トレカ")
        )

        XCTAssertEqual(input.kind, .inventory)
        XCTAssertEqual(input.title, "TWICE トレカ")
        XCTAssertEqual(input.groupID, groupID)
        XCTAssertNil(input.memberID)
        XCTAssertEqual(input.goodsTypeID, goodsTypeID)
        XCTAssertEqual(input.quantity, 999)
        XCTAssertEqual(input.status, .active)
    }

    func testSwitchingEntryKindResetsInvalidStatus() {
        var draft = GoodsEditorDraft(mode: .create, entryKind: .inventory)
        draft.status = .keep

        draft.setEntryKind(.wish)

        XCTAssertEqual(draft.entryKind, .wish)
        XCTAssertEqual(draft.status, .wishActive)
    }

    func testTagsAndPhotoAreIncludedInCreateInput() throws {
        let groupID = UUID()
        let goodsTypeID = UUID()
        var draft = GoodsEditorDraft(mode: .create, entryKind: .inventory)
        draft.title = "ランダムトレカ"
        draft.groupID = groupID
        draft.goodsTypeID = goodsTypeID
        draft.memberID = UUID()
        draft.setLocalPhotoUpload(GoodsPhotoUpload(data: Data([0xFF, 0xD8, 0xFF]), contentType: "image/jpeg"))
        draft.addTag("#会場限定")

        let input = try XCTUnwrap(draft.createInput(groupName: "TWICE", memberName: "SANA", goodsTypeName: "トレカ"))
        XCTAssertTrue(draft.blockingReasons.isEmpty)
        XCTAssertEqual(input.tagNames, ["会場限定"])
        XCTAssertEqual(input.photoUpload?.contentType, "image/jpeg")
        XCTAssertEqual(input.photoUpload?.data, Data([0xFF, 0xD8, 0xFF]))
    }

    func testCameraCapturedJPEGIsHeldAsLocalPhotoUpload() throws {
        let groupID = UUID()
        let goodsTypeID = UUID()
        let cameraJPEG = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10])
        var draft = GoodsEditorDraft(mode: .create, entryKind: .wish)
        draft.title = "探しているトレカ"
        draft.groupID = groupID
        draft.goodsTypeID = goodsTypeID

        draft.setLocalPhotoUpload(GoodsPhotoUpload(data: cameraJPEG, contentType: "image/jpeg"))

        XCTAssertTrue(draft.hasLocalPhoto)
        XCTAssertTrue(draft.hasUnsavedLocalPhoto)
        XCTAssertEqual(draft.photoStatusText, "選択済み（保存前）")

        let input = try XCTUnwrap(draft.createInput(groupName: "TWICE", memberName: nil, goodsTypeName: "トレカ"))
        XCTAssertEqual(input.kind, .wish)
        XCTAssertEqual(input.photoUpload?.contentType, "image/jpeg")
        XCTAssertEqual(input.photoUpload?.data, cameraJPEG)
    }

    func testEditModeBuildsUpdateInput() throws {
        let groupID = UUID()
        let memberID = UUID()
        let goodsTypeID = UUID()
        let item = GoodsItem(
            id: UUID(),
            ownerID: UUID(),
            groupID: groupID,
            memberID: memberID,
            goodsTypeID: goodsTypeID,
            title: "既存グッズ",
            quantity: 2
        )

        var draft = GoodsEditorDraft(mode: .edit, entryKind: .inventory, item: item)
        draft.title = "  変更後  "
        draft.quantity = 4
        draft.status = .keep

        let input = try XCTUnwrap(draft.updateInput(groupName: "TWICE", memberName: "SANA", goodsTypeName: "トレカ"))
        XCTAssertNil(draft.createInput(groupName: "TWICE", memberName: nil, goodsTypeName: "トレカ"))
        XCTAssertEqual(input.title, "変更後")
        XCTAssertEqual(input.groupID, groupID)
        XCTAssertEqual(input.memberID, memberID)
        XCTAssertEqual(input.goodsTypeID, goodsTypeID)
        XCTAssertEqual(input.quantity, 4)
        XCTAssertEqual(input.status, .keep)
        XCTAssertEqual(input.tagNames, [])
    }

    func testTagsAreNormalizedDeduplicatedAndLimited() {
        var draft = GoodsEditorDraft(mode: .create, entryKind: .wish)

        ["#会場限定", " 会場限定 ", "トレカ", "生写真", "Type A", "横アリ", "追加不可"].forEach {
            draft.addTag($0)
        }

        XCTAssertEqual(draft.tagNames, ["会場限定", "トレカ", "生写真", "Type A", "横アリ"])
    }

    func testClearingLocalPhotoSelectionKeepsExistingImageURL() throws {
        let imageURL = try XCTUnwrap(URL(string: "https://example.com/goods.jpg"))
        let item = GoodsItem(
            id: UUID(),
            ownerID: UUID(),
            groupID: UUID(),
            goodsTypeID: UUID(),
            title: "既存グッズ",
            imageURL: imageURL
        )
        var draft = GoodsEditorDraft(mode: .edit, entryKind: .inventory, item: item)
        draft.setLocalPhotoUpload(GoodsPhotoUpload(data: Data([0xFF, 0xD8, 0xFF]), contentType: "image/jpeg"))

        XCTAssertTrue(draft.hasUnsavedLocalPhoto)

        draft.clearLocalPhotoSelection()
        let input = try XCTUnwrap(draft.updateInput(groupName: "TWICE", goodsTypeName: "トレカ"))

        XCTAssertFalse(draft.hasUnsavedLocalPhoto)
        XCTAssertEqual(input.photoURLs, [imageURL.absoluteString])
        XCTAssertNil(input.photoUpload)
    }

    func testSaveFailureMessageMentionsPhotoAndTagRecovery() {
        var draft = GoodsEditorDraft(mode: .create, entryKind: .wish)
        draft.addTag("会場限定")
        draft.hasLocalPhoto = true
        draft.localPhotoData = Data([0xFF, 0xD8, 0xFF])

        let failure = GoodsEditorSaveFailure.make(draft: draft, appMessage: "グッズを保存できませんでした")

        XCTAssertTrue(failure.includesPhotoUpload)
        XCTAssertTrue(failure.includesTagChanges)
        XCTAssertTrue(failure.message.contains("写真を外して保存"))
        XCTAssertTrue(failure.message.contains("タグは画面に残っている"))
        XCTAssertTrue(failure.message.contains("入力内容はこの画面に残しています"))
    }

    func testNormalizedPhotoUploadKeepsSupportedImageContentTypes() {
        let jpeg = normalizedPhotoUpload(from: Data([0xFF, 0xD8, 0xFF]))
        XCTAssertEqual(jpeg.contentType, "image/jpeg")

        let png = normalizedPhotoUpload(from: Data([0x89, 0x50, 0x4E, 0x47]))
        XCTAssertEqual(png.contentType, "image/png")

        let gif = normalizedPhotoUpload(from: Data([0x47, 0x49, 0x46, 0x38]))
        XCTAssertEqual(gif.contentType, "image/gif")

        let webp = normalizedPhotoUpload(from: Data("RIFFxxxxWEBP".utf8))
        XCTAssertEqual(webp.contentType, "image/webp")
    }

    func testPhotoUploadSizeErrorUsesLocalUploadLimit() {
        let upload = GoodsPhotoUpload(
            data: Data(repeating: 0x00, count: goodsEditorMaxPhotoUploadBytes + 1),
            contentType: "image/jpeg"
        )

        XCTAssertEqual(goodsEditorPhotoUploadError(for: upload), "写真は10MB以下にしてください")
    }
}
