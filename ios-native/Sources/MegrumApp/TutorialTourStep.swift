import Foundation

/// ガイドツアーの見せ方の種類。
enum TutorialTourPresentation: Equatable {
    /// 全画面dim＋中央カード（ようこそ/完了）。
    case centerCard
    /// dim＋対象の切り抜き＋対象に隣接する吹き出し。
    case spotlight
    /// dimなし・下部バナー（めぐりマップなど画面全体を見せたいステップ）。
    case banner
}

/// 初回ガイドツアーの各ステップ。順に前進する。
/// 文言は「この画面が何か→なぜ使うか→どこを押すか」の順で1〜2文に収める（iter1226.337 オーナーFB反映）。
enum TutorialTourStep: Int, CaseIterable, Identifiable, Sendable {
    case welcome            // ウェルカムカード（中央）
    case homeSectionUserTag // ホーム「推し×シリーズでマッチ」をハイライト
    case homeSectionUser    // ホーム「推しでマッチ」をハイライト
    case homeSectionHaves   // ホーム「求められているグッズ」をハイライト
    case inventory          // マイグッズ + ボタン
    case wish               // ほしいもの + ボタン
    case listing            // 個別募集「募集を追加」
    case trades             // やりとり（ステージバー）
    case meguri             // めぐり（マップ全体・下部バナー）
    case completion         // 完了カード（中央）

    var id: Int { rawValue }

    var presentation: TutorialTourPresentation {
        switch self {
        case .welcome, .completion:
            return .centerCard
        case .meguri:
            return .banner
        default:
            return .spotlight
        }
    }

    /// このステップで前面に出すべきタブ。
    var targetTab: MegrumTab {
        switch self {
        case .welcome, .homeSectionUserTag, .homeSectionUser, .homeSectionHaves, .completion:
            return .home
        case .inventory:
            return .inventory
        case .wish, .listing:
            return .wish
        case .trades:
            return .trades
        case .meguri:
            return .meguri
        }
    }

    /// ほしいものタブで開くべきセクション（listing ステップは個別募集セクション）。
    var requestedWishSection: WishCollectionSection? {
        switch self {
        case .wish:
            return .wishes
        case .listing:
            return .listings
        default:
            return nil
        }
    }

    /// スポットライトを当てる対象アンカー。
    var spotlightAnchor: TutorialAnchorID? {
        switch self {
        case .homeSectionUserTag:
            return .homeSectionUserTag
        case .homeSectionUser:
            return .homeSectionUser
        case .homeSectionHaves:
            return .homeSectionHaves
        case .inventory:
            return .inventoryAddButton
        case .wish:
            return .wishAddButton
        case .listing:
            return .listingAddButton
        case .trades:
            return .tradesStageBar
        case .welcome, .meguri, .completion:
            return nil
        }
    }

    /// ホームのセクションへ自動スクロールするためのフォーカス（ホーム3ステップのみ）。
    var homeFocusAnchor: TutorialAnchorID? {
        switch self {
        case .homeSectionUserTag, .homeSectionUser, .homeSectionHaves:
            return spotlightAnchor
        default:
            return nil
        }
    }

    var calloutTitle: String {
        switch self {
        case .welcome:
            return "Megrumへようこそ！🎉"
        case .homeSectionUserTag:
            return "推し×シリーズでマッチ"
        case .homeSectionUser:
            return "推しでマッチ"
        case .homeSectionHaves:
            return "求められているグッズ"
        case .inventory:
            return "「マイグッズ」タブ"
        case .wish:
            return "「ほしいもの」タブ"
        case .listing:
            return "「個別募集」＝交換条件カード"
        case .trades:
            return "「やりとり」タブ"
        case .meguri:
            return "「めぐり」タブ"
        case .completion:
            return "準備OK！🎊"
        }
    }

    var calloutBody: String {
        switch self {
        case .welcome:
            return "これから使い方をサッと案内するよ。1分でだいじょうぶ。"
        case .homeSectionUserTag:
            return "あなたの「ほしいもの」と条件が合う相手が、ホームのいちばん上に並ぶよ。"
        case .homeSectionUser:
            return "同じ推しの相手が持っているグッズはここ。ほしいものを登録する前でも出会えるよ。"
        case .homeSectionHaves:
            return "あなたのグッズを「ほしい！」と言っている人はここに出るよ。"
        case .inventory:
            return "交換に出せる手持ちグッズを置いておく場所。左下の＋から、写真を撮るだけで登録できるよ。"
        case .wish:
            return "探しているグッズを登録する場所。登録すると、ホームに交換相手の候補が出るようになるよ。"
        case .listing:
            return "「これを譲るから、これがほしい」をセットにして公開できるよ。作るとマッチ相手が見つかりやすくなる。"
        case .trades:
            return "交換のお誘い（打診）が届いたらこのタブ。進み具合ごとに3つに分かれていて、チャットで相談して交換まで進めるよ。"
        case .meguri:
            return "ここは1km圏内の推し活マップ。近くの同担のグルーム（写真）やチャットルームが地図に出て、ゆるくつながれるよ。"
        case .completion:
            return "まずはホームの「最初の3ステップ」からはじめよう。登録するほどマッチが増えるよ。"
        }
    }

    /// VisualQA 用：環境変数 MEGRUM_VISUAL_QA_TUTORIAL_STEP の値からステップを解決する。
    /// 数字（rawValue）と kebab-case 名の両方を受け付ける。
    init?(visualQAValue: String) {
        let normalized = visualQAValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        if let rawValue = Int(normalized), let step = TutorialTourStep(rawValue: rawValue) {
            self = step
            return
        }
        switch normalized {
        case "welcome": self = .welcome
        case "home-1", "home-section-user-tag": self = .homeSectionUserTag
        case "home-2", "home-section-user": self = .homeSectionUser
        case "home-3", "home-section-haves": self = .homeSectionHaves
        case "inventory": self = .inventory
        case "wish": self = .wish
        case "listing": self = .listing
        case "trades": self = .trades
        case "meguri": self = .meguri
        case "completion": self = .completion
        default: return nil
        }
    }
}
