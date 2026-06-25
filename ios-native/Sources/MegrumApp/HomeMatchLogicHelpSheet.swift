import MegrumDesign
import SwiftUI

struct HomeMatchLogicHelpSheet: View {
    var exchangeSettings: HomeDefaultExchangeSettings
    var onOpenWish: () -> Void
    var onOpenIndividualListings: () -> Void
    var onOpenExchangeSettings: () -> Void
    var onOpenPaymentSettings: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            HomeMatchLogicHelpContent(
                exchangeSettings: exchangeSettings,
                onOpenWish: openWish,
                onOpenIndividualListings: openIndividualListings,
                onOpenExchangeSettings: openExchangeSettings,
                onOpenPaymentSettings: openPaymentSettings
            )
            .navigationTitle("相互マッチの見方")
            .megrumInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる", action: dismiss.callAsFunction)
                }
            }
        }
    }

    private func openWish() {
        dismiss()
        onOpenWish()
    }

    private func openIndividualListings() {
        dismiss()
        onOpenIndividualListings()
    }

    private func openExchangeSettings() {
        dismiss()
        onOpenExchangeSettings()
    }

    private func openPaymentSettings() {
        dismiss()
        onOpenPaymentSettings()
    }
}
