import Foundation

struct SupabaseHomeRelation: Decodable, Equatable, Sendable {
    var name: String?

    enum CodingKeys: CodingKey {
        case name
        case label
    }

    init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            self.name = try container.decodeIfPresent(String.self, forKey: .name)
                ?? container.decodeIfPresent(String.self, forKey: .label)
            return
        }
        if var unkeyed = try? decoder.unkeyedContainer() {
            self = try unkeyed.decodeIfPresent(SupabaseHomeRelation.self) ?? SupabaseHomeRelation(name: nil)
            return
        }
        self.name = nil
    }

    init(name: String?) {
        self.name = name
    }
}

struct SupabaseHomeFlexibleDouble: Decodable, Equatable, Sendable {
    var value: Double

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Double.self) {
            self.value = value
            return
        }
        let rawValue = try container.decode(String.self)
        guard let value = Double(rawValue) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected a Double-compatible value"
            )
        }
        self.value = value
    }
}

struct SupabaseHomeFlexibleString: Decodable, Equatable, Sendable {
    var value: String

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self.value = value
            return
        }
        if let value = try? container.decode(Int.self) {
            self.value = "\(value)"
            return
        }
        let value = try container.decode(Double.self)
        self.value = "\(value)"
    }
}

extension UUID {
    var lowercaseString: String {
        uuidString.lowercased()
    }
}

extension Array where Element == UUID {
    func uniqueLowercaseStrings() -> [String] {
        var seen = Set<UUID>()
        return filter { seen.insert($0).inserted }.map(\.lowercaseString)
    }
}
