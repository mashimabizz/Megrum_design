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

    static func previewDate(dayOffset: Int = 0, hour: Int, minute: Int = 0) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let day = calendar.date(byAdding: .day, value: dayOffset, to: today) ?? today
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
    }

    static func testGoodsImageURL(_ name: String, fileExtension ext: String = "png") -> URL? {
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
        bio: "関西中心にライブ参戦しています。トレカと会場限定グッズの交換が多めです。",
        avatarURL: testGoodsImageURL("twice_dahyun_1"),
        prefecture: "大阪府",
        birthDate: ProfileBirthDateCodec.date(from: "2002-04-12"),
        age: 24,
        paymentMethods: [.bankTransfer, .paypay, .cashExchange, .other],
        paymentNote: "メルペイ相談可"
    )

    static let partner = UserProfile(
        id: partnerID,
        handle: "michi1",
        displayName: "michi",
        bio: "都内イベントでの交換が多いです。",
        gender: .female,
        prefecture: "東京都",
        age: 27,
        paymentMethods: [.paypay, .other],
        paymentNote: "差額相談可"
    )

    static func ownerPaymentMethods(for ownerID: UUID) -> [UserPaymentMethod] {
        ownerID == viewerID ? viewer.paymentMethods : partner.paymentMethods
    }

    static func ownerPaymentNote(for ownerID: UUID) -> String? {
        ownerID == viewerID ? viewer.paymentNote : partner.paymentNote
    }

    static let paymentSettings = UserPaymentSettings(
        userID: viewerID,
        methods: [.bankTransfer, .paypay, .cashExchange, .other],
        bankName: "みずほ銀行",
        bankBranchName: "渋谷支店",
        bankAccountType: "普通",
        bankAccountNumber: "1234567",
        bankAccountHolder: "ヤマダ ハナコ",
        otherNote: "メルペイ、楽天ペイも相談可"
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

}
