import MegrumCore
import MegrumDesign
import SwiftUI

struct SubscriptionSettingsContent: View {
    var state: UserSubscriptionState
    var isLoading: Bool
    var offer: MegrumPlusPurchaseOffer
    var isLoadingOffer: Bool
    var isPurchasing: Bool
    var purchaseMessage: String?
    var purchaseErrorMessage: String?
    var isPurchaseEnabled: Bool
    var onPurchase: () -> Void
    var onRestore: () -> Void
    var onReload: () -> Void
    var onToggleDebugPlan: (() -> Void)? = nil

    var body: some View {
        List {
            Section {
                MegrumPlusHeroRow(
                    isActive: state.isMegrumPlusActive,
                    priceText: offer.priceText,
                    isLoadingOffer: isLoadingOffer
                )
            }

            debugPlanSection

            Section {
                ForEach(MegrumPlusBenefitItem.defaultItems) { item in
                    MegrumPlusBenefitRow(item: item)
                }
            } header: {
                Text("できること")
            } footer: {
                Text("無料プランでは個別募集は3件まで、グルームアーカイブは10件まで保存表示できます。めぐり内でのメッセージのやり取りと県外掲示板の閲覧には\(SubscriptionCatalog.currentPremiumDisplayName)が必要です。")
            }

            Section {
                SubscriptionStatusRow(state: state, isLoading: isLoading)
                if let purchaseMessage {
                    Label(purchaseMessage, systemImage: "checkmark.circle.fill")
                        .foregroundStyle(MegrumTheme.ok)
                }
                if let purchaseErrorMessage {
                    Label(purchaseErrorMessage, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(MegrumTheme.conditionPossible)
                }
            } header: {
                Text("現在の状態")
            }

            Section {
                if isPurchaseEnabled {
                    Button(action: onPurchase) {
                        Label(primaryButtonTitle, systemImage: "sparkles")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(state.isMegrumPlusActive || isPurchasing)
                    #if os(iOS)
                    .buttonStyle(.borderedProminent)
                    #endif

                    Button(action: onRestore) {
                        Label("購入を復元", systemImage: "arrow.clockwise")
                    }
                    .disabled(isPurchasing)
                } else {
                    Label("購入機能は公開準備中です", systemImage: "lock.fill")
                        .foregroundStyle(MegrumTheme.muted)
                }

                Button("状態を更新", action: onReload)
                    .disabled(isLoading || isPurchasing)
            } footer: {
                Text(purchaseFooterText)
            }

        }
    }

    @ViewBuilder
    private var debugPlanSection: some View {
        #if DEBUG
        if let onToggleDebugPlan {
            Section {
                DebugPlanToggleButton(
                    title: debugPlanButtonTitle,
                    isActive: state.isMegrumPlusActive,
                    action: onToggleDebugPlan
                )
                .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                .listRowBackground(Color.clear)
            } header: {
                Text("開発用")
            } footer: {
                Text("DEBUGビルドだけに表示される確認用の切り替えです。")
            }
        }
        #endif
    }

    private var primaryButtonTitle: String {
        if state.isMegrumPlusActive {
            return "利用中"
        }
        if !isPurchaseEnabled {
            return "準備中"
        }
        if isPurchasing {
            return "確認中"
        }
        return "\(offer.priceText)で始める"
    }

    private var purchaseFooterText: String {
        if isPurchaseEnabled {
            return "価格は月額500円です。App Storeのサブスクリプションとして更新・解約できます。"
        }
        return "購入と復元は、公開準備が整うまで停止しています。"
    }

    private var debugPlanButtonTitle: String {
        state.isMegrumPlusActive
            ? "開発用: 無料プランに戻す"
            : "開発用: プレミアムにする"
    }
}

private struct MegrumPlusHeroRow: View {
    var isActive: Bool
    var priceText: String
    var isLoadingOffer: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(MegrumTheme.lavender)
                    .frame(width: 52, height: 52)
                    .background(MegrumTheme.lavender.opacity(0.13), in: RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 5) {
                    Text(SubscriptionCatalog.currentPremiumDisplayName)
                        .font(.title3.bold())
                        .foregroundStyle(MegrumTheme.ink)
                    Text("交換相手に見つけてもらいやすく、めぐりの会話と保存を広げます。")
                        .font(.subheadline)
                        .foregroundStyle(MegrumTheme.muted)
                }
            }

            HStack {
                Text(isLoadingOffer ? "価格確認中" : priceText)
                    .font(.headline.bold())
                    .foregroundStyle(MegrumTheme.lavender)
                Spacer()
                Text(isActive ? "有効" : "未加入")
                    .font(.caption.bold())
                    .foregroundStyle(isActive ? MegrumTheme.ok : MegrumTheme.muted)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background((isActive ? MegrumTheme.ok : MegrumTheme.muted).opacity(0.12), in: Capsule())
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }
}

private struct MegrumPlusBenefitItem: Identifiable, Equatable {
    var id: MonetizationFeature
    var title: String
    var subtitle: String
    var systemImage: String

    static let defaultItems: [MegrumPlusBenefitItem] = [
        MegrumPlusBenefitItem(
            id: .unlimitedIndividualListings,
            title: "個別募集が無制限",
            subtitle: "無料プランの3件上限を外して、条件別に募集を作れます。",
            systemImage: "rectangle.stack.badge.plus"
        ),
        MegrumPlusBenefitItem(
            id: .priorityMatchDisplay,
            title: "ホーム・検索で上位表示",
            subtitle: "あなたの譲るグッズを見つけてもらいやすくします。",
            systemImage: "arrow.up.forward.circle.fill"
        ),
        MegrumPlusBenefitItem(
            id: .unlimitedGroomArchive,
            title: "グルームアーカイブ無制限",
            subtitle: "無料プランの10件上限を外して、過去のグルームを残せます。",
            systemImage: "archivebox.fill"
        ),
        MegrumPlusBenefitItem(
            id: .meguriMessageExpansion,
            title: "めぐり内でメッセージのやり取りが可能",
            subtitle: "届いた本文を読んで、そのまま相手とやり取りできます。",
            systemImage: "message.fill"
        ),
        MegrumPlusBenefitItem(
            id: .meguriBoardExtendedAccess,
            title: "県外の掲示板も閲覧可能",
            subtitle: "無料プランでは見られない県外のチャットルームも開けます。",
            systemImage: "map.fill"
        )
    ]
}

private struct MegrumPlusBenefitRow: View {
    var item: MegrumPlusBenefitItem

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.body.bold())
                    .foregroundStyle(MegrumTheme.ink)
                Text(item.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(MegrumTheme.muted)
            }
        } icon: {
            Image(systemName: item.systemImage)
                .foregroundStyle(MegrumTheme.lavender)
        }
        .padding(.vertical, 4)
    }
}

private struct SubscriptionStatusRow: View {
    var state: UserSubscriptionState
    var isLoading: Bool

    var body: some View {
        HStack {
            Label(statusTitle, systemImage: statusImage)
                .font(.body.bold())
                .foregroundStyle(MegrumTheme.ink)
            Spacer()
            if isLoading {
                ProgressView()
            } else {
                Text(state.isMegrumPlusActive ? "有効" : "無料")
                    .font(.caption.bold())
                    .foregroundStyle(state.isMegrumPlusActive ? MegrumTheme.ok : MegrumTheme.muted)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var statusTitle: String {
        state.isMegrumPlusActive ? SubscriptionCatalog.currentPremiumDisplayName : "無料プラン"
    }

    private var statusImage: String {
        state.isMegrumPlusActive ? "checkmark.seal.fill" : "person.crop.circle"
    }
}

#if DEBUG
private struct DebugPlanToggleButton: View {
    var title: String
    var isActive: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: isActive ? "person.crop.circle.badge.minus" : "switch.2")
                    .font(.system(size: 19, weight: .bold))
                Text(title)
                    .font(.body.weight(.heavy))
                Spacer(minLength: 0)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isActive ? MegrumTheme.ink : Color.blue)
            )
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityIdentifier("subscription-debug-plan-toggle-button")
    }
}
#endif
