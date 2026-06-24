import Foundation
import MegrumCore

extension NativePreviewData {
    static let meguriMessages: [MeguriMessage] = [
        MeguriMessage(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000801")!,
            senderID: partnerID,
            recipientID: viewerID,
            messageType: .text,
            body: "グルーム見ました。会場付近ですか？",
            senderDisplayName: "まさき",
            senderHandle: "masaki"
        )
    ]

    static let grooms: [GroomPost] = [
        GroomPost(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000501")!,
            authorID: partnerID,
            imageURL: URL(string: "https://example.com/groom-a.jpg")!,
            latitude: 35.681236,
            longitude: 139.767125,
            createdAt: Date(timeIntervalSince1970: 1_780_169_880)
        ),
        GroomPost(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000502")!,
            authorID: viewerID,
            imageURL: URL(string: "https://example.com/groom-archive-viewer-a.jpg")!,
            latitude: 35.682236,
            longitude: 139.768425,
            createdAt: Date(timeIntervalSince1970: 1_780_090_000)
        ),
        GroomPost(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000503")!,
            authorID: viewerID,
            imageURL: URL(string: "https://example.com/groom-archive-viewer-b.jpg")!,
            latitude: 35.679936,
            longitude: 139.765825,
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
                groomImageURL: URL(string: "https://example.com/groom-archive-viewer-a.jpg"),
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
                groomImageURL: URL(string: "https://example.com/groom-archive-viewer-b.jpg"),
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
