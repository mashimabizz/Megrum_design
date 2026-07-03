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
        let context = GoodsSharePostContext(kind: .inventory, items: items, displayName: "めぐるむ")

        XCTAssertEqual(context.shareItems.count, 20)
    }

    func testBuildsWishPostText() {
        let item = makeItem(
            ownerID: UUID(),
            groupName: "TWICE",
            memberName: "サナ",
            goodsTypeName: "缶バッジ",
            tagNames: ["ラントレ"]
        )

        XCTAssertEqual(
            GoodsSharePostTextBuilder.text(for: [item], kind: .wish),
            """
            Megrumで欲しいものを登録しました！

            #TWICE #サナ #ラントレ #缶バッジ #グッズ交換
            """
        )
    }

    func testBuildsSelectedItemsPostTextWithCustomLead() {
        let item = makeItem(
            ownerID: UUID(),
            groupName: "TWICE",
            memberName: "サナ",
            goodsTypeName: "缶バッジ",
            tagNames: ["ラントレ"]
        )

        XCTAssertEqual(
            GoodsSharePostTextBuilder.text(
                for: [item],
                kind: .wish,
                leadingTextOverride: "Megrumで欲しいものをまとめました！"
            ),
            """
            Megrumで欲しいものをまとめました！

            #TWICE #サナ #ラントレ #缶バッジ #グッズ交換
            """
        )
    }

    func testBuildsListingPostTextWithPaymentMethods() {
        let snapshot = IndividualListingShareSnapshot(
            listingID: UUID(),
            displayName: "めぐるむ",
            wantedRows: [],
            offeredRows: [],
            exchangeConditionLines: ["交換手段: 現地交換", "現地: 大阪府 / 会場付近 / 相談"],
            paymentMethodsText: "銀行振込, PayPay, 現金交換",
            hashtagValues: ["BTS", "ジミン", "BTS", "個別募集"]
        )

        XCTAssertEqual(
            GoodsSharePostTextBuilder.text(for: snapshot),
            """
            Megrumで個別募集を追加しました！

            求めるものは1枚目、譲るものは2枚目の画像にあります。

            交換条件: 交換手段: 現地交換 / 現地: 大阪府 / 会場付近 / 相談

            支払い方法: 銀行振込, PayPay, 現金交換

            #BTS #ジミン #個別募集
            """
        )
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
