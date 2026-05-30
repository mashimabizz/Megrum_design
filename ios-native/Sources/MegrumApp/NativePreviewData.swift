import Foundation
import MegrumCore

enum NativePreviewData {
    static let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    static let partnerID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
    static let groupID = UUID(uuidString: "00000000-0000-0000-0000-000000000011")!
    static let memberID = UUID(uuidString: "00000000-0000-0000-0000-000000000012")!
    static let secondGroupID = UUID(uuidString: "00000000-0000-0000-0000-000000000013")!
    static let secondMemberID = UUID(uuidString: "00000000-0000-0000-0000-000000000014")!
    static let cardGoodsTypeID = UUID(uuidString: "00000000-0000-0000-0000-000000000021")!
    static let photoGoodsTypeID = UUID(uuidString: "00000000-0000-0000-0000-000000000022")!

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

    static let goodsTypes = [
        GoodsType(id: cardGoodsTypeID, name: "トレカ", category: "card", displayOrder: 1),
        GoodsType(id: photoGoodsTypeID, name: "生写真", category: "photo", displayOrder: 2),
        GoodsType(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000023")!,
            name: "アクスタ",
            category: "figure",
            displayOrder: 3
        )
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

    static let blockedUsers = [
        BlockedUser(
            userID: UUID(uuidString: "00000000-0000-0000-0000-000000000071")!,
            handle: "blocked_sample",
            displayName: "ブロック中ユーザー",
            blockedAt: Date(timeIntervalSince1970: 1_779_800_000)
        )
    ]

    static let notifications = [
        MegrumNotification(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000081")!,
            kind: .proposalReceived,
            title: "新しい打診が届いています",
            body: "ランダムトレカAについて交換の打診があります。",
            linkPath: "/proposals/preview",
            createdAt: Date(timeIntervalSinceNow: -1_080)
        ),
        MegrumNotification(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000082")!,
            kind: .meguriBoardReply,
            title: "掲示板に返信がありました",
            body: "物販列は今だと20分くらいです。",
            linkPath: "/meguri-board-thread?id=preview-board-thread-1",
            createdAt: Date(timeIntervalSinceNow: -420)
        ),
        MegrumNotification(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000083")!,
            kind: .tradeCompleted,
            title: "取引が完了しました",
            body: "評価を入力できます。",
            linkPath: "/trades/preview",
            readAt: Date(timeIntervalSinceNow: -3_600),
            createdAt: Date(timeIntervalSinceNow: -7_200)
        )
    ]

    static let inventory: [GoodsItem] = [
        GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000201")!,
            ownerID: viewerID,
            groupID: groupID,
            memberID: memberID,
            goodsTypeID: cardGoodsTypeID,
            title: "ランダムトレカ A",
            tags: [tags[0], tags[2]],
            quantity: 2
        ),
        GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000202")!,
            ownerID: viewerID,
            groupID: groupID,
            memberID: memberID,
            goodsTypeID: photoGoodsTypeID,
            title: "会場限定フォト",
            tags: [tags[1]],
            quantity: 1
        ),
        GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000203")!,
            ownerID: partnerID,
            groupID: groupID,
            memberID: memberID,
            goodsTypeID: cardGoodsTypeID,
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
            goodsTypeID: photoGoodsTypeID,
            title: "会場限定フォト",
            tags: [tags[1]]
        ),
        WishItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000302")!,
            ownerID: viewerID,
            groupID: groupID,
            memberID: memberID,
            goodsTypeID: cardGoodsTypeID,
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

    static let messages: [UUID: [TradeMessage]] = [
        proposals[0].id: [
            TradeMessage(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000451")!,
                proposalID: proposals[0].id,
                senderID: viewerID,
                messageType: .text,
                body: "こちらの内容でお願いできますか？"
            ),
            TradeMessage(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000452")!,
                proposalID: proposals[0].id,
                senderID: partnerID,
                messageType: .text,
                body: "大丈夫です。よろしくお願いします。"
            )
        ],
        proposals[1].id: [
            TradeMessage(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000453")!,
                proposalID: proposals[1].id,
                senderID: partnerID,
                messageType: .text,
                body: "合流したらここで連絡します。"
            )
        ]
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
            audience: .samePrefecture,
            prefecture: "東京都"
        )
    ]

    static let boardReplies: [UUID: [BoardReply]] = [
        UUID(uuidString: "00000000-0000-0000-0000-000000000601")!: [
            BoardReply(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000701")!,
                threadID: UUID(uuidString: "00000000-0000-0000-0000-000000000601")!,
                authorID: partnerID,
                body: "北口はまだ列が動いています。",
                createdAt: Date(timeIntervalSince1970: 1_780_170_000)
            ),
            BoardReply(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000702")!,
                threadID: UUID(uuidString: "00000000-0000-0000-0000-000000000601")!,
                authorID: viewerID,
                body: "ありがとう、広場側で待ちます。",
                createdAt: Date(timeIntervalSince1970: 1_780_170_180)
            )
        ],
        UUID(uuidString: "00000000-0000-0000-0000-000000000602")!: [
            BoardReply(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000703")!,
                threadID: UUID(uuidString: "00000000-0000-0000-0000-000000000602")!,
                authorID: viewerID,
                body: "会場横の照明がある場所が見つけやすいです。",
                createdAt: Date(timeIntervalSince1970: 1_780_170_360)
            )
        ]
    ]
}
