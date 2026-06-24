import MegrumCore
import MegrumDesign
import SwiftUI

struct SubscriptionSettingsScreen: View {
    @ObservedObject var appState: MegrumAppState

    private var state: UserSubscriptionState {
        appState.subscriptionState
    }

    var body: some View {
        List {
            Section {
                SubscriptionStatusRow(state: state)
                if appState.isLoadingSubscriptionState {
                    ProgressView("確認中")
                } else {
                    Button("状態を更新") {
                        Task {
                            await appState.loadSubscriptionState()
                        }
                    }
                }
            } header: {
                Text("現在の状態")
            }

            Section {
                ForEach(SubscriptionCatalog.defaultPlans.sorted { $0.sortOrder < $1.sortOrder }) { plan in
                    SubscriptionPlanRow(plan: plan, isCurrent: isCurrentPlan(plan))
                }
            } header: {
                Text("プラン候補")
            } footer: {
                Text("価格と提供条件は正式公開時の内容を表示します。コアの打診・取引・安全機能は無料のまま維持します。")
            }

            Section {
                ForEach(state.activeEntitlements()) { entitlement in
                    Label(entitlement.key.displayName, systemImage: "checkmark.seal.fill")
                        .foregroundStyle(MegrumTheme.ok)
                }
                if state.activeEntitlements().isEmpty {
                    Text("有効な有料権限はありません")
                        .foregroundStyle(MegrumTheme.muted)
                }
            } header: {
                Text("有効な権限")
            }
        }
        .navigationTitle("Premium会員")
        .megrumInlineNavigationTitle()
        .task {
            await appState.loadSubscriptionState(reportsFailure: false)
        }
    }

    private func isCurrentPlan(_ plan: SubscriptionPlanDefinition) -> Bool {
        if state.planType == plan.planType {
            return true
        }
        return state.hasActiveEntitlement(plan.entitlementKey)
    }
}

private struct SubscriptionStatusRow: View {
    var state: UserSubscriptionState

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(statusTitle)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(MegrumTheme.ink)
                Spacer()
                Text(statusBadge)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(statusBadgeColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(statusBadgeColor.opacity(0.12), in: Capsule())
            }

            Text(statusSubtitle)
                .font(.subheadline)
                .foregroundStyle(MegrumTheme.muted)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(statusTitle)
        .accessibilityHint(statusSubtitle)
    }

    private var statusTitle: String {
        if state.isPremiumActive {
            return "Premium会員"
        }
        if state.hasMeguriPlus {
            return "めぐりPlus"
        }
        return "無料プラン"
    }

    private var statusBadge: String {
        if state.isPremiumActive || state.hasMeguriPlus {
            return "有効"
        }
        return "未加入"
    }

    private var statusBadgeColor: Color {
        state.isPremiumActive || state.hasMeguriPlus ? MegrumTheme.ok : MegrumTheme.muted
    }

    private var statusSubtitle: String {
        if let currentPeriodEnd = state.currentPeriodEnd {
            return "現在の期間終了: \(currentPeriodEnd.formatted(date: .numeric, time: .omitted))"
        }
        return "打診・取引・安全機能は無料で利用できます"
    }
}

private struct SubscriptionPlanRow: View {
    var plan: SubscriptionPlanDefinition
    var isCurrent: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(plan.displayName)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(MegrumTheme.ink)
                    Text(plan.priceLabel)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MegrumTheme.lavender)
                }
                Spacer()
                if isCurrent {
                    Text("有効")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(MegrumTheme.ok)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(MegrumTheme.ok.opacity(0.12), in: Capsule())
                }
            }

            Text(plan.featureIDs.map(\.displayName).joined(separator: " / "))
                .font(.caption)
                .foregroundStyle(MegrumTheme.muted)
                .lineLimit(3)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(plan.displayName)
        .accessibilityHint(plan.featureIDs.map(\.displayName).joined(separator: "、"))
    }
}
