import Foundation

extension SupabaseActivityWindowClient {
    func validateCreateInput(_ input: SupabaseActivityWindowCreateInput) throws {
        try validateVenue(input.venue)
        guard input.startAt < input.endAt else {
            throw SupabaseActivityWindowClientError.invalidTimeRange
        }
        try validateRadius(input.radiusMeters)
        if let center = input.center {
            try validateCoordinate(center)
        }
        try validateEventName(input.eventName)
        try validateNote(input.note)
    }

    func validateVenue(_ venue: String) throws {
        let normalized = SupabaseTextNormalizer.trimmed(venue)
        guard !normalized.isEmpty, normalized.count <= 100 else {
            throw SupabaseActivityWindowClientError.invalidVenue
        }
    }

    func validateRadius(_ radiusMeters: Int) throws {
        guard (50...5_000).contains(radiusMeters) else {
            throw SupabaseActivityWindowClientError.invalidRadius
        }
    }

    func validateCoordinate(_ coordinate: SupabaseActivityWindowCoordinate) throws {
        guard (-90...90).contains(coordinate.latitude),
              (-180...180).contains(coordinate.longitude)
        else {
            throw SupabaseActivityWindowClientError.invalidCoordinate
        }
    }

    func validateEventName(_ eventName: String?) throws {
        guard SupabaseTextNormalizer.optional(eventName)?.count ?? 0 <= 100 else {
            throw SupabaseActivityWindowClientError.invalidEventName
        }
    }

    func validateNote(_ note: String?) throws {
        guard SupabaseTextNormalizer.optional(note)?.count ?? 0 <= 200 else {
            throw SupabaseActivityWindowClientError.invalidNote
        }
    }
}
