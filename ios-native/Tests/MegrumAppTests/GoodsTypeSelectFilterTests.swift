import Foundation
import MegrumCore
import XCTest
@testable import MegrumApp

final class GoodsTypeSelectFilterTests: XCTestCase {
    private func makeTypes(_ names: [String]) -> [GoodsType] {
        names.enumerated().map { index, name in
            GoodsType(id: UUID(), name: name, displayOrder: index + 1)
        }
    }

    func testEmptySearchReturnsAllTypes() {
        let types = makeTypes(["トレカ", "アクリルスタンド", "その他"])

        XCTAssertEqual(GoodsTypeSelectFilter.filtered(types, searchText: "").map(\.name), ["トレカ", "アクリルスタンド", "その他"])
        XCTAssertEqual(GoodsTypeSelectFilter.filtered(types, searchText: "   ").map(\.name), ["トレカ", "アクリルスタンド", "その他"])
    }

    func testPartialMatchFiltersByName() {
        let types = makeTypes(["トレカ", "アクリルスタンド", "アクリルキーホルダー", "キーホルダー", "その他"])

        XCTAssertEqual(
            GoodsTypeSelectFilter.filtered(types, searchText: "アクリル").map(\.name),
            ["アクリルスタンド", "アクリルキーホルダー"]
        )
        XCTAssertEqual(
            GoodsTypeSelectFilter.filtered(types, searchText: "キーホルダー").map(\.name),
            ["アクリルキーホルダー", "キーホルダー"]
        )
    }

    func testCaseInsensitiveMatchForLatinNames() {
        let types = makeTypes(["Tシャツ・アパレル", "CD・DVD・ブルーレイ", "DIY・工具"])

        XCTAssertEqual(
            GoodsTypeSelectFilter.filtered(types, searchText: "dvd").map(\.name),
            ["CD・DVD・ブルーレイ"]
        )
        XCTAssertEqual(
            GoodsTypeSelectFilter.filtered(types, searchText: "diy").map(\.name),
            ["DIY・工具"]
        )
    }

    func testNoMatchReturnsEmpty() {
        let types = makeTypes(["トレカ", "ポスター"])

        XCTAssertTrue(GoodsTypeSelectFilter.filtered(types, searchText: "存在しない種別").isEmpty)
    }
}
