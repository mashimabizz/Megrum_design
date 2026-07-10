import CoreGraphics
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
    case pickOshi        // TWICEをタップ→推し欄に入る
    case pickType        // トレカをタップ→種別欄に入る
    case pickPhotos      // 9枚グリッド写真を選択
    case bulkDetect      // 一括読み取りを押す→AIが7枚を自動切り抜き（右下2枚は未検出）
    case manualCrop      // 指が左上→右下へドラッグして黄色枠で手動切り抜き
    case assignMembers   // メンバー割当（下部の一括設定ボタンを見せる）
    case seriesButton    // 「シリーズ」ボタンを押す
    case seriesSheetLens // シリーズ設定シートで「Google Lensで調べる」を押す
    case lensOpened      // Google Lens が起動した画面
    case lensCopy        // 結果「TWICE DIVE」をコピー
    case seriesPaste     // タグ欄にペースト→適用
    case saved           // 9件まとめて登録→一覧に載る
}

/// 第6章 個別募集作成デモの各ビート（オーナー指定の区切りそのまま）。
enum TutorialListingDemoBeat: Int, CaseIterable, Sendable {
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
    case openDetail      // 詳細シートが開いた（全体像）
    case profileTap      // ユーザーネームをタップ（実演）
    case profile         // 相手プロフィール画面
    case exchangeTerms   // 交換条件を見る
    case listingDetail   // 個別募集の詳細
    case receivePick     // 受け取るものを選ぶ（2つ選ぶ実演）
    case pickFromWanted  // 相手の希望から譲るものを選ぶ（選択済み状態）
    case pickFromMine    // 自分のグッズから譲るものを選ぶ
    case pickMore        // 追加で選ぶ（最低1つ・下部を表示）
    case confirmTap      // 「交換内容を確認する」をタップ
    case preview         // 打診内容プレビュー→「打診に進む」
}

/// 第8章 やりとりデモ。
enum TutorialTradesDemoBeat: Int, CaseIterable, Sendable {
    case chatFlow        // 取引チャットの一連の流れ
}

/// 第9章 めぐりのプレビューデモ。
enum TutorialMeguriDemoBeat: Int, CaseIterable, Sendable {
    case groomPreview    // グルームビューアのプレビュー
    case boardPreview    // チャットルーム（紹介画面）のプレビュー
}

/// デモステージに出すシーン。
enum TutorialDemoScene: Equatable, Sendable {
    case goods(TutorialGoodsDemoBeat)
    case listing(TutorialListingDemoBeat)
    case proposal(TutorialProposalDemoBeat)
    case trades(TutorialTradesDemoBeat)
    case meguri(TutorialMeguriDemoBeat)
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
    /// spotlight ビートで指アイコンを出す位置（画面比率 0〜1）。nil なら指なし。
    var pointerFraction: CGPoint?
    /// banner 提示で説明カードを上に置く（画面下部の切替UI等が説明対象のビート用）。
    var bannerCaptionAtTop = false

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

    // MARK: 第1章 ようこそ

    private static let welcomeBeats: [TutorialBeat] = [
        TutorialBeat(
            id: "1-1", chapter: .welcome, presentation: .centerCard, targetTab: .home,
            title: "Megrumへようこそ！🎉",
            body: "これから使い方をサッと案内するよ。画面のどこでもタップで進めて、「戻る」で1つ前にも戻れるよ。あとからヘルプの「使い方ガイド」でも見返せるよ。"
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
            title: "まとめて登録",
            body: "「まとめて登録」を押すとAIが枠を自動で配置して1枚ずつ切り抜き。今回は7枚OK、右下の2枚は読み取れなかったみたい。"
        ),
        TutorialBeat(
            id: "4-8", chapter: .inventory, presentation: .demo(.goods(.manualCrop)), targetTab: .inventory,
            title: "読み取れなかった分は手動で",
            body: "写真をタップして、枠を動かせば手動で切り抜けるよ。"
        ),
        TutorialBeat(
            id: "4-9", chapter: .inventory, presentation: .demo(.goods(.assignMembers)), targetTab: .inventory,
            title: "メンバーを付ける",
            body: "写真を選んで、下の「メンバー登録」からまとめて割り当てられるよ（あとからでもOK）。"
        ),
        TutorialBeat(
            id: "4-10", chapter: .inventory, presentation: .demo(.goods(.seriesButton)), targetTab: .inventory,
            title: "シリーズを付ける",
            body: "同じように、下の「シリーズ登録」からまとめて付けられるよ。"
        ),
        TutorialBeat(
            id: "4-11", chapter: .inventory, presentation: .demo(.goods(.seriesSheetLens)), targetTab: .inventory,
            title: "わからない時はGoogle Lens",
            body: "シリーズ名が分からない時は「Google Lensで調べる」をタップ。"
        ),
        TutorialBeat(
            id: "4-12", chapter: .inventory, presentation: .demo(.goods(.lensOpened)), targetTab: .inventory,
            title: "Google Lensが起動",
            body: "カードの写真からそのまま画像検索できるよ。"
        ),
        TutorialBeat(
            id: "4-13", chapter: .inventory, presentation: .demo(.goods(.lensCopy)), targetTab: .inventory,
            title: "結果をコピー",
            body: "出てきた結果からシリーズ名「DIVE」を長押しでコピー。"
        ),
        TutorialBeat(
            id: "4-14", chapter: .inventory, presentation: .demo(.goods(.seriesPaste)), targetTab: .inventory,
            title: "シリーズ欄にペースト",
            body: "シリーズ欄に貼り付けて「登録」。9枚ぜんぶに #DIVE が付くよ。"
        ),
        TutorialBeat(
            id: "4-15", chapter: .inventory, presentation: .demo(.goods(.saved)), targetTab: .inventory,
            title: "まとめて登録！",
            body: "「9件まとめて登録」を押せば完了。マイグッズ一覧に9枚とも並んだよ。実際の登録もこの流れ！"
        ),
    ]

    // MARK: 第5章 ほしいもの

    private static let wishBeats: [TutorialBeat] = [
        TutorialBeat(
            id: "5-1", chapter: .wish, presentation: .tabBand, targetTab: .inventory,
            title: "次は「ほしいもの」",
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
            body: "「これを譲るからこれがほしい」の条件カード。ホームのマッチの材料になるよ。ためしに1枚作ってみよう。"
        ),
        TutorialBeat(
            id: "6-3", chapter: .listing, presentation: .spotlight(.listingAddButton), targetTab: .wish,
            requestedWishSection: .listings,
            title: "募集を追加",
            body: "右下の「募集を追加」をタップすると作成がはじまるよ。"
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
            body: "ほしいものから選ぶ・条件から選ぶ・定価、の3通り。選択肢は5つまで持てるよ。"
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
            body: "「条件外の打診も受け付ける」かどうかを選べるよ。近い条件なら相談したい人向け。"
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
            id: "7-1", chapter: .proposal, presentation: .spotlight(.homeSectionUserTag), targetTab: .home,
            title: "「激求！」の相手で試そう",
            body: "激求＝あなたのグッズを名指しで求めている状態。一番上のサナの行をタップしてみよう。",
            pointerFraction: CGPoint(x: 0.24, y: 0.295)
        ),
        TutorialBeat(
            id: "7-2", chapter: .proposal, presentation: .demo(.proposal(.openDetail)), targetTab: .home,
            title: "相手の詳細が開いた",
            body: "上に交換条件と支払い条件、下に選ぶエリアが並ぶよ。"
        ),
        TutorialBeat(
            id: "7-3", chapter: .proposal, presentation: .demo(.proposal(.profileTap)), targetTab: .home,
            title: "プロフィールを見るには",
            body: "上のユーザーネームをタップ。"
        ),
        TutorialBeat(
            id: "7-4", chapter: .proposal, presentation: .demo(.proposal(.profile)), targetTab: .home,
            title: "相手のプロフィール",
            body: "評価やLike数、譲るグッズの一覧はここで見られるよ。"
        ),
        TutorialBeat(
            id: "7-5", chapter: .proposal, presentation: .demo(.proposal(.exchangeTerms)), targetTab: .home,
            title: "相手の交換条件",
            body: "現地/郵送の可否や送料など、相手の交換条件はここ。"
        ),
        TutorialBeat(
            id: "7-6", chapter: .proposal, presentation: .demo(.proposal(.listingDetail)), targetTab: .home,
            title: "個別募集の詳細",
            body: "募集内容（譲・求・条件）は「個別募集の詳細を見る」から。"
        ),
        TutorialBeat(
            id: "7-7", chapter: .proposal, presentation: .demo(.proposal(.receivePick)), targetTab: .home,
            title: "受け取るものを選ぶ",
            body: "ほしいものをタップで選ぶよ。今回は2つ選んでみた。"
        ),
        TutorialBeat(
            id: "7-8", chapter: .proposal, presentation: .demo(.proposal(.pickFromWanted)), targetTab: .home,
            title: "相手の希望から譲るを選ぶ",
            body: "相手が求めているあなたのグッズから、どれか1つ選べるよ。"
        ),
        TutorialBeat(
            id: "7-9", chapter: .proposal, presentation: .demo(.proposal(.pickFromMine)), targetTab: .home,
            title: "自分のグッズからも選べる",
            body: "「他の選択肢」からマイグッズ一覧を開けるよ。"
        ),
        TutorialBeat(
            id: "7-10", chapter: .proposal, presentation: .demo(.proposal(.pickMore)), targetTab: .home,
            title: "ほかにも交換できそうなら",
            body: "他にも交換できそうなものがあれば下に並ぶよ。タップで打診にまとめて追加できる。"
        ),
        TutorialBeat(
            id: "7-11", chapter: .proposal, presentation: .demo(.proposal(.confirmTap)), targetTab: .home,
            title: "交換内容を確認する",
            body: "選び終わったら、下の「交換内容を確認する」をタップ。"
        ),
        TutorialBeat(
            id: "7-12", chapter: .proposal, presentation: .demo(.proposal(.preview)), targetTab: .home,
            title: "内容を確認して打診！",
            body: "内容を確認して「この内容で打診を送信」で相手に届くよ。（デモはここまで）"
        ),
        TutorialBeat(
            id: "7-13", chapter: .proposal, presentation: .tabBand, targetTab: .home,
            title: "送った打診はどこへ？",
            body: "下の「やりとり」タブに届くよ。見にいこう。"
        ),
    ]

    // MARK: 第8章 やりとり

    private static let tradesBeats: [TutorialBeat] = [
        TutorialBeat(
            id: "8-1", chapter: .trades, presentation: .banner, targetTab: .trades,
            title: "「やりとり」タブ",
            body: "送った・届いた打診はここ。下の「打診中/進行中/完了済み」で切り替えられるよ。",
            bannerCaptionAtTop: true
        ),
        TutorialBeat(
            id: "8-2", chapter: .trades, presentation: .demo(.trades(.chatFlow)), targetTab: .trades,
            title: "カードを開くと取引チャット",
            body: "成立前の相談→成立→当日チャット→証跡→評価まで、この1画面で進むよ。"
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
            body: "ここは「めぐり」。周囲に自分の活動を投稿したり、チャットルームで交流できるよ。"
        ),
        TutorialBeat(
            id: "9-3", chapter: .meguri, presentation: .banner, targetTab: .meguri,
            title: "2種類のピン",
            body: "丸いピン＝グルーム（写真の投稿）、四角いピン＝チャットルーム（掲示板）。"
        ),
        TutorialBeat(
            id: "9-4", chapter: .meguri, presentation: .meguriTapDemo, targetTab: .meguri,
            title: "1km圏内なら作成できる",
            body: "自分の1km圏内をタップすると、その場所に作成できるよ。"
        ),
        TutorialBeat(
            id: "9-5", chapter: .meguri, presentation: .demo(.meguri(.groomPreview)), targetTab: .meguri,
            title: "グルームのプレビュー",
            body: "丸いピンをタップするとこんなふうに見られるよ。いいねやコメントもここから。"
        ),
        TutorialBeat(
            id: "9-6", chapter: .meguri, presentation: .demo(.meguri(.boardPreview)), targetTab: .meguri,
            title: "チャットルームのプレビュー",
            body: "四角いピンがチャットルーム。部屋ごとの名前で、近くの人と気軽にやりとりできるよ。"
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
