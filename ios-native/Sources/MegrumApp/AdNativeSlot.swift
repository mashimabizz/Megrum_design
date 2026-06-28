import SwiftUI

struct AdNativeSlot: View {
    var placement: AdPlacement
    var displayContext: AdDisplayContext
    var configuration: AdRuntimeConfiguration = .current()
    var presentation: AdNativePresentation = .standard

    @State private var loadState: AdMobNativeLoadState = .loading

    private var decision: AdDisplayDecision {
        AdDisplayPolicy.decision(
            for: placement,
            context: displayContext,
            configuration: configuration
        )
    }

    var body: some View {
        Group {
            if decision.isAllowed {
                if decision.usesPlaceholder {
                    AdNativePlaceholder(placement: placement, presentation: presentation)
                } else {
                    adMobNativeCard
                }
            }
        }
        .onChange(of: decision.unitID) { _, _ in
            loadState = .loading
        }
    }

    @ViewBuilder
    private var adMobNativeCard: some View {
        #if os(iOS) && canImport(GoogleMobileAds)
        if let unitID = decision.unitID, loadState != .failed {
            AdMobNativeCardView(
                unitID: unitID,
                presentation: presentation,
                loadState: $loadState
            )
                .frame(maxWidth: .infinity)
                .frame(height: nativeCardHeight)
                .clipped()
                .accessibilityLabel("広告")
        }
        #endif
    }

    private var nativeCardHeight: CGFloat {
        guard loadState == .loaded else {
            return 0
        }
        return presentation.cardHeight
    }
}
