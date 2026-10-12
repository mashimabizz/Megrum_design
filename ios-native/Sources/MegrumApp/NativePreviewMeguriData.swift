import Foundation
import MegrumCore

extension NativePreviewData {
    static let meguriMessages: [MeguriMessage] = [
        MeguriMessage(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000801")!,
            senderID: partnerID,
            recipientID: viewerID,
            sourceGroomReplyID: UUID(uuidString: "00000000-0000-0000-0000-000000000704")!,
            sourceGroomPostID: UUID(uuidString: "00000000-0000-0000-0000-000000000502")!,
            sourceGroomOwnerID: viewerID,
            sourceGroomImageURL: testGoodsImageURL("twice_momo_1"),
            messageType: .text,
            body: "グルーム見ました。会場付近ですか？",
            senderDisplayName: "まさき",
            senderHandle: "masaki"
        ),
        MeguriMessage(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000802")!,
            senderID: partnerID,
            recipientID: viewerID,
            sourceGroomReplyID: UUID(uuidString: "00000000-0000-0000-0000-000000000705")!,
            sourceGroomPostID: UUID(uuidString: "00000000-0000-0000-0000-000000000503")!,
            sourceGroomOwnerID: viewerID,
            sourceGroomImageURL: testGoodsImageURL("twice_dahyun_1"),
            messageType: .text,
            body: "次の現場でも見たいです",
            createdAt: Date(timeIntervalSince1970: 1_779_912_180),
            senderDisplayName: "まさき",
            senderHandle: "masaki"
        )
    ]

    static let grooms: [GroomPost] = [
        GroomPost(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000501")!,
            authorID: partnerID,
            imageURL: testGoodsImageURL("aespa_ningning")!,
            latitude: 35.681236,
            longitude: 139.767125,
            groupID: groupID,
            characterID: memberID,
            seriesName: "2026 LIVE",
            createdAt: Date(timeIntervalSince1970: 1_780_169_880)
        ),
        GroomPost(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000502")!,
            authorID: viewerID,
            imageURL: testGoodsImageURL("twice_momo_1")!,
            latitude: 35.682236,
            longitude: 139.768425,
            groupID: secondGroupID,
            characterID: secondMemberID,
            seriesName: "会場限定",
            createdAt: Date(timeIntervalSince1970: 1_780_090_000)
        ),
        GroomPost(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000503")!,
            authorID: viewerID,
            imageURL: testGoodsImageURL("twice_dahyun_1")!,
            latitude: 35.679936,
            longitude: 139.765825,
            groupID: secondGroupID,
            characterID: secondMemberID,
            seriesName: "会場限定",
            createdAt: Date(timeIntervalSince1970: 1_779_910_000)
        )
    ]

    static let groomReactions: [UUID: [GroomReaction]] = [
        UUID(uuidString: "00000000-0000-0000-0000-000000000502")!: [
            GroomReaction(
                groomPostID: UUID(uuidString: "00000000-0000-0000-0000-000000000502")!,
                userID: partnerID,
                createdAt: Date(timeIntervalSince1970: 1_780_091_200)
            )
        ],
        UUID(uuidString: "00000000-0000-0000-0000-000000000503")!: [
            GroomReaction(
                groomPostID: UUID(uuidString: "00000000-0000-0000-0000-000000000503")!,
                userID: partnerID,
                createdAt: Date(timeIntervalSince1970: 1_779_912_000)
            )
        ]
    ]

    static let groomReplies: [UUID: [GroomReply]] = [
        UUID(uuidString: "00000000-0000-0000-0000-000000000502")!: [
            GroomReply(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000704")!,
                groomPostID: UUID(uuidString: "00000000-0000-0000-0000-000000000502")!,
                senderID: partnerID,
                recipientID: viewerID,
                body: "会場の雰囲気いいですね！",
                groomImageURL: testGoodsImageURL("twice_momo_1"),
                createdAt: Date(timeIntervalSince1970: 1_780_091_260)
            )
        ],
        UUID(uuidString: "00000000-0000-0000-0000-000000000503")!: [
            GroomReply(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000705")!,
                groomPostID: UUID(uuidString: "00000000-0000-0000-0000-000000000503")!,
                senderID: partnerID,
                recipientID: viewerID,
                body: "次の現場でも見たいです",
                groomImageURL: testGoodsImageURL("twice_dahyun_1"),
                createdAt: Date(timeIntervalSince1970: 1_779_912_120)
            )
        ]
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
            prefecture: "東京都",
            groupID: groupID,
            characterID: memberID,
            seriesName: "2026 LIVE",
            // 返信（1_780_170_000〜）より前に本文が来るよう固定（未指定だと .now になり日付が逆行して見える）。
            createdAt: Date(timeIntervalSince1970: 1_780_169_700),
            latestActivityAt: Date(timeIntervalSince1970: 1_780_170_180)
        ),
        BoardThread(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000603")!,
            authorID: partnerID,
            title: "開演前ラントレどこでやる？",
            body: "東口の広場に人が集まり始めています。",
            audience: .nearby3km,
            latitude: 35.683200,
            longitude: 139.766000,
            prefecture: "東京都",
            imageURLs: [testGoodsImageURL("twice_momo_1")].compactMap { $0 },
            groupID: groupID,
            characterID: memberID,
            seriesName: "トレカ第3弾",
            createdAt: Date(timeIntervalSince1970: 1_780_168_900),
            latestActivityAt: Date(timeIntervalSince1970: 1_780_169_400)
        ),
        BoardThread(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000604")!,
            authorID: partnerID,
            title: "隣駅カフェでゆる交換",
            body: "終演後に隣駅のカフェでのんびり交換しませんか。",
            audience: .nearby3km,
            latitude: 35.729000,
            longitude: 139.710900,
            prefecture: "東京都",
            groupID: secondGroupID,
            characterID: secondMemberID,
            seriesName: "2026 LIVE",
            createdAt: Date(timeIntervalSince1970: 1_780_168_500),
            latestActivityAt: Date(timeIntervalSince1970: 1_780_169_100)
        ),
        BoardThread(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000602")!,
            authorID: viewerID,
            title: "終演後の交換場所",
            body: "駅側より会場横の広場が落ち着いています。",
            audience: .samePrefecture,
            prefecture: "東京都",
            groupID: secondGroupID,
            characterID: secondMemberID,
            seriesName: "会場限定",
            createdAt: Date(timeIntervalSince1970: 1_780_169_800),
            latestActivityAt: Date(timeIntervalSince1970: 1_780_170_360)
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
