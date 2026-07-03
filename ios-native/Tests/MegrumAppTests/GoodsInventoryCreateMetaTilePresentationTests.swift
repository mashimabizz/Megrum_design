@testable import MegrumApp
import XCTest

final class GoodsInventoryCreateMetaTilePresentationTests: XCTestCase {
    func testMissingSetupCountIgnoresMissingMemberDuringInitialCreate() {
        let meta = GoodsCreateMetaDraft()

        XCTAssertEqual(
            GoodsInventoryCreateMetaTilePresentation.missingSetupCount(
                for: meta,
                allowsMemberSelection: true,
                memberName: nil
            ),
            1
        )
    }

    func testMissingSetupCountDoesNotRequireMemberForSoloGroup() {
        let meta = GoodsCreateMetaDraft(tagNames: ["会場限定"])

        XCTAssertEqual(
            GoodsInventoryCreateMetaTilePresentation.missingSetupCount(
                for: meta,
                allowsMemberSelection: false,
                memberName: nil
            ),
            0
        )
    }

    func testGoodsEditorMemberLinkingPolicyKeepsInitialRegistrationOptional() {
        XCTAssertFalse(GoodsEditorMemberLinkingPolicy.presentsAutomaticFaceTaggingReview)
        XCTAssertFalse(GoodsEditorMemberLinkingPolicy.requiresMemberAssignmentDuringCreate)
    }

    func testTagLineShowsConfiguredTagsOnly() {
        XCTAssertNil(GoodsInventoryCreateMetaTilePresentation.tagLine(for: []))
        XCTAssertEqual(
            GoodsInventoryCreateMetaTilePresentation.tagLine(for: ["会場限定", "ラキドロ", "未開封"]),
            "# 会場限定 # ラキドロ ..."
        )
    }

    func testMetaFooterPresentationStateTracksMemberDialogAndSaveTitle() {
        var state = GoodsInventoryCreateMetaFooterPresentationState()

        XCTAssertFalse(state.isShowingMemberDialog)
        XCTAssertEqual(state.saveTitle(selectedCount: 0, totalCount: 3), "画像を選択してください")
        XCTAssertEqual(state.saveTitle(selectedCount: 2, totalCount: 3), "3件まとめて登録")
        XCTAssertEqual(state.saveTitle(selectedCount: 0, totalCount: 0), "0件まとめて登録")

        state.showMemberDialog()
        XCTAssertTrue(state.isShowingMemberDialog)
    }
}
