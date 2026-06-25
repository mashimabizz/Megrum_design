import Foundation

extension SupabaseListingClient {
    func listingQueryItems(userID: UUID, publicOnly: Bool) -> [URLQueryItem] {
        [
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString.lowercased())"),
            URLQueryItem(name: "status", value: publicOnly ? "eq.active" : "in.(active,paused,matched)"),
            URLQueryItem(name: "order", value: "updated_at.desc")
        ]
    }

    func optionQueryItems(listingIDs: [UUID]) -> [URLQueryItem] {
        let ids = listingIDs
            .map { $0.uuidString.lowercased() }
            .joined(separator: ",")
        return [
            URLQueryItem(name: "listing_id", value: "in.(\(ids))"),
            URLQueryItem(name: "order", value: "position.asc,created_at.asc")
        ]
    }

    func ownedListingQueryItems(userID: UUID, listingID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "id", value: "eq.\(listingID.uuidString.lowercased())"),
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString.lowercased())")
        ]
    }

    func listingWishOptionQueryItems(listingID: UUID, optionID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "id", value: "eq.\(optionID.uuidString.lowercased())"),
            URLQueryItem(name: "listing_id", value: "eq.\(listingID.uuidString.lowercased())")
        ]
    }

    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }
}
