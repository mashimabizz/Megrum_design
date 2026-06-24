import MegrumCore

public enum AccountSetupMode: Sendable {
    case onboarding
    case edit

    var headerTitle: String {
        switch self {
        case .onboarding:
            "Megrumへようこそ"
        case .edit:
            "プロフィールを整える"
        }
    }

    var headerSubtitle: String {
        switch self {
        case .onboarding:
            "まずはアプリ内で表示する名前、活動エリア、推しを設定します"
        case .edit:
            "表示名、活動エリア、推し設定をまとめて更新できます"
        }
    }

    var navigationTitle: String {
        switch self {
        case .onboarding:
            "プロフィール設定"
        case .edit:
            "プロフィール編集"
        }
    }

    var saveTitle: String {
        switch self {
        case .onboarding:
            "設定を完了する"
        case .edit:
            "プロフィールを更新する"
        }
    }

    var completionFootnote: String {
        switch self {
        case .onboarding:
            "完了するとホームへ進みます。あとからプロフィール画面で推し設定を編集できます。"
        case .edit:
            "保存後もこの画面で続けて推し設定を調整できます。"
        }
    }

    var completionTitle: String {
        switch self {
        case .onboarding:
            "初回設定が完了しました"
        case .edit:
            "プロフィールを更新しました"
        }
    }

    var completionMessage: String {
        switch self {
        case .onboarding:
            "表示名、活動エリア、推し設定を保存しました。"
        case .edit:
            "プロフィールと推し設定を保存しました。"
        }
    }
}

public enum AccountSetupDraftValidator {
    public static let missingDisplayNameMessage = "表示名を入力してください"
    public static let missingOshiMessage = "推しを1つ以上選択してください"

    public static func validationMessage(
        displayName: String,
        oshiSelections: [AccountSetupOshiInput]
    ) -> String? {
        if displayName.isBlank {
            return missingDisplayNameMessage
        }
        if oshiSelections.isEmpty {
            return missingOshiMessage
        }
        return nil
    }
}
