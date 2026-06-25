import Foundation

public enum SupabaseRESTError: Error, Equatable, Sendable {
    case invalidURL
    case unexpectedStatus(Int)
}

struct StorageSignedURLResponse: Decodable, Sendable {
    var signedURL: String

    enum CodingKeys: String, CodingKey {
        case signedURL
    }
}
