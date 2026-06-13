@testable import MegrumApp
import CoreGraphics
import Foundation
import ImageIO
import MegrumCore
import UniformTypeIdentifiers
import XCTest

final class GoodsEditorDraftTests: XCTestCase {
    func testInventoryCreateMetaBuildsInputPerPhoto() throws {
        let groupID = UUID()
        let memberID = UUID()
        let goodsTypeID = UUID()
        let photoUpload = GoodsPhotoUpload(data: Data([0xFF, 0xD8, 0xFF]), contentType: "image/jpeg")
        var draft = GoodsEditorDraft(mode: .create, entryKind: .inventory)
        draft.groupID = groupID
        draft.goodsTypeID = goodsTypeID
        draft.addTag("会場限定")

        let meta = GoodsCreateMetaDraft(photoID: UUID(), memberID: memberID, quantity: 2)
        let input = try XCTUnwrap(
            meta.createInput(
                sharedDraft: draft,
                photoUpload: photoUpload,
                groupName: "aespa",
                memberName: "KARINA",
                goodsTypeName: "トレカ"
            )
        )

        XCTAssertEqual(input.kind, .inventory)
        XCTAssertEqual(input.title, "KARINA aespa トレカ")
        XCTAssertEqual(input.memberID, memberID)
        XCTAssertEqual(input.quantity, 2)
        XCTAssertEqual(input.tagNames, ["会場限定"])
        XCTAssertEqual(input.photoUpload, photoUpload)
    }

    func testInventoryCreateMetaAutoResolvesTitleForOtherGoodsType() throws {
        var draft = GoodsEditorDraft(mode: .create, entryKind: .inventory)
        draft.groupID = UUID()
        draft.goodsTypeID = UUID()
        let blankMeta = GoodsCreateMetaDraft(memberID: UUID(), title: "   ")

        XCTAssertEqual(
            blankMeta.createInput(
                sharedDraft: draft,
                photoUpload: nil,
                groupName: "aespa",
                memberName: "KARINA",
                goodsTypeName: "その他"
            )?.title,
            "KARINA aespa その他"
        )

        let titledMeta = GoodsCreateMetaDraft(memberID: UUID(), title: "ランダム封入ミニカード")
        XCTAssertEqual(
            titledMeta.createInput(
                sharedDraft: draft,
                photoUpload: nil,
                groupName: "aespa",
                memberName: "KARINA",
                goodsTypeName: "その他"
            )?.title,
            "ランダム封入ミニカード"
        )
    }

    func testInventoryCreateMetaBoundsQuantity() throws {
        var draft = GoodsEditorDraft(mode: .create, entryKind: .inventory)
        draft.groupID = UUID()
        draft.goodsTypeID = UUID()
        let meta = GoodsCreateMetaDraft(quantity: 2_000)

        let input = try XCTUnwrap(
            meta.createInput(
                sharedDraft: draft,
                photoUpload: nil,
                groupName: "NCT",
                memberName: nil,
                goodsTypeName: "アクスタ"
            )
        )

        XCTAssertEqual(input.quantity, 999)
    }

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

    func testRemovingExistingWishPhotoEmitsEmptyPhotoURLs() throws {
        let imageURL = try XCTUnwrap(URL(string: "https://example.com/wish.jpg"))
        let item = GoodsItem(
            id: UUID(),
            ownerID: UUID(),
            groupID: UUID(),
            goodsTypeID: UUID(),
            title: "既存Wish",
            imageURL: imageURL
        )
        var draft = GoodsEditorDraft(mode: .edit, entryKind: .wish, item: item)

        draft.removeDisplayPhoto()
        let input = try XCTUnwrap(draft.updateInput(groupName: "TWICE", goodsTypeName: "トレカ"))

        XCTAssertTrue(draft.didRemoveExistingPhoto)
        XCTAssertNil(draft.existingImageURL)
        XCTAssertEqual(input.photoURLs, [])
        XCTAssertNil(input.photoUpload)
        XCTAssertEqual(draft.photoStatusText, "削除予定（保存前）")
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

    func testTradingCardBulkRecognizerSortsTopToBottomThenLeftToRight() {
        let centers = [
            CGPoint(x: 0.72, y: 0.42),
            CGPoint(x: 0.68, y: 0.18),
            CGPoint(x: 0.18, y: 0.19),
            CGPoint(x: 0.22, y: 0.43)
        ]

        let sorted = TradingCardBulkRecognizer.sortedTopLeftCenters(centers)

        zip(sorted.map(\.x), [0.18, 0.68, 0.22, 0.72]).forEach { actual, expected in
            XCTAssertEqual(actual, expected, accuracy: 0.001)
        }
        zip(sorted.map(\.y), [0.19, 0.18, 0.43, 0.42]).forEach { actual, expected in
            XCTAssertEqual(actual, expected, accuracy: 0.001)
        }
    }

    func testTradingCardBulkRecognizerFallsBackToOriginalWhenNoCardIsDetected() async throws {
        let data = try makeSolidJPEGData()

        let results = try await TradingCardBulkRecognizer.recognizeCards(in: data, maximumCards: 3)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.source, .fallbackOriginal)
        XCTAssertEqual(results.first?.contentType, "image/jpeg")
        XCTAssertFalse(results.first?.data.isEmpty ?? true)
    }

    func testTradingCardBulkRecognizerRejectsInvalidImageData() async {
        do {
            _ = try await TradingCardBulkRecognizer.recognizeCards(in: Data([0x00, 0x01, 0x02]))
            XCTFail("Invalid image data should not be recognized")
        } catch let error as TradingCardBulkRecognitionError {
            XCTAssertEqual(error.errorDescription, "画像を読み込めませんでした。")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    private func makeSolidJPEGData(width: Int = 40, height: Int = 40) throws -> Data {
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let pixels = Data(repeating: 0xF5, count: width * height * bytesPerPixel)
        guard let provider = CGDataProvider(data: pixels as CFData),
              let image = CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
              )
        else {
            XCTFail("Failed to create test image")
            return Data()
        }

        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            output,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            XCTFail("Failed to create JPEG destination")
            return Data()
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            XCTFail("Failed to write JPEG")
            return Data()
        }
        return output as Data
    }
}
