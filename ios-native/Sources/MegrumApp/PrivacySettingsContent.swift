import SwiftUI

@MainActor
struct PrivacySettingsContent: View {
    @ObservedObject var appState: MegrumAppState

    var body: some View {
        List {
            PrivacySafetyManagementSection(appState: appState)
            PrivacySharedInformationSection()
        }
    }
}

@MainActor
private struct PrivacySafetyManagementSection: View {
    @ObservedObject var appState: MegrumAppState

    var body: some View {
        Section {
            NavigationLink {
                BlockedUsersScreen(appState: appState)
            } label: {
                HelpRouteRow(
                    iconName: "person.crop.circle.badge.xmark",
                    title: "ブロックした人",
                    message: "ブロック中の相手を確認し、必要に応じて解除できます。"
                )
            }

            NavigationLink {
                LegalDocumentScreen(kind: .privacy)
            } label: {
                HelpRouteRow(
                    iconName: "hand.raised",
                    title: "プライバシーポリシー",
                    message: "Megrumが扱う情報と利用目的を確認できます。"
                )
            }
        } header: {
            Text("安全管理")
        }
    }
}

private struct PrivacySharedInformationSection: View {
    var body: some View {
        Section {
            HelpRouteRow(
                iconName: "location.circle",
                title: "位置情報",
                message: "グルームとチャットルームは位置情報の許可状態に応じて表示範囲が変わります。端末の設定アプリから変更できます。"
            )
            HelpRouteRow(
                iconName: "bell.badge",
                title: "通知の表示",
                message: "通知のON/OFFは設定一覧のモバイル通知から変更できます。"
            )
            HelpRouteRow(
                iconName: "shippingbox",
                title: "住所情報",
                message: "住所は取引に必要な場面だけで扱います。住所設定から内容を確認できます。"
            )
        } header: {
            Text("共有される情報")
        }
    }
}
