import Foundation
import MegrumCore

extension HomeMockGoods {
    func proposalGoodsItem(fallbackOwnerID: UUID = HomeDiscoveryFixtures.ownerID) -> GoodsItem {
        GoodsItem(
            id: id,
            ownerID: ownerID ?? fallbackOwnerID,
            groupID: groupID,
            memberID: memberID,
            goodsTypeID: goodsTypeID,
            groupName: groupName,
            memberName: memberName,
            goodsTypeName: goodsTypeName,
            title: title,
            imageURL: imageURL,
            tags: rawTagNames.map { GoodsTag(id: Self.stableTagID(for: $0), name: $0) },
            quantity: 1,
            ownerPrefecture: ownerPrefecture,
            ownerDisplayName: ownerDisplayName,
            ownerHandle: ownerHandle,
            ownerAvatarURL: ownerAvatarURL,
            ownerGender: ownerGender,
            ownerAge: ownerAge,
            ownerAverageStars: ownerAverageStars,
            ownerEvaluationCount: ownerEvaluationCount,
            ownerCompletedTradeCount: ownerCompletedTradeCount,
            ownerPaymentMethods: ownerPaymentMethods,
            ownerPaymentNote: ownerPaymentNote
        )
    }

    private static func stableTagID(for name: String) -> UUID {
        let hash = name
            .lowercased()
            .utf8
            .reduce(UInt64(14_695_981_039_346_656_037)) { partial, byte in
                (partial ^ UInt64(byte)).multipliedReportingOverflow(by: 1_099_511_628_211).partialValue
            }
        let tail = String(format: "%012llu", hash % 1_000_000_000_000)
        return UUID(uuidString: "00000000-0000-0000-0000-\(tail)")
            ?? UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    }
}
