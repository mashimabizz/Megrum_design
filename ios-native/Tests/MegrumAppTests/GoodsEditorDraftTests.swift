@testable import MegrumApp
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
        XCTAssertEqual(input.goodsTypeID, goodsTypeID)
        XCTAssertEqual(input.quantity, 999)
    }

    func testSwitchingEntryKindResetsInvalidStatus() {
        var draft = GoodsEditorDraft(mode: .create, entryKind: .inventory)
        draft.status = .keep

        draft.setEntryKind(.wish)

        XCTAssertEqual(draft.entryKind, .wish)
        XCTAssertEqual(draft.status, .wishActive)
    }

    func testUnsupportedFieldsBlockCreateInsteadOfBeingDropped() {
        let groupID = UUID()
        let goodsTypeID = UUID()
        var draft = GoodsEditorDraft(mode: .create, entryKind: .inventory)
        draft.title = "ランダムトレカ"
        draft.groupID = groupID
        draft.goodsTypeID = goodsTypeID
        draft.memberID = UUID()
        draft.hasLocalPhoto = true
        draft.addTag("#会場限定")

        XCTAssertEqual(
            draft.blockingReasons,
            [.memberPersistence, .tagPersistence, .photoPersistence]
        )
        XCTAssertNil(draft.createInput(groupName: "TWICE", memberName: "SANA", goodsTypeName: "トレカ"))
    }

    func testEditModeIsBlockedUntilUpdateBoundaryExists() {
        let item = GoodsItem(
            id: UUID(),
            ownerID: UUID(),
            groupID: UUID(),
            goodsTypeID: UUID(),
            title: "既存グッズ",
            quantity: 2
        )

        let draft = GoodsEditorDraft(mode: .edit, entryKind: .inventory, item: item)

        XCTAssertTrue(draft.blockingReasons.contains(.editPersistence))
        XCTAssertNil(draft.createInput(groupName: "TWICE", memberName: nil, goodsTypeName: "トレカ"))
    }

    func testTagsAreNormalizedDeduplicatedAndLimited() {
        var draft = GoodsEditorDraft(mode: .create, entryKind: .wish)

        ["#会場限定", " 会場限定 ", "トレカ", "生写真", "Type A", "横アリ", "追加不可"].forEach {
            draft.addTag($0)
        }

        XCTAssertEqual(draft.tagNames, ["会場限定", "トレカ", "生写真", "Type A", "横アリ"])
    }
}
