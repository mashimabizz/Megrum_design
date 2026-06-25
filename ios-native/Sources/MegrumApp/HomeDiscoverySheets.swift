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
    @State private var nestedPresentation: HomeDiscoveryNestedPresentation?
    @State private var addedExtraSelections: [HomeDiscoveryProposalSelection] = []
    @State private var wishCopyToastMessage: String?
    @State private var wishCopyToastID = UUID()
    @State private var copyingWishGoodsID: UUID?

    var body: some View {
        HomeDiscoverySheetContent(
            sheet: sheet,
            viewerOfferGoods: viewerOfferGoods,
            addedExtraCandidateIDs: addedExtraCandidateIDs,
            presentationContext: presentationContext,
            copyingWishGoodsID: copyingWishGoodsID,
            onClose: onClose,
            onOpenOwnerProfile: openOwnerProfile,
            onOpenNestedSheet: { nestedPresentation = .discoverySheet($0) },
            onStartProposal: submitSelection,
            onCopyToWish: copyGoodsToWish
        )
            .overlay(alignment: .bottom) {
                if let wishCopyToastMessage {
                    MeguriToastView(message: wishCopyToastMessage)
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.32, dampingFraction: 0.88), value: wishCopyToastMessage)
            .sheet(item: $nestedPresentation) { presentation in
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
                        onAddExtraCandidate: onAddExtraCandidate,
                        onAddExtraProposalSelection: { selection in
                            addedExtraSelections.append(selection)
                            nestedPresentation = nil
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
        Set(addedExtraSelections.flatMap(\.receiverGoodsIDs))
    }

    private func submitSelection(_ selection: HomeDiscoveryProposalSelection) {
        switch presentationContext {
        case .primary:
            onStartProposal(selection.includingExtraSelections(addedExtraSelections))
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
            nestedPresentation = .publicProfile(route)
        case .parent(let userID):
            onOpenOwnerProfile(userID)
        }
    }

    private func copyGoodsToWish(_ goods: HomeMockGoods) {
        guard copyingWishGoodsID == nil else {
            return
        }
        guard let appState else {
            showWishCopyToast(HomeWishCopyInputBuilder.failureToastMessage)
            return
        }

        copyingWishGoodsID = goods.id
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
                copyingWishGoodsID = nil
                showWishCopyToast(HomeWishCopyInputBuilder.failureToastMessage)
                return
            }

            let saved = await appState.createGoodsEntry(input)
            copyingWishGoodsID = nil
            showWishCopyToast(
                saved
                    ? HomeWishCopyInputBuilder.successToastMessage
                    : HomeWishCopyInputBuilder.failureToastMessage
            )
        }
    }

    private func showWishCopyToast(_ message: String) {
        let toastID = UUID()
        wishCopyToastID = toastID
        withAnimation {
            wishCopyToastMessage = message
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard wishCopyToastID == toastID else {
                return
            }
            withAnimation {
                wishCopyToastMessage = nil
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
