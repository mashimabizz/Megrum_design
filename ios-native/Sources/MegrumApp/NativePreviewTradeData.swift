import Foundation
import MegrumCore

extension NativePreviewData {
    static let listings: [IndividualListing] = {
        let listingID = UUID(uuidString: "00000000-0000-0000-0000-000000000351")!
        return [
            IndividualListing(
                id: listingID,
                ownerID: viewerID,
                haves: [
                    ListingItemQuantity(itemID: inventory[0].id, quantity: 1),
                    ListingItemQuantity(itemID: inventory[1].id, quantity: 1)
                ],
                haveLogic: .one,
                haveGroupID: groupID,
                haveGoodsTypeID: cardGoodsTypeID,
                status: .active,
                note: """
                会場周辺で交換できる方を探しています。
                交換手段: 現地交換・郵送OK / 都道府県: 東京都 / 場所メモ: 東京ドーム周辺 / 日程: 相談して決める / 送料: 要相談 / 発送目安: 2〜4日以内 / 条件外打診: 可
                """,
                options: [
                    IndividualListingWishOption(
                        id: UUID(uuidString: "00000000-0000-0000-0000-000000000352")!,
                        listingID: listingID,
                        position: 1,
                        wishes: [
                            ListingItemQuantity(itemID: inventory[2].id, quantity: 1),
                            ListingItemQuantity(itemID: wishes[1].id, quantity: 1)
                        ],
                        logic: .one,
                        exchangeType: .any,
                        wishGroupID: secondGroupID,
                        wishGoodsTypeID: cardGoodsTypeID
                    )
                ],
                createdAt: Date(timeIntervalSinceNow: -3_600),
                updatedAt: Date(timeIntervalSinceNow: -1_800)
            )
        ]
    }()

    static let publicListings: [IndividualListing] = {
        let listingID = UUID(uuidString: "00000000-0000-0000-0000-000000000361")!
        return [
            IndividualListing(
                id: listingID,
                ownerID: partnerID,
                haves: [
                    ListingItemQuantity(itemID: inventory[2].id, quantity: 1),
                    ListingItemQuantity(itemID: inventory[3].id, quantity: 1)
                ],
                haveLogic: .one,
                haveGroupID: secondGroupID,
                haveGoodsTypeID: cardGoodsTypeID,
                status: .active,
                note: """
                カリナ春ver.を探しています。
                交換手段: 現地交換 / 都道府県: 大阪府 / 場所メモ: 会場周辺 / 日程: 相談して決める / 条件外打診: 不可
                """,
                options: [
                    IndividualListingWishOption(
                        id: UUID(uuidString: "00000000-0000-0000-0000-000000000362")!,
                        listingID: listingID,
                        position: 1,
                        wishes: [
                            ListingItemQuantity(itemID: inventory[0].id, quantity: 1),
                            ListingItemQuantity(itemID: inventory[1].id, quantity: 1)
                        ],
                        logic: .one,
                        exchangeType: .any,
                        wishGroupID: groupID,
                        wishGoodsTypeID: cardGoodsTypeID
                    ),
                    IndividualListingWishOption(
                        id: UUID(uuidString: "00000000-0000-0000-0000-000000000363")!,
                        listingID: listingID,
                        position: 2,
                        wishes: [],
                        logic: .one,
                        exchangeType: .any,
                        wishGroupID: groupID,
                        wishGoodsTypeID: cardGoodsTypeID
                    ),
                    IndividualListingWishOption(
                        id: UUID(uuidString: "00000000-0000-0000-0000-000000000364")!,
                        listingID: listingID,
                        position: 3,
                        wishes: [],
                        logic: .one,
                        exchangeType: .any,
                        isCashOffer: true,
                        cashAmount: 1_500
                    )
                ],
                createdAt: Date(timeIntervalSinceNow: -2_400),
                updatedAt: Date(timeIntervalSinceNow: -1_200)
            )
        ]
    }()

    static let proposals: [TradeProposal] = [
        TradeProposal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000401")!,
            senderID: viewerID,
            receiverID: partnerID,
            status: .sent,
            exchangeMethod: .both,
            senderGoodsIDs: [inventory[0].id],
            receiverGoodsIDs: [inventory[2].id],
            conditionTags: ["同日発送", "終演後OK"],
            agreedBySender: true,
            createdAt: Date(timeIntervalSinceNow: -3_600),
            meetupCandidates: previewMeetupCandidates
        ),
        TradeProposal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000402")!,
            senderID: partnerID,
            receiverID: viewerID,
            status: .agreed,
            exchangeMethod: .mail,
            senderGoodsIDs: [inventory[2].id],
            receiverGoodsIDs: [inventory[1].id],
            conditionTags: ["会場付近"],
            cashOffer: true,
            cashAmount: 1_100,
            agreedBySender: true,
            agreedByReceiver: true,
            createdAt: Date(timeIntervalSinceNow: -5_400),
            meetupCandidates: Array(previewMeetupCandidates.prefix(1)),
            senderMailingAddress: TradeMailingAddressSnapshot(
                recipientName: "はる",
                postalCode: "5300001",
                prefecture: "大阪府",
                city: "大阪市北区",
                line1: "梅田1-1",
                line2: "Megrumマンション101",
                phoneNumber: "09012345678"
            ),
            receiverMailingAddress: TradeMailingAddressSnapshot(
                recipientName: "みちりおん",
                postalCode: "1000001",
                prefecture: "東京都",
                city: "千代田区",
                line1: "千代田1-1",
                line2: "Megrumビル",
                phoneNumber: "0312345678"
            ),
            senderPaymentSettings: TradePaymentSettingsSnapshot(
                bankName: "みずほ銀行",
                bankBranchName: "渋谷支店",
                bankAccountType: "普通",
                bankAccountNumber: "1234567",
                bankAccountHolder: "ハル"
            ),
            receiverPaymentSettings: TradePaymentSettingsSnapshot(
                bankName: "三井住友銀行",
                bankBranchName: "丸の内支店",
                bankAccountType: "普通",
                bankAccountNumber: "7654321",
                bankAccountHolder: "ミチリオン"
            )
        ),
        TradeProposal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000403")!,
            senderID: partnerID,
            receiverID: viewerID,
            status: .sent,
            exchangeMethod: .both,
            senderGoodsIDs: [inventory[2].id],
            receiverGoodsIDs: [inventory[0].id],
            conditionTags: ["即日発送"],
            agreedBySender: true,
            createdAt: Date(timeIntervalSinceNow: -7_200),
            meetupCandidates: previewMeetupCandidates
        ),
        TradeProposal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000404")!,
            senderID: partnerID,
            receiverID: viewerID,
            status: .negotiating,
            exchangeMethod: .hand,
            senderGoodsIDs: [inventory[2].id, inventory[3].id, inventory[4].id],
            receiverGoodsIDs: [inventory[1].id, inventory[0].id],
            conditionTags: ["返信確認中", "要対応"],
            agreedBySender: true,
            createdAt: Date(timeIntervalSinceNow: -180),
            meetupCandidates: previewMeetupCandidates
        ),
        TradeProposal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000405")!,
            senderID: partnerID,
            receiverID: viewerID,
            status: .agreementOneSide,
            exchangeMethod: .hand,
            senderGoodsIDs: [inventory[2].id],
            receiverGoodsIDs: [inventory[0].id],
            conditionTags: ["合意待ち", "要対応"],
            agreedBySender: true,
            createdAt: Date(timeIntervalSinceNow: -720),
            meetupCandidates: previewMeetupCandidates
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

    static var schedules: [PersonalSchedule] {
        [
            PersonalSchedule(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000471")!,
                userID: viewerID,
                title: "物販列",
                placeName: "横浜アリーナ 北口",
                startAt: previewDate(hour: 10),
                endAt: previewDate(hour: 12)
            ),
            PersonalSchedule(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000472")!,
                userID: viewerID,
                title: "友人と合流",
                placeName: "駅前広場",
                startAt: previewDate(hour: 14),
                endAt: previewDate(hour: 15, minute: 30)
            ),
            PersonalSchedule(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000473")!,
                userID: partnerID,
                title: "開演前準備",
                placeName: "会場ロビー",
                startAt: previewDate(hour: 11, minute: 30),
                endAt: previewDate(hour: 12, minute: 30)
            ),
            PersonalSchedule(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000474")!,
                userID: partnerID,
                title: "交換待ち合わせ",
                placeName: "東ゲート付近",
                startAt: previewDate(dayOffset: 1, hour: 13),
                endAt: previewDate(dayOffset: 1, hour: 13, minute: 45)
            )
        ]
    }
}
