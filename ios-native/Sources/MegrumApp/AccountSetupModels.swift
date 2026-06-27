import MegrumCore
import Foundation

enum AccountSetupStep: Int, CaseIterable, Identifiable, Sendable {
    case welcome = 1
    case oshi = 2
    case area = 3
    case displayName = 4
    case handle = 5
    case birthDate = 6
    case gender = 7
    case completion = 8

    var id: Int { rawValue }
    var progressIndex: Int { rawValue }
    static var totalCount: Int { allCases.count }

    var title: String {
        switch self {
        case .welcome:
            "Megrumへようこそ"
        case .oshi:
            "推しを設定する"
        case .area:
            "活動エリアを選ぶ"
        case .displayName:
            "名前を設定する"
        case .handle:
            "ユーザーIDを設定する"
        case .birthDate:
            "生年月日を設定する"
        case .gender:
            "性別を設定する"
        case .completion:
            "設定はこれで終わりです"
        }
    }

    var subtitle: String {
        switch self {
        case .welcome:
            "大切なグッズとの出会いを、やさしくつなぎます。"
        case .oshi:
            "まずはグループ・作品を選び、次にメンバーを設定します。"
        case .area:
            "主に会いやすい都道府県を設定します。"
        case .displayName:
            "アプリ内で相手に表示されます。"
        case .handle:
            "プロフィールURLや検索で使う半角英数字のIDです。"
        case .birthDate:
            "年齢確認とプロフィール表示のために使います。"
        case .gender:
            "プロフィールに反映されます。あとから変更できます。"
        case .completion:
            "入力内容を保存してホーム画面へ進みます。"
        }
    }

    var primaryButtonTitle: String {
        switch self {
        case .welcome:
            "はじめる"
        case .completion:
            "ホームへ"
        default:
            "次へ"
        }
    }

    var previous: AccountSetupStep? {
        AccountSetupStep(rawValue: rawValue - 1)
    }

    var next: AccountSetupStep? {
        AccountSetupStep(rawValue: rawValue + 1)
    }
}

public enum AccountSetupMode: Sendable, Equatable {
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
            "完了するとホームへ進みます。あとからプロフィール画面で設定を編集できます。"
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
    public static let invalidDisplayNameMessage = "表示名は50文字以内で入力してください"
    public static let missingHandleMessage = "ユーザーIDを入力してください"
    public static let invalidHandleMessage = "ユーザーIDは半角英数字・_ の3〜20文字で入力してください"
    public static let missingPrefectureMessage = "活動エリアを選択してください"
    public static let invalidPrefectureMessage = "活動エリアは都道府県から選択してください"
    public static let missingBirthDateMessage = "生年月日を選択してください"
    public static let futureBirthDateMessage = "生年月日は今日以前の日付を選択してください"
    public static let missingGenderMessage = "性別を選択してください"
    public static let missingOshiMessage = "推しを1つ以上選択してください"
    public static let missingOshiGroupMessage = "グループ・作品を1つ以上選択してください"
    public static let missingOshiMemberMessage = "選んだグループ・作品ごとに、メンバー・キャラクターまたは全体を選択してください"

    public static func validationMessage(
        displayName: String,
        oshiSelections: [AccountSetupOshiInput]
    ) -> String? {
        validationMessage(
            displayName: displayName,
            handle: "megrum",
            prefecture: "東京都",
            birthDate: Date(timeIntervalSince1970: 0),
            gender: .female,
            oshiSelections: oshiSelections
        )
    }

    public static func validationMessage(
        displayName: String,
        handle: String,
        prefecture: String?,
        birthDate: Date?,
        gender: UserGender?,
        oshiSelections: [AccountSetupOshiInput]
    ) -> String? {
        validationMessage(for: .displayName, displayName: displayName, handle: handle, prefecture: prefecture, birthDate: birthDate, gender: gender, oshiSelections: oshiSelections)
            ?? validationMessage(for: .handle, displayName: displayName, handle: handle, prefecture: prefecture, birthDate: birthDate, gender: gender, oshiSelections: oshiSelections)
            ?? validationMessage(for: .area, displayName: displayName, handle: handle, prefecture: prefecture, birthDate: birthDate, gender: gender, oshiSelections: oshiSelections)
            ?? validationMessage(for: .birthDate, displayName: displayName, handle: handle, prefecture: prefecture, birthDate: birthDate, gender: gender, oshiSelections: oshiSelections)
            ?? validationMessage(for: .gender, displayName: displayName, handle: handle, prefecture: prefecture, birthDate: birthDate, gender: gender, oshiSelections: oshiSelections)
            ?? validationMessage(for: .oshi, displayName: displayName, handle: handle, prefecture: prefecture, birthDate: birthDate, gender: gender, oshiSelections: oshiSelections)
    }

    static func validationMessage(
        for step: AccountSetupStep,
        displayName: String,
        handle: String,
        prefecture: String?,
        birthDate: Date?,
        gender: UserGender?,
        oshiSelections: [AccountSetupOshiInput]
    ) -> String? {
        switch step {
        case .welcome, .completion:
            return nil
        case .oshi:
            return oshiSelections.isEmpty ? missingOshiMessage : nil
        case .area:
            let normalized = MegrumAppStateInputNormalizer.prefecture(prefecture)
            guard let normalized else {
                return missingPrefectureMessage
            }
            return JapanesePrefectureCatalog.all.contains(normalized) ? nil : invalidPrefectureMessage
        case .displayName:
            let normalized = MegrumAppStateInputNormalizer.trimmedText(displayName)
            if normalized.isEmpty {
                return missingDisplayNameMessage
            }
            return normalized.count <= 50 ? nil : invalidDisplayNameMessage
        case .handle:
            guard let normalized = MegrumAppStateInputNormalizer.profileHandle(handle) else {
                return missingHandleMessage
            }
            return MegrumAppStateInputNormalizer.isValidProfileHandle(normalized) ? nil : invalidHandleMessage
        case .birthDate:
            guard let birthDate else {
                return missingBirthDateMessage
            }
            return birthDate <= Date() ? nil : futureBirthDateMessage
        case .gender:
            return gender == nil ? missingGenderMessage : nil
        }
    }
}
