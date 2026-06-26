import MegrumCore
import MegrumDesign
import SwiftUI

struct SubscriptionSettingsScreen: View {
    @ObservedObject var appState: MegrumAppState
    var purchaseClient: any MegrumPlusPurchaseClient = StoreKitMegrumPlusPurchaseClient()

    @State private var offer: MegrumPlusPurchaseOffer?
    @State private var isLoadingOffer = false
    @State private var isPurchasing = false
    @State private var purchaseMessage: String?
    @State private var purchaseErrorMessage: String?

    private var state: UserSubscriptionState {
        appState.subscriptionState
    }

    var body: some View {
        SubscriptionSettingsContent(
            state: state,
            isLoading: appState.isLoadingSubscriptionState,
            offer: offer ?? fallbackOffer,
            isLoadingOffer: isLoadingOffer,
            isPurchasing: isPurchasing,
            purchaseMessage: purchaseMessage,
            purchaseErrorMessage: purchaseErrorMessage,
            onPurchase: purchase,
            onRestore: restore,
            onReload: reloadSubscriptionState
        )
        .navigationTitle("メグルムプラス")
        .megrumInlineNavigationTitle()
        .task {
            await appState.loadSubscriptionState(reportsFailure: false)
            await loadOffer()
        }
    }

    private var fallbackOffer: MegrumPlusPurchaseOffer {
        MegrumPlusPurchaseOffer(
            productID: SubscriptionCatalog.megrumPlusMonthlyProductID,
            displayName: "メグルムプラス",
            priceText: MegrumPlusLimits.monthlyPriceLabel
        )
    }

    private func reloadSubscriptionState() {
        Task {
            await appState.loadSubscriptionState()
        }
    }

    private func loadOffer() async {
        guard offer == nil, !isLoadingOffer else {
            return
        }
        isLoadingOffer = true
        defer { isLoadingOffer = false }
        do {
            offer = try await purchaseClient.loadOffer(productID: SubscriptionCatalog.megrumPlusMonthlyProductID)
        } catch {
            offer = fallbackOffer
        }
    }

    private func purchase() {
        Task {
            await runPurchaseAction {
                try await purchaseClient.purchase(productID: SubscriptionCatalog.megrumPlusMonthlyProductID)
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

    private func runPurchaseAction(_ action: @escaping () async throws -> MegrumPlusPurchaseOutcome) async {
        guard !isPurchasing else {
            return
        }
        isPurchasing = true
        purchaseMessage = nil
        purchaseErrorMessage = nil
        defer { isPurchasing = false }

        do {
            let outcome = try await action()
            await handlePurchaseOutcome(outcome)
        } catch {
            purchaseErrorMessage = (error as? LocalizedError)?.errorDescription ?? "購入状態を確認できませんでした。"
        }
    }

    private func handlePurchaseOutcome(_ outcome: MegrumPlusPurchaseOutcome) async {
        switch outcome {
        case .purchased(let purchase), .restored(let purchase):
            do {
                try await appState.applyVerifiedMegrumPlusPurchase(purchase)
                purchaseMessage = "メグルムプラスが有効になりました。"
            } catch {
                purchaseMessage = "購入は確認できました。サーバー同期は次回起動時に再確認してください。"
            }
        case .pending:
            purchaseMessage = "購入の承認待ちです。完了後に復元してください。"
        case .cancelled:
            purchaseMessage = "購入をキャンセルしました。"
        case .unavailable:
            purchaseErrorMessage = "有効なメグルムプラスの購入が見つかりませんでした。"
        }
    }
}
