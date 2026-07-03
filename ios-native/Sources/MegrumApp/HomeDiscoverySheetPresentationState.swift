import Foundation

struct HomeDiscoverySheetPresentationState {
    var nestedPresentation: HomeDiscoveryNestedPresentation?
    var addedExtraSelections: [HomeDiscoveryProposalSelection] = []
    var wishCopyToastMessage: String?
    var wishCopyToastID = UUID()
    var copyingWishGoodsID: UUID?

    var addedExtraCandidateIDs: Set<UUID> {
        Set(addedExtraSelections.flatMap(\.receiverGoodsIDs))
    }

    var canStartWishCopy: Bool {
        copyingWishGoodsID == nil
    }

    mutating func showNestedSheet(_ sheet: HomeDiscoverySheet) {
        nestedPresentation = .discoverySheet(sheet)
    }

    mutating func showNestedProfile(_ route: PublicProfileRoute) {
        nestedPresentation = .publicProfile(route)
    }

    mutating func closeNestedPresentation() {
        nestedPresentation = nil
    }

    mutating func addExtraProposalSelectionAndDismiss(_ selection: HomeDiscoveryProposalSelection) {
        addedExtraSelections.append(selection)
        nestedPresentation = nil
    }

    func primaryProposalSelection(_ selection: HomeDiscoveryProposalSelection) -> HomeDiscoveryProposalSelection {
        selection.includingExtraSelections(addedExtraSelections)
    }

    mutating func beginWishCopy(goodsID: UUID) {
        copyingWishGoodsID = goodsID
    }

    mutating func finishWishCopy() {
        copyingWishGoodsID = nil
    }

    mutating func showWishCopyToast(_ message: String, toastID: UUID = UUID()) {
        wishCopyToastID = toastID
        wishCopyToastMessage = message
    }

    mutating func clearWishCopyToast(ifMatching toastID: UUID) {
        guard wishCopyToastID == toastID else {
            return
        }
        wishCopyToastMessage = nil
    }
}
