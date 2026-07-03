import MegrumCore
import Foundation

struct SearchResultGridPresentationState {
    var selectedSheet: HomeDiscoverySheet?
    var pendingProfileUserID: UUID?
    var reportTargetItem: GoodsItem?

    mutating func showSheet(_ sheet: HomeDiscoverySheet) {
        selectedSheet = sheet
    }

    mutating func requestProposalPresentation() {
        selectedSheet = nil
    }

    mutating func requestProfilePresentation(userID: UUID) {
        pendingProfileUserID = userID
        selectedSheet = nil
    }

    mutating func consumePendingProfileUserID() -> UUID? {
        guard let pendingProfileUserID else {
            return nil
        }
        self.pendingProfileUserID = nil
        return pendingProfileUserID
    }

    mutating func showReport(item: GoodsItem) {
        reportTargetItem = item
    }

    mutating func clearReport() {
        reportTargetItem = nil
    }
}
