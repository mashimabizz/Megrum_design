import Foundation
import MegrumCore

enum NativePreviewData {
    static let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    static let partnerID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
    static let groupID = UUID(uuidString: "00000000-0000-0000-0000-000000000011")!
    static let memberID = UUID(uuidString: "00000000-0000-0000-0000-000000000012")!
    static let secondGroupID = UUID(uuidString: "00000000-0000-0000-0000-000000000013")!
    static let secondMemberID = UUID(uuidString: "00000000-0000-0000-0000-000000000014")!
    static let thirdGroupID = UUID(uuidString: "00000000-0000-0000-0000-000000000015")!
    static let thirdMemberID = UUID(uuidString: "00000000-0000-0000-0000-000000000016")!
    static let cardGoodsTypeID = UUID(uuidString: "00000000-0000-0000-0000-000000000021")!
    static let photoGoodsTypeID = UUID(uuidString: "00000000-0000-0000-0000-000000000022")!
    static let acrylicStandGoodsTypeID = UUID(uuidString: "00000000-0000-0000-0000-000000000023")!
    static let kpopMaleGenreID = UUID(uuidString: "00000000-0000-0000-0000-000000000101")!
    static let kpopFemaleGenreID = UUID(uuidString: "00000000-0000-0000-0000-000000000102")!

    private static func previewDate(dayOffset: Int = 0, hour: Int, minute: Int = 0) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let day = calendar.date(byAdding: .day, value: dayOffset, to: today) ?? today
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
    }

    private static func testGoodsImageURL(_ name: String, fileExtension ext: String = "png") -> URL? {
        Bundle.module.url(
            forResource: name,
            withExtension: ext,
            subdirectory: "TestGoodsImages"
        ) ?? Bundle.module.url(forResource: name, withExtension: ext)
    }

    static let previewMeetupCandidates = [
        ProposalMeetupInput(
            startAt: previewDate(hour: 17),
            endAt: previewDate(hour: 18),
            placeName: "横浜アリーナ",
            latitude: 35.5122,
            longitude: 139.6171
        ),
        ProposalMeetupInput(
            startAt: previewDate(hour: 19),
            endAt: previewDate(hour: 20),
            placeName: "新横浜駅",
            latitude: 35.5075,
            longitude: 139.6175
        )
    ]

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
        GoodsTag(id: UUID(uuidString: "00000000-0000-0000-0000-000000000101")!, name: "aespa"),
        GoodsTag(id: UUID(uuidString: "00000000-0000-0000-0000-000000000102")!, name: "会場限定"),
        GoodsTag(id: UUID(uuidString: "00000000-0000-0000-0000-000000000103")!, name: "トレカ"),
        GoodsTag(id: UUID(uuidString: "00000000-0000-0000-0000-000000000104")!, name: "TWICE"),
        GoodsTag(id: UUID(uuidString: "00000000-0000-0000-0000-000000000105")!, name: "BTS"),
        GoodsTag(id: UUID(uuidString: "00000000-0000-0000-0000-000000000106")!, name: "SEVENTEEN"),
        GoodsTag(id: UUID(uuidString: "00000000-0000-0000-0000-000000000107")!, name: "2026 LIVE"),
        GoodsTag(id: UUID(uuidString: "00000000-0000-0000-0000-000000000108")!, name: "缶バッジ")
    ]

    static let oshiGroups = [
        OshiGroup(
            id: groupID,
            name: "aespa",
            aliases: ["エスパ"],
            kind: .group,
            genreID: kpopFemaleGenreID,
            genreName: "K-POP女性",
            displayOrder: 1
        ),
        OshiGroup(
            id: secondGroupID,
            name: "LUMENA",
            aliases: [],
            kind: .group,
            genreID: kpopFemaleGenreID,
            genreName: "K-POP女性",
            displayOrder: 2
        ),
        OshiGroup(
            id: thirdGroupID,
            name: "NCT",
            aliases: [],
            kind: .group,
            genreID: kpopMaleGenreID,
            genreName: "K-POP男性",
            displayOrder: 3
        )
    ]

    static let oshiGenres = [
        OshiGenre(id: kpopMaleGenreID, name: "K-POP男性", displayOrder: 1),
        OshiGenre(id: kpopFemaleGenreID, name: "K-POP女性", displayOrder: 2),
        OshiGenre(id: UUID(uuidString: "00000000-0000-0000-0000-000000000103")!, name: "国内男性", displayOrder: 3),
        OshiGenre(id: UUID(uuidString: "00000000-0000-0000-0000-000000000104")!, name: "国内女性", displayOrder: 4),
        OshiGenre(id: UUID(uuidString: "00000000-0000-0000-0000-000000000105")!, name: "アニメ・マンガ", displayOrder: 5)
    ]

    static let oshiCharacters = [
        OshiCharacter(id: memberID, groupID: groupID, name: "カリナ", aliases: ["KARINA"], displayOrder: 1),
        OshiCharacter(id: secondMemberID, groupID: secondGroupID, name: "スア", aliases: ["SUA"], displayOrder: 1),
        OshiCharacter(id: thirdMemberID, groupID: thirdGroupID, name: "ジョンウ", aliases: ["JUNGWOO"], displayOrder: 1)
    ]

    static let goodsTypes = [
        GoodsType(id: cardGoodsTypeID, name: "トレカ", category: "card", displayOrder: 1),
        GoodsType(id: photoGoodsTypeID, name: "生写真", category: "photo", displayOrder: 2),
        GoodsType(
            id: acrylicStandGoodsTypeID,
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

    static let userEvaluations = [
        UserEvaluation(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000091")!,
            raterID: UUID(uuidString: "00000000-0000-0000-0000-000000000092")!,
            raterHandle: "trade_mina",
            raterDisplayName: "mina",
            stars: 5,
            comment: "返信が早く、交換物も丁寧に保管されていました。",
            createdAt: Date(timeIntervalSinceNow: -86_400 * 2)
        ),
        UserEvaluation(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000093")!,
            raterID: UUID(uuidString: "00000000-0000-0000-0000-000000000094")!,
            raterHandle: "sana_goods",
            raterDisplayName: "sana",
            stars: 4,
            comment: "現地での受け渡しがスムーズでした。",
            createdAt: Date(timeIntervalSinceNow: -86_400 * 14)
        )
    ]

    static let inventory: [GoodsItem] = [
        GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000201")!,
            ownerID: viewerID,
            groupID: groupID,
            memberID: memberID,
            goodsTypeID: cardGoodsTypeID,
            title: "モモ 2026 LIVE",
            imageURL: testGoodsImageURL("twice_momo_2"),
            tags: [tags[3], tags[6], tags[2]],
            quantity: 1,
            exchangeMethod: .both,
            ownerPrefecture: "東京都"
        ),
        GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000202")!,
            ownerID: viewerID,
            groupID: thirdGroupID,
            memberID: thirdMemberID,
            goodsTypeID: cardGoodsTypeID,
            title: "ジョングク トレカ",
            imageURL: testGoodsImageURL("bts_jungkook"),
            tags: [tags[4], tags[2]],
            quantity: 1,
            exchangeMethod: .mail,
            ownerPrefecture: "東京都"
        ),
        GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000203")!,
            ownerID: partnerID,
            status: .traded,
            groupID: secondGroupID,
            memberID: secondMemberID,
            goodsTypeID: cardGoodsTypeID,
            title: "サナ 2026 LIVE",
            imageURL: testGoodsImageURL("twice_sana_1"),
            tags: [tags[3], tags[6], tags[2]],
            quantity: 1,
            exchangeMethod: .hand,
            ownerPrefecture: "福岡県"
        ),
        GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000204")!,
            ownerID: partnerID,
            groupID: groupID,
            goodsTypeID: acrylicStandGoodsTypeID,
            title: "ニンニン 制服",
            imageURL: testGoodsImageURL("aespa_ningning"),
            tags: [tags[0], tags[2]],
            quantity: 1,
            exchangeMethod: .both,
            ownerPrefecture: "東京都"
        ),
        GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000205")!,
            ownerID: partnerID,
            groupID: secondGroupID,
            memberID: secondMemberID,
            goodsTypeID: cardGoodsTypeID,
            title: "モモ ファンミ",
            imageURL: testGoodsImageURL("twice_momo_1"),
            tags: [tags[3], tags[1], tags[2]],
            quantity: 1,
            exchangeMethod: .hand,
            ownerPrefecture: "大阪府"
        ),
        GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000206")!,
            ownerID: partnerID,
            groupID: groupID,
            goodsTypeID: cardGoodsTypeID,
            title: "ダヒョン 缶バッジ",
            imageURL: testGoodsImageURL("twice_dahyun_1"),
            tags: [tags[3], tags[7]],
            quantity: 1,
            exchangeMethod: .mail,
            ownerPrefecture: "東京都"
        ),
        GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000207")!,
            ownerID: partnerID,
            groupID: thirdGroupID,
            memberID: thirdMemberID,
            goodsTypeID: cardGoodsTypeID,
            title: "V トレカ",
            imageURL: testGoodsImageURL("bts_v"),
            tags: [tags[4], tags[2]],
            quantity: 1,
            exchangeMethod: .both,
            ownerPrefecture: "兵庫県"
        ),
        GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000208")!,
            ownerID: partnerID,
            groupID: thirdGroupID,
            goodsTypeID: cardGoodsTypeID,
            title: "Joshua トレカ",
            imageURL: testGoodsImageURL("svt_joshua", fileExtension: "jpg"),
            tags: [tags[5], tags[2]],
            quantity: 1,
            exchangeMethod: .hand,
            ownerPrefecture: "愛知県"
        ),
        GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000209")!,
            ownerID: partnerID,
            groupID: groupID,
            goodsTypeID: cardGoodsTypeID,
            title: "S.Coups トレカ",
            imageURL: testGoodsImageURL("svt_scoups", fileExtension: "jpg"),
            tags: [tags[5], tags[2]],
            quantity: 1,
            exchangeMethod: .mail,
            ownerPrefecture: "神奈川県"
        ),
        GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000210")!,
            ownerID: viewerID,
            groupID: groupID,
            goodsTypeID: acrylicStandGoodsTypeID,
            title: "TWICE ペンライト",
            imageURL: testGoodsImageURL("twice_penlight"),
            tags: [tags[3], tags[6]],
            quantity: 1,
            exchangeMethod: .both,
            ownerPrefecture: "東京都"
        ),
        GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000211")!,
            ownerID: viewerID,
            groupID: thirdGroupID,
            memberID: thirdMemberID,
            goodsTypeID: cardGoodsTypeID,
            title: "ジミン トレカ",
            imageURL: testGoodsImageURL("bts_jimin"),
            tags: [tags[4], tags[2]],
            quantity: 1,
            exchangeMethod: .mail,
            ownerPrefecture: "東京都"
        ),
        GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000212")!,
            ownerID: viewerID,
            groupID: groupID,
            goodsTypeID: cardGoodsTypeID,
            title: "Mingyu トレカ",
            imageURL: testGoodsImageURL("svt_mingyu", fileExtension: "jpg"),
            tags: [tags[5], tags[2]],
            quantity: 1,
            exchangeMethod: .hand,
            ownerPrefecture: "東京都"
        ),
        GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000213")!,
            ownerID: viewerID,
            groupID: groupID,
            goodsTypeID: acrylicStandGoodsTypeID,
            title: "ニンニン トレカ",
            imageURL: testGoodsImageURL("aespa_ningning_2"),
            tags: [tags[0], tags[2]],
            quantity: 1,
            exchangeMethod: .both,
            ownerPrefecture: "東京都"
        )
    ]

    static let wishes: [WishItem] = [
        WishItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000301")!,
            ownerID: viewerID,
            groupID: secondGroupID,
            memberID: secondMemberID,
            goodsTypeID: cardGoodsTypeID,
            title: "スア ラキドロ",
            imageURL: testGoodsImageURL("twice_sana_1"),
            tags: [tags[3], tags[6], tags[2]]
        ),
        WishItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000302")!,
            ownerID: viewerID,
            groupID: groupID,
            goodsTypeID: acrylicStandGoodsTypeID,
            title: "ニンニン 制服",
            imageURL: testGoodsImageURL("aespa_ningning"),
            tags: [tags[0], tags[2]]
        )
    ]

    static var homeMatchedItems: [GoodsItem] {
        partnerGoods + viewerGoods
    }

    static var homePossibleItems: [GoodsItem] {
        viewerGoods + partnerGoods
    }

    private static var partnerGoods: [GoodsItem] {
        inventory.filter { $0.ownerID == partnerID }
    }

    private static var viewerGoods: [GoodsItem] {
        inventory.filter { $0.ownerID == viewerID }
    }

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
                note: "会場周辺で交換できる方を探しています。",
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
                note: "カリナ春ver.を探しています。",
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
            exchangeMethod: .hand,
            senderGoodsIDs: [inventory[2].id],
            receiverGoodsIDs: [inventory[1].id],
            conditionTags: ["会場付近"],
            agreedBySender: true,
            agreedByReceiver: true,
            createdAt: Date(timeIntervalSinceNow: -5_400),
            meetupCandidates: Array(previewMeetupCandidates.prefix(1))
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
