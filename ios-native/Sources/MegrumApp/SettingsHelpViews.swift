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
