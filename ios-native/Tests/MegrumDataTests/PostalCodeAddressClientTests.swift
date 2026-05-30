import Foundation
import MegrumData
import XCTest

final class PostalCodeAddressClientTests: XCTestCase {
    func testBuildsZipCloudSearchRequest() throws {
        let client = PostalCodeAddressClient(baseURL: URL(string: "https://zipcloud.ibsnet.co.jp/api/search")!)

        let request = try client.makeSearchRequest(postalCode: "100-0001")

        XCTAssertEqual(request.url?.absoluteString, "https://zipcloud.ibsnet.co.jp/api/search?zipcode=1000001&limit=1")
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
    }

    func testRejectsIncompletePostalCode() {
        let client = PostalCodeAddressClient(baseURL: URL(string: "https://zipcloud.ibsnet.co.jp/api/search")!)

        XCTAssertThrowsError(try client.makeSearchRequest(postalCode: "100")) { error in
            XCTAssertEqual(error as? PostalCodeLookupError, .invalidPostalCode)
        }
    }

    func testNormalizesPostalCode() {
        XCTAssertEqual(PostalCodeAddressClient.normalizedPostalCode("〒100-0001"), "1000001")
        XCTAssertEqual(PostalCodeAddressClient.normalizedPostalCode("100000199"), "1000001")
    }
}
