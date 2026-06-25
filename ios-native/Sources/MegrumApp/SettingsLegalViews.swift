import MegrumDesign
import SwiftUI

struct LegalDocumentScreen: View {
    var kind: LegalDocumentKind

    var body: some View {
        LegalDocumentContent(kind: kind)
        .navigationTitle(kind.title)
        .megrumInlineNavigationTitle()
    }
}

enum LegalDocumentKind {
    case terms
    case privacy
    case commerce

    var title: String {
        switch self {
        case .terms:
            "利用規約"
        case .privacy:
            "プライバシーポリシー"
        case .commerce:
            "特定商取引法に基づく表記"
        }
    }

    var statusMessage: String {
        "この画面は正式な法的本文ではありません。公開前レビュー後の原文へ差し替えるための入口として、確認に必要な要点だけを表示しています。"
    }

    var summaryItems: [LegalSummaryItem] {
        switch self {
        case .terms:
            [
                LegalSummaryItem(
                    title: "Megrumの目的",
                    body: "推し活グッズの取引を、打診、取引チャット、待ち合わせ、評価まで一連の流れで支援します。"
                ),
                LegalSummaryItem(
                    title: "ユーザーの責任",
                    body: "登録内容、在庫情報、wish、取引相手とのやりとりは、正確で相手に誤解を与えない内容にしてください。"
                ),
                LegalSummaryItem(
                    title: "禁止事項",
                    body: "チケット転売、盗品や権利侵害品の取引、相手への迷惑行為、アプリ外での不適切な誘導は禁止です。"
                ),
                LegalSummaryItem(
                    title: "取引と安全",
                    body: "合意した内容を守り、待ち合わせや取引チャットの情報は当該取引の目的にだけ使います。"
                ),
                LegalSummaryItem(
                    title: "運営の対応",
                    body: "通報や異議申し立てを確認し、必要に応じて表示制限、アカウント制限、証跡確認を行います。"
                )
            ]
        case .privacy:
            [
                LegalSummaryItem(
                    title: "取得する情報",
                    body: "アカウント、プロフィール、推し、在庫情報、wish、打診、取引チャット、住所情報、位置情報、通知設定などを扱います。"
                ),
                LegalSummaryItem(
                    title: "利用目的",
                    body: "アカウント管理、取引の成立と安全な進行、通知、問い合わせ対応、不正利用の防止、サービス改善に利用します。"
                ),
                LegalSummaryItem(
                    title: "相手への表示",
                    body: "取引に必要なプロフィール、在庫情報、wish、待ち合わせ情報、任意共有した服装写真や現在地を、必要な範囲で表示します。"
                ),
                LegalSummaryItem(
                    title: "保存と削除",
                    body: "取引の安全確認、異議申し立て、法令対応に必要な範囲で保存し、不要になった情報は削除または非表示化します。"
                ),
                LegalSummaryItem(
                    title: "外部サービス",
                    body: "認証、通知、決済、分析、問い合わせ対応などで外部サービスを使う場合があります。"
                )
            ]
        case .commerce:
            [
                LegalSummaryItem(
                    title: "表示方針",
                    body: "代表者名・住所・電話番号は、請求があれば遅滞なく開示する方針です。"
                ),
                LegalSummaryItem(
                    title: "有料機能",
                    body: "Premium、めぐりPlus、ブーストなどの価格と提供条件は、公開前レビュー済みの本文に合わせて表示します。"
                ),
                LegalSummaryItem(
                    title: "問い合わせ先",
                    body: "問い合わせは support@megrum.jp で受け付けます。"
                )
            ]
        }
    }
}
