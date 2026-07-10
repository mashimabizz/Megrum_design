import Foundation

enum VisualQAInitialScreen: String, Equatable {
    case home
    case drawerOpen = "drawer-open"
    /// ドロワー経由の推し設定を直接開く（iter1226.405 刷新の確認用）。
    case oshiSettings = "oshi-settings"
    /// 住所設定を直接開く（iter1226.407 刷新の確認用）。
    case addressSettings = "address-settings"
    /// 通知センターを直接開く（iter1226.408 刷新の確認用）。
    case notifications
    case homeHavesLookup = "home-haves-lookup"
    case matchRelation = "match-relation"
    case matchRelationCandidates = "match-relation-candidates"
    case candidateSheet = "candidate-sheet"
    case proposalGive = "proposal-give"
    case proposalReceive = "proposal-receive"
    case proposalMeetup = "proposal-meetup"
    case proposalMeetupMonth = "proposal-meetup-month"
    case proposalConfirm = "proposal-confirm"
    case proposalComplete = "proposal-complete"
    case proposalPending = "proposal-pending"
    case authSignIn = "auth-sign-in"
    case authSignUp = "auth-sign-up"
    case authEmailSignIn = "auth-email-sign-in"
    case authEmailSignUp = "auth-email-sign-up"
    case authPasswordReset = "auth-password-reset"
    case accountSetup = "account-setup"
    case meguri
    case groomArchive = "groom-archive"
    case meguriProfileSettings = "meguri-profile-settings"
    case meguriMessages = "meguri-messages"
    case meguriMessageThread = "meguri-message-thread"
    case subscriptionSettings = "subscription-settings"
    case individualListings = "individual-listings"
    case individualListingHaves = "individual-listing-haves"
    case individualListingWish = "individual-listing-wish"
    case individualListingCondition = "individual-listing-condition"
    case individualListingCash = "individual-listing-cash"
    case individualListingExchange = "individual-listing-exchange"
    case ownProfile = "own-profile"
    case publicProfile = "public-profile"
    case inventory
    case wish
    case goodsTypeSelect = "goods-type-select"
    case search
    case profileProposal = "profile-proposal"
    case tutorial
    /// ホーム最上部に「最初の3ステップ」ミッションカードを強制表示する（QA/デモ確認用）。
    case starterMission = "starter-mission"

    var isAuthRoute: Bool {
        switch self {
        case .authSignIn, .authSignUp, .authEmailSignIn, .authEmailSignUp, .authPasswordReset:
            true
        default:
            false
        }
    }
}

enum VisualQAPreviewMode {
    static let environmentKey = "MEGRUM_VISUAL_QA_PREVIEW_AUTH"
    static let initialScreenEnvironmentKey = "MEGRUM_VISUAL_QA_INITIAL_SCREEN"
    static let subscriptionEnvironmentKey = "MEGRUM_VISUAL_QA_PREVIEW_SUBSCRIPTION"
    static let profileUserIDEnvironmentKey = "MEGRUM_VISUAL_QA_PROFILE_USER_ID"

    /// public-profile ルートで開く実ユーザーID（検証用・省略時はフィクスチャ）。
    static func profileUserID(environment: [String: String]) -> UUID? {
        environment[profileUserIDEnvironmentKey]
            .flatMap { UUID(uuidString: $0.trimmingCharacters(in: .whitespacesAndNewlines)) }
    }

    static func isEnabled(environment: [String: String]) -> Bool {
        switch environment[environmentKey]?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "1", "true", "yes", "on":
            true
        default:
            false
        }
    }

    static func initialScreen(environment: [String: String]) -> VisualQAInitialScreen? {
        guard
            let rawValue = environment[initialScreenEnvironmentKey]?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased(),
            !rawValue.isEmpty
        else {
            return nil
        }
        return VisualQAInitialScreen(rawValue: rawValue)
    }

    /// ガイドツアーの開始ビート指定（INITIAL_SCREEN=tutorial と併用）。
    /// ビートID（例: "4-7"）または全体通し番号（0始まり）を受け付ける。
    static let tutorialStepEnvironmentKey = "MEGRUM_VISUAL_QA_TUTORIAL_STEP"

    static func tutorialStartBeat(environment: [String: String]) -> TutorialBeat? {
        guard let raw = environment[tutorialStepEnvironmentKey]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased(),
            !raw.isEmpty
        else {
            return nil
        }
        if let beat = TutorialScript.beat(withID: raw) {
            return beat
        }
        if let index = Int(raw), TutorialScript.beats.indices.contains(index) {
            return TutorialScript.beats[index]
        }
        return nil
    }

    /// 章別再生（ヘルプ＞使い方ガイド相当）の検証用。章のrawValue（例: "meguri"）を受け付ける。
    /// INITIAL_SCREEN=tutorial と併用し、STEP指定より優先される。
    static let tutorialChapterEnvironmentKey = "MEGRUM_VISUAL_QA_TUTORIAL_CHAPTER"

    static func tutorialStartChapter(environment: [String: String]) -> TutorialChapter? {
        guard let raw = environment[tutorialChapterEnvironmentKey]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased(),
            !raw.isEmpty
        else {
            return nil
        }
        return TutorialChapter.allCases.first { String(describing: $0).lowercased() == raw }
    }
}
