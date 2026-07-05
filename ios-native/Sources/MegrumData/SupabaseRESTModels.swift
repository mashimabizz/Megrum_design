import Foundation

public enum SupabaseRESTError: Error, Equatable, Sendable {
    case invalidURL
    case unexpectedStatus(Int)
    /// サーバー（DBトリガー等）がユーザー向けメッセージ付きで拒否した。
    case serverRejected(status: Int, message: String)

    /// HTTPステータスコード（あれば）。レガシーフォールバック判定用。
    public var statusCode: Int? {
        switch self {
        case .invalidURL:
            nil
        case .unexpectedStatus(let status):
            status
        case .serverRejected(let status, _):
            status
        }
    }

    /// サーバーが返したユーザー向けメッセージ（あれば）。
    public var serverMessage: String? {
        if case .serverRejected(_, let message) = self {
            return message
        }
        return nil
    }

    static func from(status: Int, data: Data?) -> SupabaseRESTError {
        struct ErrorBody: Decodable {
            var message: String?
        }
        if let data,
           let body = try? JSONDecoder().decode(ErrorBody.self, from: data),
           let message = body.message?.trimmingCharacters(in: .whitespacesAndNewlines),
           !message.isEmpty {
            return .serverRejected(status: status, message: message)
        }
        return .unexpectedStatus(status)
    }
}

struct StorageSignedURLResponse: Decodable, Sendable {
    var signedURL: String

    enum CodingKeys: String, CodingKey {
        case signedURL
    }
}
