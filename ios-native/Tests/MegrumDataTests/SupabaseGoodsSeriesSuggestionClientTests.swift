import Foundation
import MegrumCore
import MegrumData
import XCTest

final class SupabaseGoodsSeriesSuggestionClientTests: XCTestCase {
    func testBuildsSuggestSeriesNamesRequest() throws {
        let client = SupabaseGoodsSeriesSuggestionClient(configuration: authenticatedConfiguration)
        let input = GoodsSeriesSuggestionInput(
            images: [
                GoodsSeriesSuggestionImage(
                    data: Data([0xFF, 0xD8, 0xFF]),
                    contentType: "image/jpeg"
                )
            ],
            groupName: "BTS",
            memberName: "RM",
            goodsTypeName: "トレカ",
            existingCandidateNames: [" 会場限定 ", "#ラキドロ", "会場限定"]
        )

        let request = try client.makeSuggestSeriesNamesRequest(input: input)
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        let images = try XCTUnwrap(json["images"] as? [[String: Any]])

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/functions/v1/suggest-goods-series")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer session_token")
        XCTAssertEqual(json["group_name"] as? String, "BTS")
        XCTAssertEqual(json["member_name"] as? String, "RM")
        XCTAssertEqual(json["goods_type_name"] as? String, "トレカ")
        XCTAssertEqual(json["existing_candidate_names"] as? [String], ["会場限定", "ラキドロ"])
        XCTAssertEqual(images.first?["content_type"] as? String, "image/jpeg")
        XCTAssertEqual(images.first?["base64"] as? String, Data([0xFF, 0xD8, 0xFF]).base64EncodedString())
    }

    func testSuggestSeriesNamesRejectsEmptyImageSource() throws {
        let client = SupabaseGoodsSeriesSuggestionClient(configuration: authenticatedConfiguration)
        let input = GoodsSeriesSuggestionInput(images: [])

        XCTAssertThrowsError(try client.makeSuggestSeriesNamesRequest(input: input)) { error in
            XCTAssertEqual(error as? SupabaseGoodsSeriesSuggestionClientError, .emptyImageSource)
        }
    }

    private var authenticatedConfiguration: SupabaseConfiguration {
        SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test",
            accessToken: "session_token"
        )
    }
}
