import Foundation

/// 初回ガイドツアーの各ステップ。順に前進する。
/// value 訴求（AccountSetupWelcomeStep の3スライド）は済んでいるので、ここは操作の場所案内に徹する。
enum TutorialTourStep: Int, CaseIterable, Identifiable, Sendable {
    case welcome        // ウェルカムカード（中央・スポットライトなし）
    case homeSections   // ホーム3セクション紹介（サンプル表示中）
    case inventory      // マイグッズ + ボタン
    case wish           // ほしいもの + ボタン
    case listing        // 個別募集「募集を追加」
    case trades         // やりとり（ステージバー）
    case meguri         // めぐり（マップ全体）
    case completion     // 完了カード（中央）

    var id: Int { rawValue }

    /// このステップで前面に出すべきタブ。
    var targetTab: MegrumTab {
        switch self {
        case .welcome, .homeSections, .completion:
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

    /// 中央カード表示か（スポットライトなし）。
    var isCardStep: Bool { self == .welcome || self == .completion }

    /// スポットライトを当てる対象アンカー。
    /// homeSections / meguri は特定の対象がなく、サンプル/マップを見せたいので dim せず nil。
    var spotlightAnchor: TutorialAnchorID? {
        switch self {
        case .inventory:
            return .inventoryAddButton
        case .wish:
            return .wishAddButton
        case .listing:
            return .listingAddButton
        case .trades:
            return .tradesStageBar
        case .welcome, .homeSections, .meguri, .completion:
            return nil
        }
    }

    var calloutTitle: String {
        switch self {
        case .welcome:
            return "Megrumへようこそ！🎉"
        case .homeSections:
            return "ここがホーム"
        case .inventory:
            return "持っているグッズを登録"
        case .wish:
            return "探しているグッズを登録"
        case .listing:
            return "個別募集で交換相手を探す"
        case .trades:
            return "やりとりはここ"
        case .meguri:
            return "めぐりで“今”をシェア"
        case .completion:
            return "準備OK！🎊"
        }
    }

    var calloutBody: String {
        switch self {
        case .welcome:
            return "これから使い方をサッと案内するよ。1分でだいじょうぶ。"
        case .homeSections:
            return "「推し×シリーズでマッチ」はあなたのほしいものに合う相手、「推しでマッチ」は同じ推しの相手のグッズ、「求められているグッズ」はあなたのグッズを欲しい人が並ぶよ。"
        case .inventory:
            return "まずはここでマイグッズを登録。写真を撮るだけで、何枚でもまとめて登録できるよ。"
        case .wish:
            return "ほしいものを登録すると、ホームに交換候補が出るようになるよ。"
        case .listing:
            return "「これを譲るからこれが欲しい」の条件が個別募集。作るとマッチ相手が見つかりやすくなるよ。"
        case .trades:
            return "交換の打診が届いたらこのタブ。チャットで条件を相談して、待ち合わせて交換！"
        case .meguri:
            return "1km圏内の推し活マップ。近くの同担とグルームやチャットルームでつながれるよ。"
        case .completion:
            return "まずは「最初の3ステップ」からはじめよう。ホームでいつでも続きを確認できるよ。"
        }
    }
}
