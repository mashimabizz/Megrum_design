import MegrumDesign
import SwiftUI

struct SettingsHelpScreen: View {
    private let supportEmail = "support@megrum.jp"

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("困った時は、状況が分かる内容を添えてお問い合わせください。")
                        .font(.body)
                        .foregroundStyle(MegrumTheme.ink)

                    Text(supportEmail)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(MegrumTheme.lavender)
                        .textSelection(.enabled)
                }
                .padding(.vertical, 4)
            } header: {
                Text("問い合わせ")
            }

            Section {
                HelpRouteRow(
                    iconName: "bell",
                    title: "通知",
                    message: "打診、取引チャット、評価、掲示板の更新を確認できます。届かない時はモバイル通知のON/OFFも見直してください。"
                )
                HelpRouteRow(
                    iconName: "shippingbox",
                    title: "住所設定",
                    message: "住所情報を登録・更新できます。取引で必要になる場面に備えて、内容が古くないか確認してください。"
                )
                HelpRouteRow(
                    iconName: "person.crop.circle.badge.xmark",
                    title: "ブロックした人",
                    message: "ブロック中の相手を確認し、必要に応じて解除できます。"
                )
                HelpRouteRow(
                    iconName: "rectangle.portrait.and.arrow.right",
                    title: "ログアウト",
                    message: "共有端末や機種変更前など、今の端末からMegrumのセッションを外したい時に使います。"
                )
            } header: {
                Text("よく使う設定")
            }

            Section {
                NavigationLink {
                    MutualMatchConditionHelpScreen()
                } label: {
                    HelpRouteRow(
                        iconName: "arrow.left.arrow.right.circle",
                        title: "相互マッチの条件",
                        message: "個別募集同士の相互マッチで、交換条件や支払条件をどう見ているか確認できます。"
                    )
                }
            } header: {
                Text("マッチング")
            }

            Section {
                NavigationLink {
                    LegalDocumentScreen(kind: .terms)
                } label: {
                    HelpRouteRow(
                        iconName: "doc.text",
                        title: "利用規約",
                        message: "公開前レビュー後の正式本文へ差し替えるための入口です。"
                    )
                }
                NavigationLink {
                    LegalDocumentScreen(kind: .privacy)
                } label: {
                    HelpRouteRow(
                        iconName: "hand.raised",
                        title: "プライバシーポリシー",
                        message: "扱う情報と問い合わせ先を確認できます。"
                    )
                }
                NavigationLink {
                    LegalDocumentScreen(kind: .commerce)
                } label: {
                    HelpRouteRow(
                        iconName: "building.columns",
                        title: "特定商取引法に基づく表記",
                        message: "有料機能と事業者表示の確認入口です。"
                    )
                }
            } header: {
                Text("法的文書")
            }

            Section {
                Text("取引中の相手と連絡が取れない、待ち合わせに不安がある、相手の行動に問題を感じる場合は、取引チャットの内容や状況を整理してサポートへ連絡してください。")
                    .font(.body)
                    .foregroundStyle(MegrumTheme.ink)
                    .padding(.vertical, 4)
            } header: {
                Text("取引で困った時")
            }
        }
        .navigationTitle("ヘルプ")
        .megrumInlineNavigationTitle()
    }
}

struct MutualMatchConditionHelpScreen: View {
    var body: some View {
        List {
            Section {
                HelpDetailText("相互マッチは、あなたの個別募集と相手の個別募集が、両方向に噛み合っている候補です。グッズ条件で候補を作り、交換条件や支払条件は候補から除外せず、すり合わせが必要な点として表示します。")
            } header: {
                Text("基本")
            }

            Section {
                HelpDetailRow(title: "現地交換 × 現地交換", message: "現地交換の条件を確認します。")
                HelpDetailRow(title: "郵送交換 × 郵送交換", message: "郵送交換の条件を確認します。")
                HelpDetailRow(title: "現地交換 × 郵送交換", message: "共通の交換手段がないため、交換手段のすり合わせが必要です。")
                HelpDetailRow(title: "現地交換・郵送OKを含む場合", message: "現地または郵送のうち、問題が少ない方を優先して見ます。")
            } header: {
                Text("交換手段")
            }

            Section {
                HelpDetailRow(title: "都道府県が同じ", message: "日程が相談、または指定日程が重なれば問題なしとして扱います。")
                HelpDetailRow(title: "都道府県が違う", message: "現地交換にする場合は、場所のすり合わせが必要です。")
                HelpDetailRow(title: "日程が合わない", message: "両方が日程を指定していて重ならない場合は、日程調整が必要です。")
                HelpDetailRow(title: "片方が相談して決める", message: "日程は柔軟条件として扱い、日程不一致にはしません。")
                HelpDetailRow(title: "都道府県が未設定", message: "現地交換にする場合は、先に都道府県の確認が必要です。")
            } header: {
                Text("現地交換条件")
            }

            Section {
                HelpDetailRow(title: "自己負担 × 自己負担", message: "送料条件は問題なしとして扱います。")
                HelpDetailRow(title: "要相談を含む", message: "不一致ではなく、送料を決める必要がある状態として扱います。")
            } header: {
                Text("郵送交換条件")
            }

            Section {
                HelpDetailText("支払条件は、物々交換だけの候補では見ません。どちらかの求めるものに定価または金額指定が含まれる場合だけ、銀行振込、PayPay、現金交換などの共通手段を確認します。")
                HelpDetailRow(title: "PayPayなど共通する支払方法がある", message: "支払条件は問題なしとして扱います。")
                HelpDetailRow(title: "共通手段がない", message: "支払方法のすり合わせが必要です。")
                HelpDetailRow(title: "未設定がある", message: "未設定の側で支払条件を設定する必要があります。")
                HelpDetailRow(title: "共通手段がその他のみ", message: "具体的な支払方法を相談する必要があります。")
            } header: {
                Text("支払条件")
            }

            Section {
                HelpDetailRow(title: "定価同士", message: "定価という同じ文字条件として扱います。")
                HelpDetailRow(title: "定価と金額指定", message: "定価には具体的な金額がないため、金額そのものは比較せず、金額を含む候補として扱います。")
                HelpDetailRow(title: "金額指定同士", message: "提示額が求める金額を下回る場合は、金額面のすり合わせが必要です。")
            } header: {
                Text("定価・金額指定")
            }
        }
        .navigationTitle("相互マッチの条件")
        .megrumInlineNavigationTitle()
    }
}

private struct HelpDetailText: View {
    var message: String

    init(_ message: String) {
        self.message = message
    }

    var body: some View {
        Text(message)
            .font(.body)
            .foregroundStyle(MegrumTheme.ink)
            .padding(.vertical, 4)
    }
}

private struct HelpDetailRow: View {
    var title: String
    var message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(MegrumTheme.ink)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(MegrumTheme.muted)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

struct HelpRouteRow: View {
    var iconName: String
    var title: String
    var message: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(MegrumTheme.ink)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(MegrumTheme.muted)
            }
            .padding(.vertical, 3)
        } icon: {
            Image(systemName: iconName)
                .foregroundStyle(MegrumTheme.lavender)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityHint(message)
    }
}
