import MegrumCore
@testable import MegrumApp
import XCTest

final class GoodsSharePostTextBuilderTests: XCTestCase {
    func testBuildsPostTextWithDeduplicatedHashtags() {
        let ownerID = UUID()
        let items = [
            makeItem(
                ownerID: ownerID,
                groupName: "BTS",
                memberName: "ジミン",
                goodsTypeName: "トレカ",
                tagNames: ["会場限定", "BTS"]
            ),
            makeItem(
                ownerID: ownerID,
                groupName: "BTS",
                memberName: "ジミン",
                goodsTypeName: "トレカ",
                tagNames: ["会場限定"]
            )
        ]

        XCTAssertEqual(
            GoodsSharePostTextBuilder.text(for: items),
            """
            Megrumで譲るグッズを登録しました！

            #BTS #ジミン #会場限定 #トレカ #グッズ交換
            """
        )
    }

    func testSanitizesHashtagValues() {
        let item = makeItem(
            ownerID: UUID(),
            groupName: " #New Jeans ",
            memberName: " ミンジ ",
            goodsTypeName: " アクスタ ",
            tagNames: [" #2026 Tour ", "New Jeans"]
        )

        XCTAssertEqual(
            GoodsSharePostTextBuilder.text(for: [item]),
            """
            Megrumで譲るグッズを登録しました！

            #NewJeans #ミンジ #2026Tour #アクスタ #グッズ交換
            """
        )
    }

    func testLimitsShareContextItemsToTwenty() {
        let items = (0..<24).map { index in
            makeItem(ownerID: UUID(), groupName: "Group\(index)", memberName: nil, goodsTypeName: "トレカ", tagNames: [])
        }
        let context = GoodsSharePostContext(items: items, displayName: "めぐるむ")

        XCTAssertEqual(context.shareItems.count, 20)
    }

    private func makeItem(
        ownerID: UUID,
        groupName: String?,
        memberName: String?,
        goodsTypeName: String?,
        tagNames: [String]
    ) -> GoodsItem {
        GoodsItem(
            id: UUID(),
            ownerID: ownerID,
            kind: .inventory,
            status: .active,
            groupID: UUID(),
            memberID: memberName == nil ? nil : UUID(),
            goodsTypeID: UUID(),
            groupName: groupName,
            memberName: memberName,
            goodsTypeName: goodsTypeName,
            title: "譲るグッズ",
            tags: tagNames.map { GoodsTag(id: UUID(), name: $0) }
        )
    }
}
