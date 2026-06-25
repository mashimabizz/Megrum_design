import Foundation
import MegrumCore

struct SearchInitialCriteria: Equatable, Sendable {
    var query: String
    var groupID: UUID?
    var memberID: UUID?
    var goodsTypeID: UUID?
    var tagNames: [String]

    init(
        query: String = "",
        groupID: UUID? = nil,
        memberID: UUID? = nil,
        goodsTypeID: UUID? = nil,
        tagNames: [String] = []
    ) {
        self.query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        self.groupID = groupID
        self.memberID = memberID
        self.goodsTypeID = goodsTypeID
        self.tagNames = TagNameNormalizer.uniquePreservingOrder(tagNames, limit: 8)
    }

    var id: String {
        [
            query,
            groupID?.uuidString ?? "",
            memberID?.uuidString ?? "",
            goodsTypeID?.uuidString ?? "",
            tagNames.joined(separator: ",")
        ].joined(separator: "|")
    }
}
