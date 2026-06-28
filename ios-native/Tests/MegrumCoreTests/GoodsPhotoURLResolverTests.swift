import MegrumCore
import XCTest

final class GoodsPhotoURLResolverTests: XCTestCase {
    func testKeepsExternalImageURL() {
        let url = GoodsPhotoURLResolver.displayURL(from: "https://cdn.example.com/goods/a.jpg")

        XCTAssertEqual(url?.absoluteString, "https://cdn.example.com/goods/a.jpg")
    }

    func testConvertsExpiredSignedGoodsPhotoURLToPublicObjectURL() {
        let url = GoodsPhotoURLResolver.displayURL(
            from: "https://example.supabase.co/storage/v1/object/sign/goods-photos/user/photo.jpg?token=old"
        )

        XCTAssertEqual(
            url?.absoluteString,
            "https://example.supabase.co/storage/v1/object/public/goods-photos/user/photo.jpg"
        )
    }

    func testConvertsRawStoragePathWhenProjectURLIsKnown() throws {
        let projectURL = try XCTUnwrap(URL(string: "https://example.supabase.co"))
        let url = GoodsPhotoURLResolver.displayURL(
            from: "user/photo with space.jpg",
            projectURL: projectURL
        )

        XCTAssertEqual(
            url?.absoluteString,
            "https://example.supabase.co/storage/v1/object/public/goods-photos/user/photo%20with%20space.jpg"
        )
    }
}
