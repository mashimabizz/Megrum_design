import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct HomeDiscoverySheetView: View {
    var sheet: HomeDiscoverySheet
    var appState: MegrumAppState?
    var viewerOfferGoods: [HomeMockGoods] = []
    var presentationContext: HomeDiscoverySheetPresentationContext = .primary
    var onClose: (() -> Void)? = nil
    var onAddExtraCandidate: (HomeExtraHitPayload) -> Void = { _ in }
    var onAddExtraProposalSelection: (HomeDiscoveryProposalSelection) -> Void = { _ in }
    var onOpenOwnerProfile: (UUID) -> Void = { _ in }
    var onStartProposal: (HomeDiscoveryProposalSelection) -> Void = { _ in }
    @State private var presentationState = HomeDiscoverySheetPresentationState()

    var body: some View {
        HomeDiscoverySheetContent(
            sheet: sheet,
            viewerOfferGoods: viewerOfferGoods,
            addedExtraCandidateIDs: addedExtraCandidateIDs,
            presentationContext: presentationContext,
            copyingWishGoodsID: presentationState.copyingWishGoodsID,
            onClose: onClose,
            onOpenOwnerProfile: openOwnerProfile,
            onOpenNestedSheet: { presentationState.showNestedSheet($0) },
            onStartProposal: submitSelection,
            onCopyToWish: copyGoodsToWish
        )
            .overlay(alignment: .bottom) {
                if let wishCopyToastMessage = presentationState.wishCopyToastMessage {
                    MeguriToastView(message: wishCopyToastMessage)
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.32, dampingFraction: 0.88), value: presentationState.wishCopyToastMessage)
            .sheet(item: $presentationState.nestedPresentation) { presentation in
                switch presentation {
                case .discoverySheet(let sheet):
                    HomeDiscoverySheetView(
                        sheet: sheet,
                        appState: appState,
                        viewerOfferGoods: viewerOfferGoods,
                        presentationContext: .additionalCandidate,
                        onClose: {
                            presentationState.closeNestedPresentation()
                        },
                        onAddExtraCandidate: onAddExtraCandidate,
                        onAddExtraProposalSelection: { selection in
                            presentationState.addExtraProposalSelectionAndDismiss(selection)
                        },
                        onOpenOwnerProfile: onOpenOwnerProfile,
                        onStartProposal: submitSelection
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

    private var addedExtraCandidateIDs: Set<UUID> {
        presentationState.addedExtraCandidateIDs
    }

    private func submitSelection(_ selection: HomeDiscoveryProposalSelection) {
        switch presentationContext {
        case .primary:
            onStartProposal(presentationState.primaryProposalSelection(selection))
        case .additionalCandidate:
            onAddExtraProposalSelection(selection)
        }
    }

    private func openOwnerProfile(_ userID: UUID) {
        switch HomeDiscoveryOwnerProfileRoutingPolicy.decision(
            for: userID,
            canPresentNestedProfile: appState != nil
        ) {
        case .nested(let route):
            presentationState.showNestedProfile(route)
        case .parent(let userID):
            onOpenOwnerProfile(userID)
        }
    }

    private func copyGoodsToWish(_ goods: HomeMockGoods) {
        guard presentationState.canStartWishCopy else {
            return
        }
        guard let appState else {
            showWishCopyToast(HomeWishCopyInputBuilder.failureToastMessage)
            return
        }

        presentationState.beginWishCopy(goodsID: goods.id)
        Task { @MainActor in
            if appState.oshiGroups.isEmpty {
                await appState.loadOshiGroups()
            }
            if appState.goodsTypes.isEmpty {
                await appState.loadGoodsTypes()
            }
            guard let input = HomeWishCopyInputBuilder.input(
                from: goods,
                groups: appState.oshiGroups,
                goodsTypes: appState.goodsTypes
            ) else {
                presentationState.finishWishCopy()
                showWishCopyToast(HomeWishCopyInputBuilder.failureToastMessage)
                return
            }

            let saved = await appState.createGoodsEntry(input)
            presentationState.finishWishCopy()
            showWishCopyToast(
                saved
                    ? HomeWishCopyInputBuilder.successToastMessage
                    : HomeWishCopyInputBuilder.failureToastMessage
            )
        }
    }

    private func showWishCopyToast(_ message: String) {
        let toastID = UUID()
        withAnimation {
            presentationState.showWishCopyToast(message, toastID: toastID)
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation {
                presentationState.clearWishCopyToast(ifMatching: toastID)
            }
        }
    }
}

enum HomeDiscoverySheetPresentationContext: Equatable {
    case primary
    case additionalCandidate

    var showsOtherExchangeRows: Bool {
        self == .primary
    }

    var bottomButtonTitle: String {
        switch self {
        case .primary:
            return "交換内容を確認する"
        case .additionalCandidate:
            return "このグッズも追加する"
        }
    }

    var preselectPreferredOffer: Bool {
        self == .primary
    }
}
