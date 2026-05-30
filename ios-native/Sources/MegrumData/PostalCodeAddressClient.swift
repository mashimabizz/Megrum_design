import Foundation
import MegrumCore

public enum PostalCodeLookupError: Error, Equatable, Sendable {
    case invalidURL
    case invalidPostalCode
    case unexpectedHTTPStatus(Int)
    case serviceStatus(Int, String?)
}

public final class PostalCodeAddressClient: @unchecked Sendable {
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder

    public init(
        baseURL: URL = URL(string: "https://zipcloud.ibsnet.co.jp/api/search")!,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = JSONDecoder()
    }

    public func lookup(postalCode: String) async throws -> PostalCodeAddress? {
        let request = try makeSearchRequest(postalCode: postalCode)
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PostalCodeLookupError.unexpectedHTTPStatus(-1)
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw PostalCodeLookupError.unexpectedHTTPStatus(httpResponse.statusCode)
        }

        let decoded = try decoder.decode(ZipCloudSearchResponse.self, from: data)
        guard decoded.status == 200 else {
            throw PostalCodeLookupError.serviceStatus(decoded.status, decoded.message)
        }
        return decoded.results?.first?.address
    }

    public func makeSearchRequest(postalCode: String) throws -> URLRequest {
        let normalizedPostalCode = Self.normalizedPostalCode(postalCode)
        guard normalizedPostalCode.count == 7 else {
            throw PostalCodeLookupError.invalidPostalCode
        }
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw PostalCodeLookupError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "zipcode", value: normalizedPostalCode),
            URLQueryItem(name: "limit", value: "1")
        ]
        guard let url = components.url else {
            throw PostalCodeLookupError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    public static func normalizedPostalCode(_ value: String) -> String {
        String(value.filter(\.isNumber).prefix(7))
    }
}

private struct ZipCloudSearchResponse: Decodable, Sendable {
    var status: Int
    var message: String?
    var results: [ZipCloudAddressRow]?
}

private struct ZipCloudAddressRow: Decodable, Sendable {
    var zipcode: String
    var address1: String
    var address2: String
    var address3: String

    var address: PostalCodeAddress {
        PostalCodeAddress(
            postalCode: PostalCodeAddressClient.normalizedPostalCode(zipcode),
            prefecture: address1,
            city: address2,
            town: address3
        )
    }
}
