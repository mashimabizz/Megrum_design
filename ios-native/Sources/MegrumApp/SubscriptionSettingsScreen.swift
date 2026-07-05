import MegrumCore
import MegrumDesign
import SwiftUI

struct SubscriptionSettingsScreen: View {
    @ObservedObject var appState: MegrumAppState
    var purchaseClient: any MegrumPlusPurchaseClient = StoreKitMegrumPlusPurchaseClient()
    var runtimeConfiguration: MegrumPlusRuntimeConfiguration = .current()
    var onClose: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    @State private var presentationState = SubscriptionSettingsPresentationState()
    @State private var selectedPlanID = SubscriptionCatalog.megrumPlusMonthlyProductID

    private var state: UserSubscriptionState {
        appState.subscriptionState
    }

    var body: some View {
        SubscriptionSettingsContent(
            state: state,
            isLoading: appState.isLoadingSubscriptionState,
            offer: presentationState.displayOffer(fallback: fallbackOffer),
            isLoadingOffer: presentationState.isLoadingOffer,
            isPurchasing: presentationState.isPurchasing,
            purchaseMessage: presentationState.purchaseMessage,
            purchaseErrorMessage: presentationState.purchaseErrorMessage,
            isPurchaseEnabled: runtimeConfiguration.isIAPEnabled,
            selectedPlanID: $selectedPlanID,
            onPurchase: purchase,
            onRestore: restore,
            onReload: reloadSubscriptionState,
            onToggleDebugPlan: toggleDebugPlan
        )
        .navigationTitle(SubscriptionCatalog.currentPremiumDisplayName)
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(action: closeScreen) {
                    Label("戻る", systemImage: "chevron.left")
                }
            }
        }
        .task {
            await appState.loadSubscriptionState(reportsFailure: false)
            await loadOffer()
        }
    }

    private var fallbackOffer: MegrumPlusPurchaseOffer {
        MegrumPlusPurchaseOffer(
            productID: SubscriptionCatalog.megrumPlusMonthlyProductID,
            displayName: SubscriptionCatalog.currentPremiumDisplayName,
            priceText: runtimeConfiguration.isIAPEnabled ? MegrumPlusLimits.monthlyPriceLabel : "準備中"
        )
    }

    private func reloadSubscriptionState() {
        Task {
            await appState.loadSubscriptionState()
        }
    }

    private func loadOffer() async {
        guard runtimeConfiguration.isIAPEnabled else {
            presentationState.setPurchaseMessage("購入機能は公開準備中です。")
            return
        }
        guard presentationState.beginLoadingOfferIfNeeded() else {
            return
        }
        do {
            let offer = try await purchaseClient.loadOffer(productID: SubscriptionCatalog.megrumPlusMonthlyProductID)
            presentationState.finishLoadingOffer(offer)
        } catch {
            presentationState.finishLoadingOffer(fallbackOffer)
        }
    }

    private func purchase() {
        let productID = selectedPlanID
        Task {
            await runPurchaseAction {
                try await purchaseClient.purchase(productID: productID)
            }
        }
    }

    private func restore() {
        Task {
            await runPurchaseAction {
                try await purchaseClient.restore(productID: SubscriptionCatalog.megrumPlusMonthlyProductID)
            }
        }
    }

    private func toggleDebugPlan() {
#if DEBUG
        appState.debugToggleMegrumPremiumEntitlement()
#endif
    }

    private func runPurchaseAction(_ action: @escaping () async throws -> MegrumPlusPurchaseOutcome) async {
        guard runtimeConfiguration.isIAPEnabled else {
            presentationState.setPurchaseErrorMessage("購入機能は公開準備中です。")
            return
        }
        guard presentationState.beginPurchaseAction() else {
            return
        }
        defer { presentationState.finishPurchaseAction() }

        do {
            let outcome = try await action()
            await handlePurchaseOutcome(outcome)
        } catch {
            presentationState.setPurchaseErrorMessage(
                (error as? LocalizedError)?.errorDescription ?? "購入状態を確認できませんでした。"
            )
        }
    }

    private func handlePurchaseOutcome(_ outcome: MegrumPlusPurchaseOutcome) async {
        switch outcome {
        case .purchased(let purchase), .restored(let purchase):
            do {
                try await appState.applyVerifiedMegrumPlusPurchase(purchase)
                presentationState.setPurchaseMessage("\(SubscriptionCatalog.currentPremiumDisplayName)が有効になりました。")
            } catch {
                presentationState.setPurchaseMessage("購入は確認できました。サーバー同期は次回起動時に再確認してください。")
            }
        case .pending:
            presentationState.setPurchaseMessage("購入の承認待ちです。完了後に復元してください。")
        case .cancelled:
            presentationState.setPurchaseMessage("購入をキャンセルしました。")
        case .unavailable:
            presentationState.setPurchaseErrorMessage("有効な\(SubscriptionCatalog.currentPremiumDisplayName)の購入が見つかりませんでした。")
        }
    }

    private func closeScreen() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }
}
