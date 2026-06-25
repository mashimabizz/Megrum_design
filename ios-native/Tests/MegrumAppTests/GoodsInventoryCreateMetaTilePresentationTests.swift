@testable import MegrumApp
import XCTest

final class GoodsInventoryCreateMetaTilePresentationTests: XCTestCase {
    func testMissingSetupCountIncludesMissingTagAndRequiredMember() {
        let meta = GoodsCreateMetaDraft()

        XCTAssertEqual(
            GoodsInventoryCreateMetaTilePresentation.missingSetupCount(
                for: meta,
                allowsMemberSelection: true,
                memberName: nil
            ),
            2
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

    func testTagLineShowsConfiguredTagsOnly() {
        XCTAssertNil(GoodsInventoryCreateMetaTilePresentation.tagLine(for: []))
        XCTAssertEqual(
            GoodsInventoryCreateMetaTilePresentation.tagLine(for: ["会場限定", "ラキドロ", "未開封"]),
            "# 会場限定 # ラキドロ ..."
        )
    }
}
