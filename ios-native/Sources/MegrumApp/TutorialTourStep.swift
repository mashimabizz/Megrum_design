import Foundation

// MARK: - 章

/// ガイドツアーの章。進行UI（章内カウンタ・章スキップ）の単位。
enum TutorialChapter: Int, CaseIterable, Sendable {
    case welcome
    case home
    case tabMap
    case inventory
    case wish
    case listing
    case proposal
    case trades
    case meguri
    case completion

    var title: String {
        switch self {
        case .welcome: return "ようこそ"
        case .home: return "ホーム"
        case .tabMap: return "タブ"
        case .inventory: return "マイグッズ"
        case .wish: return "ほしいもの"
        case .listing: return "個別募集"
        case .proposal: return "打診"
        case .trades: return "やりとり"
        case .meguri: return "めぐり"
        case .completion: return "完了"
        }
    }
}

// MARK: - デモシーン識別子

/// 第4章 マイグッズ登録デモの各ビート。
enum TutorialGoodsDemoBeat: Int, CaseIterable, Sendable {
    case openEditor      // ＋をタップ→作成シートが開く
    case pickOshi        // TWICEをタップ
    case pickType        // トレカをタップ→次へ
    case pickPhotos      // 9枚グリッド写真を選択
    case bulkDetect      // AIが7枚を自動切り抜き（右下2枚は未検出）
    case manualCrop      // 指で枠をドラッグして手動切り抜き
    case assignMembers   // メンバー割当
    case assignSeries    // シリーズ＋Google Lensで#DIVE特定
    case saved           // 9件まとめて登録→一覧に載る
}

/// 第6章 個別募集作成デモの各ビート（オーナー指定の区切りそのまま）。
enum TutorialListingDemoBeat: Int, CaseIterable, Sendable {
    case openEditor      // 「募集を追加」をタップ
    case havesOverview   // 譲るもの（Step1全体）
    case havesCashTab    // 「定価で選ぶ」タブ
    case havesCashAmount // 金額指定
    case wishOverview    // 欲しいもの（Step2全体）
    case wishConditionTab// 「条件から選ぶ」
    case wishCashTab     // 「定価」
    case exchangeMethod  // 現地交換・郵送OK
    case exchangeLocal   // 現地交換の条件
    case exchangeMail    // 郵送交換の条件
    case exchangeOffSpec // 条件外の打診について
    case exchangeNote    // その他要望など
    case save            // 保存する
    case afterSave       // 終わった後の画面
}

/// 第7章 打診デモの各ビート（激求の例）。
enum TutorialProposalDemoBeat: Int, CaseIterable, Sendable {
    case openDetail      // 激求行をタップ→詳細シート
    case profile         // ユーザーネーム→相手プロフィール
    case exchangeTerms   // 交換条件を見る
    case listingDetail   // 個別募集の詳細
    case pickFromWanted  // 相手の希望から譲るものを選ぶ
    case pickFromMine    // 自分のグッズから譲るものを選ぶ
    case pickMore        // 追加で選ぶ（最低1つ）
    case confirm         // 交換内容を確認する
    case send            // 打診に進む
}

/// 第8章 やりとりデモ。
enum TutorialTradesDemoBeat: Int, CaseIterable, Sendable {
    case overview        // 一覧（サンプル打診カード）
    case chatFlow        // 取引チャットの一連の流れ
}

/// デモステージに出すシーン。
enum TutorialDemoScene: Equatable, Sendable {
    case goods(TutorialGoodsDemoBeat)
    case listing(TutorialListingDemoBeat)
    case proposal(TutorialProposalDemoBeat)
    case trades(TutorialTradesDemoBeat)
}

// MARK: - ビート

/// 1タップで進む最小単位。
struct TutorialBeat: Identifiable, Equatable, Sendable {
    enum Presentation: Equatable, Sendable {
        /// 全画面dim＋中央カード。
        case centerCard
        /// dim＋対象切り抜き＋隣接吹き出し。
        case spotlight(TutorialAnchorID)
        /// dimなし・下部バナー（画面全体を見せる）。
        case banner
        /// 下部タブバー帯だけ明るく残す（タブ移動の予告）。
        case tabBand
        /// デモステージ（実UI部品をスクリプト状態で描画＋指アイコン実演）。
        case demo(TutorialDemoScene)
        /// めぐり実画面上で、指が1km圏内をタップ→作成コールアウトを出す実演。
        case meguriTapDemo
    }

    let id: String
    let chapter: TutorialChapter
    let presentation: Presentation
    let targetTab: MegrumTab
    var requestedWishSection: WishCollectionSection?
    let title: String
    let body: String

    /// ホームのセクションへ自動スクロールするフォーカス。
    var homeFocusAnchor: TutorialAnchorID? {
        if case .spotlight(let anchor) = presentation {
            switch anchor {
            case .homeSectionUserTag, .homeSectionUser, .homeSectionHaves:
                return anchor
            default:
                return nil
            }
        }
        return nil
    }
}

// MARK: - 台本

enum TutorialScript {
    /// 全ビート（順序どおり）。id は「章番号-連番」で VisualQA からも指定できる。
    static let beats: [TutorialBeat] = welcomeBeats + homeBeats + tabMapBeats
        + inventoryBeats + wishBeats + listingBeats + proposalBeats
        + tradesBeats + meguriBeats + completionBeats

    static func beat(withID id: String) -> TutorialBeat? {
        beats.first { $0.id == id }
    }

    static func index(of beat: TutorialBeat) -> Int {
        beats.firstIndex(of: beat) ?? 0
    }

    /// 章内での位置（1-based）と章内総数。吹き出しの「マイグッズ 3/11」表示用。
    static func chapterProgress(of beat: TutorialBeat) -> (index: Int, count: Int) {
        let chapterBeats = beats.filter { $0.chapter == beat.chapter }
        let index = (chapterBeats.firstIndex(of: beat) ?? 0) + 1
        return (index, chapterBeats.count)
    }

    /// 次の章の先頭ビート（章スキップ用）。無ければ nil（＝ツアー終了）。
    static func firstBeatOfNextChapter(after beat: TutorialBeat) -> TutorialBeat? {
        guard let currentIndex = beats.firstIndex(of: beat) else { return nil }
        return beats.dropFirst(currentIndex + 1).first { $0.chapter != beat.chapter }
    }

    // MARK: 第1章 ようこそ

    private static let welcomeBeats: [TutorialBeat] = [
        TutorialBeat(
            id: "1-1", chapter: .welcome, presentation: .centerCard, targetTab: .home,
            title: "Megrumへようこそ！🎉",
            body: "これから使い方をサッと案内するよ。画面のどこでもタップで進めて、各章は「この章をとばす」でスキップもできるよ。"
        ),
    ]

    // MARK: 第2章 ホーム3セクション

    private static let homeBeats: [TutorialBeat] = [
        TutorialBeat(
            id: "2-1", chapter: .home, presentation: .spotlight(.homeSectionUserTag), targetTab: .home,
            title: "推し×シリーズでマッチ",
            body: "あなたが登録している「ほしいもの」の推しとシリーズが合致しているグッズがマッチ候補として並ぶよ"
        ),
        TutorialBeat(
            id: "2-2", chapter: .home, presentation: .spotlight(.homeSectionUser), targetTab: .home,
            title: "推しでマッチ",
            body: "あなたが登録している「ほしいもの」の推しが合致しているグッズがマッチ候補として並ぶよ"
        ),
        TutorialBeat(
            id: "2-3", chapter: .home, presentation: .spotlight(.homeSectionHaves), targetTab: .home,
            title: "求められているグッズ",
            body: "あなたのグッズのうち、「ほしい！」と思われているグッズと、その件数がここに並ぶよ"
        ),
    ]

    // MARK: 第3章 タブの地図

    private static let tabMapBeats: [TutorialBeat] = [
        TutorialBeat(
            id: "3-1", chapter: .tabMap, presentation: .tabBand, targetTab: .home,
            title: "ここまでが🏠ホーム",
            body: "いま見てきたのが、下の左端「ホーム」の画面だよ。次は「マイグッズ」を見にいこう。"
        ),
    ]

    // MARK: 第4章 マイグッズ＋登録デモ

    private static let inventoryBeats: [TutorialBeat] = [
        TutorialBeat(
            id: "4-1", chapter: .inventory, presentation: .banner, targetTab: .inventory,
            title: "「マイグッズ」タブ",
            body: "ここは交換に出せる手持ちグッズを並べる場所。上の「譲る候補／自分用キープ／過去に譲った」で整理できるよ。"
        ),
        TutorialBeat(
            id: "4-2", chapter: .inventory, presentation: .spotlight(.inventoryAddButton), targetTab: .inventory,
            title: "登録は左下の＋から",
            body: "ためしに1回、登録の流れを見てみよう。"
        ),
        TutorialBeat(
            id: "4-3", chapter: .inventory, presentation: .demo(.goods(.openEditor)), targetTab: .inventory,
            title: "登録をはじめる",
            body: "＋をタップすると登録シートが開くよ。"
        ),
        TutorialBeat(
            id: "4-4", chapter: .inventory, presentation: .demo(.goods(.pickOshi)), targetTab: .inventory,
            title: "推しを選ぶ",
            body: "まずグループ・作品を選ぶよ。今回は「TWICE」。"
        ),
        TutorialBeat(
            id: "4-5", chapter: .inventory, presentation: .demo(.goods(.pickType)), targetTab: .inventory,
            title: "グッズ種別を選ぶ",
            body: "つぎに種別。今回は「トレカ」を選んで、写真へ進むよ。"
        ),
        TutorialBeat(
            id: "4-6", chapter: .inventory, presentation: .demo(.goods(.pickPhotos)), targetTab: .inventory,
            title: "写真を選ぶ",
            body: "カメラで撮るか、ライブラリから選ぶよ。今回はトレカが9枚並んだ写真を1枚選んでみた。"
        ),
        TutorialBeat(
            id: "4-7", chapter: .inventory, presentation: .demo(.goods(.bulkDetect)), targetTab: .inventory,
            title: "トレカAIで一括登録",
            body: "「トレカ一括読み取り」を押すと、AIが1枚ずつ自動で切り抜いてくれるよ。今回は7枚が自動でOK、右下の2枚だけ読み取れなかったみたい。"
        ),
        TutorialBeat(
            id: "4-8", chapter: .inventory, presentation: .demo(.goods(.manualCrop)), targetTab: .inventory,
            title: "読み取れなかった分は手動で",
            body: "写真をタップして、枠を動かせば手動で切り抜けるよ。"
        ),
        TutorialBeat(
            id: "4-9", chapter: .inventory, presentation: .demo(.goods(.assignMembers)), targetTab: .inventory,
            title: "メンバーを付ける",
            body: "写真を選んでメンバーをまとめて割り当てられるよ（あとからでもOK）。"
        ),
        TutorialBeat(
            id: "4-10", chapter: .inventory, presentation: .demo(.goods(.assignSeries)), targetTab: .inventory,
            title: "シリーズを付ける",
            body: "シリーズ名がわからない時は「Google Lensで調べる」。今回は「#DIVE」だと分かったので入力したよ。"
        ),
        TutorialBeat(
            id: "4-11", chapter: .inventory, presentation: .demo(.goods(.saved)), targetTab: .inventory,
            title: "まとめて登録！",
            body: "「9件まとめて登録」を押せば完了。マイグッズ一覧に9枚とも並んだよ。実際の登録もこの流れ！"
        ),
    ]

    // MARK: 第5章 ほしいもの

    private static let wishBeats: [TutorialBeat] = [
        TutorialBeat(
            id: "5-1", chapter: .wish, presentation: .tabBand, targetTab: .inventory,
            title: "次は❤️ほしいもの",
            body: "下の「ほしいもの」タブへ移動するよ。"
        ),
        TutorialBeat(
            id: "5-2", chapter: .wish, presentation: .banner, targetTab: .wish,
            requestedWishSection: .wishes,
            title: "「ほしいもの」タブ",
            body: "探しているグッズを登録する場所。登録すると、ホームに交換候補が出るようになるよ。"
        ),
        TutorialBeat(
            id: "5-3", chapter: .wish, presentation: .spotlight(.wishAddButton), targetTab: .wish,
            requestedWishSection: .wishes,
            title: "追加は左下の＋から",
            body: "登録の流れはマイグッズと同じ。写真を撮るだけでOK。"
        ),
    ]

    // MARK: 第6章 個別募集＋作成デモ

    private static let listingBeats: [TutorialBeat] = [
        TutorialBeat(
            id: "6-1", chapter: .listing, presentation: .spotlight(.wishSectionSegment), targetTab: .wish,
            requestedWishSection: .wishes,
            title: "「個別募集」に切り替え",
            body: "上のセグメントで「個別募集」へ。"
        ),
        TutorialBeat(
            id: "6-2", chapter: .listing, presentation: .banner, targetTab: .wish,
            requestedWishSection: .listings,
            title: "個別募集＝交換条件カード",
            body: "「これを譲るから、これがほしい」の条件カード。求めるもの・譲るもの・交換条件の3つで1枚になっていて、ホームのマッチの材料になるよ。ためしに1枚作る流れを見てみよう。"
        ),
        TutorialBeat(
            id: "6-3", chapter: .listing, presentation: .demo(.listing(.openEditor)), targetTab: .wish,
            requestedWishSection: .listings,
            title: "募集を追加",
            body: "右下の「募集を追加」をタップ。"
        ),
        TutorialBeat(
            id: "6-4", chapter: .listing, presentation: .demo(.listing(.havesOverview)), targetTab: .wish,
            requestedWishSection: .listings,
            title: "1. 譲るものを選ぶ",
            body: "マイグッズから選ぶか、「定価で選ぶ」でお金にすることもできるよ。"
        ),
        TutorialBeat(
            id: "6-5", chapter: .listing, presentation: .demo(.listing(.havesCashTab)), targetTab: .wish,
            requestedWishSection: .listings,
            title: "定価で選ぶ",
            body: "今回は「定価で選ぶ」をタップ。"
        ),
        TutorialBeat(
            id: "6-6", chapter: .listing, presentation: .demo(.listing(.havesCashAmount)), targetTab: .wish,
            requestedWishSection: .listings,
            title: "金額を指定",
            body: "金額指定にして、1,500円と入力したよ。"
        ),
        TutorialBeat(
            id: "6-7", chapter: .listing, presentation: .demo(.listing(.wishOverview)), targetTab: .wish,
            requestedWishSection: .listings,
            title: "2. 欲しいものを登録",
            body: "ほしいものから選ぶ・条件で指定する・定価、の3通り。選択肢は5つまで持てるよ。"
        ),
        TutorialBeat(
            id: "6-8", chapter: .listing, presentation: .demo(.listing(.wishConditionTab)), targetTab: .wish,
            requestedWishSection: .listings,
            title: "条件から選ぶ",
            body: "「TWICE × トレカ」みたいに、グループとグッズ種別で指定できるよ。"
        ),
        TutorialBeat(
            id: "6-9", chapter: .listing, presentation: .demo(.listing(.wishCashTab)), targetTab: .wish,
            requestedWishSection: .listings,
            title: "定価もOK",
            body: "「定価でもいいよ」という選択肢も追加できるよ。"
        ),
        TutorialBeat(
            id: "6-10", chapter: .listing, presentation: .demo(.listing(.exchangeMethod)), targetTab: .wish,
            requestedWishSection: .listings,
            title: "3. 交換条件",
            body: "受け渡し方法を選ぶよ。今回は「現地交換・郵送OK」。"
        ),
        TutorialBeat(
            id: "6-11", chapter: .listing, presentation: .demo(.listing(.exchangeLocal)), targetTab: .wish,
            requestedWishSection: .listings,
            title: "現地交換の条件",
            body: "会える都道府県や日程を書いておけるよ。"
        ),
        TutorialBeat(
            id: "6-12", chapter: .listing, presentation: .demo(.listing(.exchangeMail)), targetTab: .wish,
            requestedWishSection: .listings,
            title: "郵送交換の条件",
            body: "送料の負担や発送までの目安もここで。"
        ),
        TutorialBeat(
            id: "6-13", chapter: .listing, presentation: .demo(.listing(.exchangeOffSpec)), targetTab: .wish,
            requestedWishSection: .listings,
            title: "条件外の打診",
            body: "「条件ぴったりじゃない打診も受け付ける」かどうかを選べるよ。"
        ),
        TutorialBeat(
            id: "6-14", chapter: .listing, presentation: .demo(.listing(.exchangeNote)), targetTab: .wish,
            requestedWishSection: .listings,
            title: "その他の要望",
            body: "スリーブ必須、などの要望はメモに。"
        ),
        TutorialBeat(
            id: "6-15", chapter: .listing, presentation: .demo(.listing(.save)), targetTab: .wish,
            requestedWishSection: .listings,
            title: "保存する",
            body: "内容が決まったら「保存する」をタップ。"
        ),
        TutorialBeat(
            id: "6-16", chapter: .listing, presentation: .demo(.listing(.afterSave)), targetTab: .wish,
            requestedWishSection: .listings,
            title: "募集カードができた！",
            body: "一覧に1枚目の募集が並んだよ。これがマッチ探しの材料になる。"
        ),
    ]

    // MARK: 第7章 打診デモ（激求の例）

    private static let proposalBeats: [TutorialBeat] = [
        TutorialBeat(
            id: "7-1", chapter: .proposal, presentation: .demo(.proposal(.openDetail)), targetTab: .home,
            title: "「激求！」の相手で試そう",
            body: "ホームの激求カードをタップすると、相手の詳細が開くよ。"
        ),
        TutorialBeat(
            id: "7-2", chapter: .proposal, presentation: .demo(.proposal(.profile)), targetTab: .home,
            title: "相手のプロフィール",
            body: "ユーザーネームをタップすると、評価や完了取引数が見られるよ。"
        ),
        TutorialBeat(
            id: "7-3", chapter: .proposal, presentation: .demo(.proposal(.exchangeTerms)), targetTab: .home,
            title: "相手の交換条件",
            body: "「交換条件」を押すと、現地/郵送や都道府県などの条件が見られるよ。"
        ),
        TutorialBeat(
            id: "7-4", chapter: .proposal, presentation: .demo(.proposal(.listingDetail)), targetTab: .home,
            title: "個別募集の詳細",
            body: "相手の募集内容（譲・求・条件）もここで確認できるよ。"
        ),
        TutorialBeat(
            id: "7-5", chapter: .proposal, presentation: .demo(.proposal(.pickFromWanted)), targetTab: .home,
            title: "相手の希望から選ぶ",
            body: "相手があなたのグッズを求めている時は、その中から譲るものを選べるよ。"
        ),
        TutorialBeat(
            id: "7-6", chapter: .proposal, presentation: .demo(.proposal(.pickFromMine)), targetTab: .home,
            title: "自分のグッズから選ぶ",
            body: "自分のマイグッズ一覧からも選べるよ。"
        ),
        TutorialBeat(
            id: "7-7", chapter: .proposal, presentation: .demo(.proposal(.pickMore)), targetTab: .home,
            title: "ほかにも交換できそうなら",
            body: "交換できそうなものがあればタップで追加。最低1つ選べば進めるよ。"
        ),
        TutorialBeat(
            id: "7-8", chapter: .proposal, presentation: .demo(.proposal(.confirm)), targetTab: .home,
            title: "交換内容を確認する",
            body: "「交換内容を確認する」を押すと、ゆずる・うけとるの最終確認になるよ。"
        ),
        TutorialBeat(
            id: "7-9", chapter: .proposal, presentation: .demo(.proposal(.send)), targetTab: .home,
            title: "打診に進む",
            body: "「打診に進む」で相手に届くよ。（今回はデモなのでここまで！）"
        ),
        TutorialBeat(
            id: "7-10", chapter: .proposal, presentation: .tabBand, targetTab: .home,
            title: "送った打診はどこへ？",
            body: "下の「やりとり」タブに届くよ。見にいこう。"
        ),
    ]

    // MARK: 第8章 やりとり

    private static let tradesBeats: [TutorialBeat] = [
        TutorialBeat(
            id: "8-1", chapter: .trades, presentation: .demo(.trades(.overview)), targetTab: .trades,
            title: "「やりとり」タブ",
            body: "送った・届いた打診はここに並ぶよ。下の「打診中／進行中／完了済み」で進み具合ごとに見られる。"
        ),
        TutorialBeat(
            id: "8-2", chapter: .trades, presentation: .demo(.trades(.chatFlow)), targetTab: .trades,
            title: "カードを開くと取引チャット",
            body: "①成立前＝条件の相談 ②成立後＝当日チャット（現在地・服装の共有）③交換したら証跡撮影 ④最後に評価。ぜんぶこの1画面で進むよ。"
        ),
    ]

    // MARK: 第9章 めぐり

    private static let meguriBeats: [TutorialBeat] = [
        TutorialBeat(
            id: "9-1", chapter: .meguri, presentation: .tabBand, targetTab: .trades,
            title: "最後は「めぐり」",
            body: "下の「めぐり」タブへ移動するよ。"
        ),
        TutorialBeat(
            id: "9-2", chapter: .meguri, presentation: .banner, targetTab: .meguri,
            title: "「めぐり」タブ",
            body: "ここは「めぐり」。周囲に自分の活動を投稿できたり、チャットルームでユーザーと交流ができたりするよ。丸いピンがグルーム（写真の投稿）、四角いピンがチャットルーム（掲示板）。"
        ),
        TutorialBeat(
            id: "9-3", chapter: .meguri, presentation: .meguriTapDemo, targetTab: .meguri,
            title: "1km圏内なら作成できる",
            body: "地図の1km圏内をタップすると、グルームやチャットルームをその場所に作成できるよ。ピンをタップすれば参加もできる。"
        ),
    ]

    // MARK: 第10章 完了

    private static let completionBeats: [TutorialBeat] = [
        TutorialBeat(
            id: "10-1", chapter: .completion, presentation: .centerCard, targetTab: .home,
            title: "準備OK！🎊",
            body: "まずはホームの「最初の3ステップ」からはじめよう。登録するほどマッチが増えるよ。"
        ),
    ]
}
