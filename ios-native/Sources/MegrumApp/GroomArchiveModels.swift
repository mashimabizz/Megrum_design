import Foundation
import MegrumCore

public enum GroomArchiveOrdering {
    public static func sorted(_ grooms: [GroomPost]) -> [GroomPost] {
        grooms.sorted { lhs, rhs in
            if lhs.createdAt != rhs.createdAt {
                return lhs.createdAt > rhs.createdAt
            }
            return lhs.id.uuidString < rhs.id.uuidString
        }
    }
}
