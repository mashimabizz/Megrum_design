import MegrumCore
import MegrumDesign
import SwiftUI

struct OwnProfileSummary: Equatable, Sendable {
    var displayName: String
    var handle: String
    var prefecture: String?
    var inventoryCount: Int
    var wishCount: Int
    var activeTradeCount: Int

    var prefectureText: String {
        trimmedNonEmpty(prefecture) ?? "未設定"
    }

    var handleText: String {
        "@\(handle)"
    }

    var activeTradeText: String {
        "\(activeTradeCount)件"
    }

    init?(viewer: UserProfile?, inventoryCount: Int, wishCount: Int, proposals: [TradeProposal]) {
        guard let viewer else {
            return nil
        }
        self.displayName = viewer.displayName
        self.handle = viewer.handle
        self.prefecture = viewer.prefectureForDisplay
        self.inventoryCount = inventoryCount
        self.wishCount = wishCount
        self.activeTradeCount = proposals.filter(\.status.isOwnProfileActiveTrade).count
    }
}

@MainActor
struct OwnProfileScreen: View {
    @ObservedObject var appState: MegrumAppState

    private var summary: OwnProfileSummary? {
        OwnProfileSummary(
            viewer: appState.viewer,
            inventoryCount: appState.inventory.count,
            wishCount: appState.wishes.count,
            proposals: appState.proposals
        )
    }

    var body: some View {
        List {
            if let summary {
                Section {
                    OwnProfileHeader(summary: summary)
                        .listRowInsets(EdgeInsets(top: 18, leading: 18, bottom: 18, trailing: 18))
                }

                Section("プロフィール") {
                    OwnProfileInfoRow(title: "ユーザーID", value: summary.handleText, systemImage: "at")
                    OwnProfileInfoRow(title: "活動エリア", value: summary.prefectureText, systemImage: "mappin.and.ellipse")
                }

                Section("いまの状態") {
                    OwnProfileMetricRow(title: "譲るもの", value: "\(summary.inventoryCount)件", systemImage: "shippingbox")
                    OwnProfileMetricRow(title: "Wish", value: "\(summary.wishCount)件", systemImage: "heart")
                    OwnProfileMetricRow(title: "進行中のやりとり", value: summary.activeTradeText, systemImage: "arrow.left.arrow.right")
                }

                Section {
                    NavigationLink {
                        AccountSetupScreen(appState: appState, mode: .edit)
                    } label: {
                        Label("プロフィールと推しを編集", systemImage: "person.crop.circle.badge.checkmark")
                    }
                } footer: {
                    Text("表示名、活動エリア、複数の推しをまとめて更新します。")
                }
            } else {
                Section {
                    ContentUnavailableView(
                        "プロフィールを読み込めません",
                        systemImage: "person.crop.circle",
                        description: Text("ログイン状態を確認してからもう一度開いてください。")
                    )
                }
            }
        }
        .navigationTitle("自分のプロフィール")
        .megrumInlineNavigationTitle()
    }
}

private struct OwnProfileHeader: View {
    var summary: OwnProfileSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [MegrumTheme.lavender, MegrumTheme.sky],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text(initial)
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(width: 78, height: 78)

            VStack(alignment: .leading, spacing: 5) {
                Text(summary.displayName)
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)

                Text(summary.handleText)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(MegrumTheme.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(4)
    }

    private var initial: String {
        summary.displayName.first.map(String.init) ?? "M"
    }
}

private struct OwnProfileInfoRow: View {
    var title: String
    var value: String
    var systemImage: String

    var body: some View {
        Label {
            HStack {
                Text(title)
                Spacer()
                Text(value)
                    .foregroundStyle(MegrumTheme.muted)
                    .multilineTextAlignment(.trailing)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(MegrumTheme.lavender)
        }
    }
}

private struct OwnProfileMetricRow: View {
    var title: String
    var value: String
    var systemImage: String

    var body: some View {
        Label {
            HStack {
                Text(title)
                Spacer()
                Text(value)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(MegrumTheme.ink)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(MegrumTheme.lavender)
        }
    }
}

private extension UserProfile {
    var prefectureForDisplay: String? {
        trimmedNonEmpty(prefecture)
    }
}

private func trimmedNonEmpty(_ value: String?) -> String? {
    let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return trimmed.isEmpty ? nil : trimmed
}

private extension ProposalStatus {
    var isOwnProfileActiveTrade: Bool {
        switch self {
        case .sent, .negotiating, .agreementOneSide, .agreed:
            true
        case .draft, .rejected, .expired, .cancelled, .completed:
            false
        }
    }
}
