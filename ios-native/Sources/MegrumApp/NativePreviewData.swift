import Foundation
import MegrumCore

enum NativePreviewData {
    static let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    static let partnerID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
    static let groupID = UUID(uuidString: "00000000-0000-0000-0000-000000000011")!
    static let memberID = UUID(uuidString: "00000000-0000-0000-0000-000000000012")!
    static let secondGroupID = UUID(uuidString: "00000000-0000-0000-0000-000000000013")!
    static let secondMemberID = UUID(uuidString: "00000000-0000-0000-0000-000000000014")!

    static let viewer = UserProfile(
        id: viewerID,
        handle: "michilion",
        displayName: "みちりおん",
        prefecture: "東京都"
    )

    static let partner = UserProfile(
        id: partnerID,
        handle: "michi1",
        displayName: "michi",
        prefecture: "東京都"
    )

    static let tags = [
        GoodsTag(id: UUID(uuidString: "00000000-0000-0000-0000-000000000101")!, name: "東京2026"),
        GoodsTag(id: UUID(uuidString: "00000000-0000-0000-0000-000000000102")!, name: "会場限定"),
        GoodsTag(id: UUID(uuidString: "00000000-0000-0000-0000-000000000103")!, name: "トレカ")
    ]

    static let oshiGroups = [
        OshiGroup(id: groupID, name: "TWICE", aliases: ["トゥワイス"], displayOrder: 1),
        OshiGroup(id: secondGroupID, name: "LE SSERAFIM", aliases: ["ルセラフィム"], displayOrder: 2)
    ]

    static let oshiCharacters = [
        OshiCharacter(id: memberID, groupID: groupID, name: "SANA", aliases: ["サナ"], displayOrder: 1),
        OshiCharacter(id: secondMemberID, groupID: secondGroupID, name: "SAKURA", aliases: ["サクラ"], displayOrder: 1)
    ]

    static let mailingAddress = MailingAddress(
        userID: viewerID,
        recipientName: "みちりおん",
        postalCode: "1000001",
        prefecture: "東京都",
        city: "千代田区",
        line1: "千代田1-1",
        line2: "Megrumビル",
        phoneNumber: "0312345678"
    )

    static let inventory: [GoodsItem] = [
        GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000201")!,
            ownerID: viewerID,
            groupID: groupID,
            memberID: memberID,
            title: "ランダムトレカ A",
            tags: [tags[0], tags[2]],
            quantity: 2
        ),
        GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000202")!,
            ownerID: viewerID,
            groupID: groupID,
            memberID: memberID,
            title: "会場限定フォト",
            tags: [tags[1]],
            quantity: 1
        ),
        GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000203")!,
            ownerID: partnerID,
            groupID: groupID,
            memberID: memberID,
            title: "ランダムトレカ B",
            tags: [tags[2]],
            quantity: 1
        )
    ]

    static let wishes: [WishItem] = [
        WishItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000301")!,
            ownerID: viewerID,
            groupID: groupID,
            memberID: memberID,
            title: "会場限定フォト",
            tags: [tags[1]]
        ),
        WishItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000302")!,
            ownerID: viewerID,
            groupID: groupID,
            memberID: memberID,
            title: "ランダムトレカ B",
            tags: [tags[2]]
        )
    ]

    static let proposals: [TradeProposal] = [
        TradeProposal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000401")!,
            senderID: viewerID,
            receiverID: partnerID,
            status: .sent,
            exchangeMethod: .both,
            senderGoodsIDs: [inventory[0].id],
            receiverGoodsIDs: [inventory[2].id],
            conditionTags: ["同日発送", "終演後OK"]
        ),
        TradeProposal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000402")!,
            senderID: partnerID,
            receiverID: viewerID,
            status: .agreed,
            exchangeMethod: .hand,
            senderGoodsIDs: [inventory[2].id],
            receiverGoodsIDs: [inventory[1].id],
            conditionTags: ["会場付近"]
        )
    ]

    static let grooms: [GroomPost] = [
        GroomPost(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000501")!,
            authorID: partnerID,
            imageURL: URL(string: "https://example.com/groom-a.jpg")!,
            latitude: 35.681236,
            longitude: 139.767125
        )
    ]

    static let threads: [BoardThread] = [
        BoardThread(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000601")!,
            authorID: partnerID,
            title: "物販列どのくらい？",
            body: "北口側はまだ動きがあります。整理券の確認を忘れずに。",
            audience: .nearby3km,
            latitude: 35.681236,
            longitude: 139.767125,
            prefecture: "東京都"
        ),
        BoardThread(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000602")!,
            authorID: viewerID,
            title: "終演後の交換場所",
            body: "駅側より会場横の広場が落ち着いています。",
            audience: .prefecture,
            prefecture: "東京都"
        )
    ]
}
