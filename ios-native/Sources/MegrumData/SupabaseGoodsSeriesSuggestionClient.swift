import Foundation
import MegrumCore

public enum SupabaseGoodsSeriesSuggestionClientError: Error, Equatable, Sendable {
    case emptyImageSource
}

public final class SupabaseGoodsSeriesSuggestionClient: @unchecked Sendable {
    let client: SupabaseRESTClient

    public init(configuration: SupabaseConfiguration, session: URLSession = .shared) {
        self.client = SupabaseRESTClient(configuration: configuration, session: session)
    }

    public init(client: SupabaseRESTClient) {
        self.client = client
    }

    public func suggestSeriesNames(input: GoodsSeriesSuggestionInput) async throws -> [String] {
        let response: GoodsSeriesSuggestionResponse = try await client.invokeFunction(
            name: "suggest-goods-series",
            payload: try makePayload(input: input)
        )
        return response.normalizedSuggestionNames(limit: 6)
    }

    public func makeSuggestSeriesNamesRequest(input: GoodsSeriesSuggestionInput) throws -> URLRequest {
        try client.makeFunctionRequest(
            name: "suggest-goods-series",
            payload: try makePayload(input: input)
        )
    }

    private func makePayload(input: GoodsSeriesSuggestionInput) throws -> GoodsSeriesSuggestionPayload {
        let images = input.images.prefix(3).compactMap(GoodsSeriesSuggestionImagePayload.init(source:))
        guard !images.isEmpty else {
            throw SupabaseGoodsSeriesSuggestionClientError.emptyImageSource
        }
        return GoodsSeriesSuggestionPayload(
            images: images,
            groupName: trimmed(input.groupName),
            memberName: trimmed(input.memberName),
            goodsTypeName: trimmed(input.goodsTypeName),
            existingCandidateNames: normalizedNames(input.existingCandidateNames, limit: 10)
        )
    }

    private func trimmed(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }

    private func normalizedNames(_ names: [String], limit: Int) -> [String] {
        var seen: Set<String> = []
        var result: [String] = []
        for name in names {
            guard result.count < limit else {
                break
            }
            let trimmed = name
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "#＃"))
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                continue
            }
            let key = trimmed.lowercased()
            guard seen.insert(key).inserted else {
                continue
            }
            result.append(String(trimmed.prefix(40)))
        }
        return result
    }
}

private struct GoodsSeriesSuggestionPayload: Encodable, Sendable {
    var images: [GoodsSeriesSuggestionImagePayload]
    var groupName: String?
    var memberName: String?
    var goodsTypeName: String?
    var existingCandidateNames: [String]
}

private struct GoodsSeriesSuggestionImagePayload: Encodable, Sendable {
    var base64: String?
    var contentType: String?
    var url: String?

    init?(source: GoodsSeriesSuggestionImage) {
        if let data = source.data, !data.isEmpty {
            self.base64 = data.base64EncodedString()
            self.contentType = source.contentType?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                ? source.contentType
                : "image/jpeg"
            self.url = nil
            return
        }
        if let imageURL = source.imageURL {
            self.base64 = nil
            self.contentType = nil
            self.url = imageURL.absoluteString
            return
        }
        return nil
    }
}

private struct GoodsSeriesSuggestionResponse: Decodable, Sendable {
    struct Candidate: Decodable, Sendable {
        var name: String?
    }

    var suggestions: [String]?
    var candidates: [Candidate]?

    func normalizedSuggestionNames(limit: Int) -> [String] {
        let names = (suggestions ?? []) + (candidates ?? []).compactMap(\.name)
        var seen: Set<String> = []
        var result: [String] = []
        for name in names {
            guard result.count < limit else {
                break
            }
            let trimmed = name
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "#＃"))
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                continue
            }
            let key = trimmed.lowercased()
            guard seen.insert(key).inserted else {
                continue
            }
            result.append(String(trimmed.prefix(40)))
        }
        return result
    }
}
