import SwiftUI

struct HomeMutualMatchNestedPresentationModifier: ViewModifier {
    @Binding var nestedPresentation: HomeDiscoveryNestedPresentation?
    var appState: MegrumAppState?
    var viewerOfferGoods: [HomeMockGoods]
    var onAddExtraProposalSelection: (HomeDiscoveryProposalSelection) -> Void
    var onOpenOwnerProfile: (UUID) -> Void
    var onStartProposal: (HomeDiscoveryProposalSelection) -> Void

    func body(content: Content) -> some View {
        content.sheet(item: $nestedPresentation) { presentation in
            switch presentation {
            case .discoverySheet(let sheet):
                HomeDiscoverySheetView(
                    sheet: sheet,
                    appState: appState,
                    viewerOfferGoods: viewerOfferGoods,
                    presentationContext: .additionalCandidate,
                    onClose: {
                        nestedPresentation = nil
                    },
                    onAddExtraProposalSelection: onAddExtraProposalSelection,
                    onOpenOwnerProfile: onOpenOwnerProfile,
                    onStartProposal: onStartProposal
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            case .publicProfile(let route):
                if let appState {
                    NavigationStack {
                        PublicUserProfileScreen(
                            appState: appState,
                            userID: route.userID,
                            presentationContext: .stackedFromHomeDiscoverySheet
                        )
                    }
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                }
            }
        }
    }
}
