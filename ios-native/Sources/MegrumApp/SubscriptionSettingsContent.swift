import MegrumCore
import MegrumDesign
import SwiftUI

/// Megrumプレミアム案内（iter1226.296 リッチ化）。
/// グラデヒーロー＋無料プランとの○×比較表＋期間プラン選択（1/2/3/6/12ヶ月）。
struct SubscriptionSettingsContent: View {
    var state: UserSubscriptionState
    var isLoading: Bool
    var offer: MegrumPlusPurchaseOffer
    var isLoadingOffer: Bool
    var isPurchasing: Bool
    var purchaseMessage: String?
    var purchaseErrorMessage: String?
    var isPurchaseEnabled: Bool
    @Binding var selectedPlanID: String
    var onPurchase: () -> Void
    var onRestore: () -> Void
    var onReload: () -> Void
    var onToggleDebugPlan: (() -> Void)? = nil

    private var selectedPlan: SubscriptionPremiumPlan {
        SubscriptionPremiumPlanCatalog.plan(for: selectedPlanID)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                SubscriptionPremiumHero(isActive: state.isMegrumPlusActive)

                SubscriptionComparisonTable()

                SubscriptionPlanPicker(
                    selectedPlanID: $selectedPlanID,
                    monthlyOfferPriceText: isLoadingOffer ? nil : offer.priceText,
                    isPurchaseEnabled: isPurchaseEnabled
                )

                statusAndMessages

                purchaseButtons

                debugPlanSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 40)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
    }

    private var statusAndMessages: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(
                    state.isMegrumPlusActive ? SubscriptionCatalog.currentPremiumDisplayName : "現在は無料プラン",
                    systemImage: state.isMegrumPlusActive ? "checkmark.seal.fill" : "person.crop.circle"
                )
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                Spacer()
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text(state.isMegrumPlusActive ? "有効" : "未加入")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(state.isMegrumPlusActive ? MegrumTheme.ok : MegrumTheme.muted)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            (state.isMegrumPlusActive ? MegrumTheme.ok : MegrumTheme.muted).opacity(0.12),
                            in: Capsule()
                        )
                }
            }

            if let purchaseMessage {
                Label(purchaseMessage, systemImage: "checkmark.circle.fill")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.ok)
            }
            if let purchaseErrorMessage {
                Label(purchaseErrorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.conditionPossible)
            }
        }
        .padding(14)
        .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var purchaseButtons: some View {
        VStack(spacing: 12) {
            if isPurchaseEnabled {
                Button(action: onPurchase) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .black))
                        Text(primaryButtonTitle)
                            .font(.system(size: 17, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [MegrumTheme.sky, MegrumTheme.lavender, MegrumTheme.pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(.white.opacity(0.4), lineWidth: 1)
                    }
                    .shadow(color: MegrumTheme.lavender.opacity(0.3), radius: 14, y: 7)
                }
                .buttonStyle(.plain)
                .disabled(state.isMegrumPlusActive || isPurchasing)
                .opacity(state.isMegrumPlusActive || isPurchasing ? 0.6 : 1)

                HStack(spacing: 18) {
                    Button("購入を復元", action: onRestore)
                        .disabled(isPurchasing)
                    Button("状態を更新", action: onReload)
                        .disabled(isLoading || isPurchasing)
                }
                .font(.system(size: 13.5, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(maxWidth: .infinity)
            } else {
                Label("購入機能は公開準備中です", systemImage: "lock.fill")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .frame(maxWidth: .infinity)

                Button("状態を更新", action: onReload)
                    .font(.system(size: 13.5, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .disabled(isLoading || isPurchasing)
            }

            Text(purchaseFooterText)
                .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var debugPlanSection: some View {
        #if DEBUG
        if let onToggleDebugPlan {
            DebugPlanToggleButton(
                title: debugPlanButtonTitle,
                isActive: state.isMegrumPlusActive,
                action: onToggleDebugPlan
            )
        }
        #endif
    }

    private var primaryButtonTitle: String {
        if state.isMegrumPlusActive {
            return "利用中"
        }
        if isPurchasing {
            return "確認中"
        }
        return "\(selectedPlan.title)プランで始める"
    }

    private var purchaseFooterText: String {
        if isPurchaseEnabled {
            return "App Storeのサブスクリプションとして自動更新されます。いつでも解約できます。"
        }
        return "購入と復元は、公開準備が整うまで停止しています。"
    }

    private var debugPlanButtonTitle: String {
        state.isMegrumPlusActive
            ? "開発用: 無料プランに戻す"
            : "開発用: プレミアムにする"
    }
}

/// ヒーロー：ブランドグラデの案内カード。
private struct SubscriptionPremiumHero: View {
    var isActive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 26, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(.white.opacity(0.22), in: RoundedRectangle(cornerRadius: 15, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(SubscriptionCatalog.currentPremiumDisplayName)
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("推し活の交換を、もっと速く・もっと広く")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }

            HStack(spacing: 6) {
                ForEach(["上位表示", "募集無制限", "めぐり解放"], id: \.self) { chip in
                    Text(chip)
                        .font(.system(size: 11.5, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.white.opacity(0.94), in: Capsule())
                }
                Spacer()
                if isActive {
                    Label("利用中", systemImage: "checkmark.seal.fill")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [MegrumTheme.sky, MegrumTheme.lavender, MegrumTheme.pink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.42), lineWidth: 1)
        }
        .shadow(color: MegrumTheme.lavender.opacity(0.28), radius: 18, y: 9)
    }
}

/// 無料プランとの○×比較表。
private struct SubscriptionComparisonTable: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("できること")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("無料")
                    .frame(width: 74)
                Text("プレミアム")
                    .frame(width: 84)
                    .foregroundStyle(MegrumTheme.lavender)
            }
            .font(.system(size: 12, weight: .black, design: .rounded))
            .foregroundStyle(MegrumTheme.muted)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(MegrumTheme.lavender.opacity(0.07))

            ForEach(Array(SubscriptionComparisonRow.rows.enumerated()), id: \.element.id) { index, row in
                HStack(spacing: 8) {
                    Image(systemName: row.systemImage)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(MegrumTheme.lavender)
                        .frame(width: 20)
                    Text(row.title)
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    comparisonCell(text: row.freeText, isAvailable: row.freeIsAvailable, isPremiumColumn: false)
                        .frame(width: 74)
                    comparisonCell(text: row.premiumText, isAvailable: true, isPremiumColumn: true)
                        .frame(width: 84)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(index.isMultiple(of: 2) ? Color.white.opacity(0.9) : MegrumTheme.canvas)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(MegrumTheme.lavender.opacity(0.16), lineWidth: 1)
        }
    }

    private func comparisonCell(text: String, isAvailable: Bool, isPremiumColumn: Bool) -> some View {
        Group {
            if text == "○" {
                Image(systemName: "circle")
                    .font(.system(size: 13, weight: .black))
            } else if text == "×" {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .black))
            } else {
                Text(text)
                    .font(.system(size: 11.5, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .foregroundStyle(
            isPremiumColumn
                ? MegrumTheme.lavender
                : (isAvailable ? MegrumTheme.ink.opacity(0.68) : MegrumTheme.muted.opacity(0.55))
        )
    }
}

/// 期間プランの選択（1ヶ月・2ヶ月・3ヶ月・半年・1年）。
private struct SubscriptionPlanPicker: View {
    @Binding var selectedPlanID: String
    var monthlyOfferPriceText: String?
    var isPurchaseEnabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("プランを選ぶ")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            ForEach(SubscriptionPremiumPlanCatalog.plans) { plan in
                planCard(plan)
            }
        }
    }

    private func planCard(_ plan: SubscriptionPremiumPlan) -> some View {
        let isSelected = plan.productID == selectedPlanID
        return Button {
            MegrumHaptics.performSelectionChanged {
                selectedPlanID = plan.productID
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(isSelected ? MegrumTheme.lavender : MegrumTheme.muted.opacity(0.5))

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text("\(plan.title)プラン")
                            .font(.system(size: 15.5, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink)
                        if let badge = plan.badge {
                            Text(badge)
                                .font(.system(size: 10.5, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(
                                    LinearGradient(
                                        colors: [MegrumTheme.pink, Color(red: 0.94, green: 0.35, blue: 0.55)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    in: Capsule()
                                )
                        }
                    }
                    Text(plan.perMonthText)
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }

                Spacer(minLength: 8)

                Text(displayPrice(for: plan))
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(isSelected ? MegrumTheme.lavender : MegrumTheme.ink.opacity(0.8))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(.white.opacity(isSelected ? 0.98 : 0.82), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        isSelected ? MegrumTheme.lavender : MegrumTheme.ink.opacity(0.08),
                        lineWidth: isSelected ? 1.8 : 1
                    )
            }
            .shadow(color: isSelected ? MegrumTheme.lavender.opacity(0.16) : .clear, radius: 10, y: 5)
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(plan.title)プラン \(displayPrice(for: plan))")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func displayPrice(for plan: SubscriptionPremiumPlan) -> String {
        if plan.months == 1, let monthlyOfferPriceText, isPurchaseEnabled {
            return monthlyOfferPriceText
        }
        return plan.fallbackPriceText
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
