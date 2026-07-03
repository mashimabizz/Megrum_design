import Foundation
import SwiftUI

struct GoodsTileActionPolicy: Equatable {
    var viewerID: UUID?
    var itemOwnerID: UUID
    var canAddToExchangeList: Bool
    var canCreateIndividualListing: Bool
    var canEdit: Bool
    var canHide: Bool
    var canDelete: Bool
    var canReport: Bool

    var actions: [GoodsTileAction] {
        guard let viewerID else {
            return [.detail]
        }

        if itemOwnerID == viewerID {
            var ownerActions: [GoodsTileAction] = [.detail]
            if canEdit {
                ownerActions.append(.edit)
            }
            if canCreateIndividualListing {
                ownerActions.append(.createIndividualListing)
            }
            if canHide {
                ownerActions.append(.hide)
            }
            if canDelete {
                ownerActions.append(.delete)
            }
            return ownerActions
        }

        var remoteActions: [GoodsTileAction] = [.detail]
        if canAddToExchangeList {
            remoteActions.append(.addToExchangeList)
        }
        if canReport {
            remoteActions.append(.report)
        }
        return remoteActions
    }
}

enum GoodsTileContextMenuPolicy {
    static func isEnabled(actions: [GoodsTileAction], hasLongPressSelection: Bool) -> Bool {
        !hasLongPressSelection && actions.count > 1
    }
}

struct GoodsGridPrimaryTapPolicy: Equatable {
    var isSelectionMode: Bool
    var canToggleSelection: Bool
    var canOpenItem: Bool
    var canOpenOwnerProfile: Bool
    var viewerID: UUID?
    var itemOwnerID: UUID

    var destination: GoodsGridPrimaryTapDestination {
        if isSelectionMode, canToggleSelection {
            return .toggleSelection
        }
        if canOpenItem {
            return .openItem
        }
        if canOpenOwnerProfile, Optional(itemOwnerID) != viewerID {
            return .openOwnerProfile(itemOwnerID)
        }
        return .showDetail
    }
}

enum GoodsGridPrimaryTapDestination: Equatable {
    case toggleSelection
    case openItem
    case openOwnerProfile(UUID)
    case showDetail
}

struct GoodsGridTileActionPolicy: Equatable {
    var viewerID: UUID?
    var itemOwnerID: UUID
    var itemTitle: String
    var canAddToExchangeList: Bool
    var canCreateIndividualListing: Bool
    var canEdit: Bool
    var canHide: Bool
    var canDelete: Bool
    var canReport: Bool

    func destination(for action: GoodsTileAction) -> GoodsGridTileActionDestination {
        switch action {
        case .detail:
            return .showDetail
        case .addToExchangeList:
            if canAddToExchangeList {
                return .addToExchangeList
            }
            return .showActionMessage("「\(itemTitle)」を交換リストに追加する処理は、打診フローのSwift化で接続します。")
        case .createIndividualListing:
            if canCreateIndividualListing {
                return .createIndividualListing
            }
            return .showActionMessage("「\(itemTitle)」から個別募集を作成する処理は、Wish画面で使えます。")
        case .edit:
            if itemOwnerID == viewerID, canEdit {
                return .edit
            }
            return .showActionMessage("「\(itemTitle)」の編集は、自分のマイグッズ/Wishでのみ使えます。")
        case .hide:
            if itemOwnerID == viewerID, canHide {
                return .hide
            }
            return .showActionMessage("「\(itemTitle)」を非表示にする処理は、自分のマイグッズ/Wishでのみ使えます。")
        case .report:
            if Optional(itemOwnerID) != viewerID, canReport {
                return .showReport
            }
            return .showActionMessage("「\(itemTitle)」の通報導線は、他のユーザーのグッズでのみ使えます。")
        case .delete:
            if itemOwnerID == viewerID, canDelete {
                return .delete
            }
            return .showActionMessage("「\(itemTitle)」を削除する処理は、自分のマイグッズ/Wishでのみ使えます。")
        }
    }
}

enum GoodsGridTileActionDestination: Equatable {
    case showDetail
    case addToExchangeList
    case createIndividualListing
    case edit
    case hide
    case showReport
    case delete
    case showActionMessage(String)
}

enum GoodsTileAction: CaseIterable, Identifiable, Equatable {
    case detail
    case addToExchangeList
    case createIndividualListing
    case edit
    case hide
    case report
    case delete

    static var visibleActions: [GoodsTileAction] {
        [.detail, .addToExchangeList, .edit, .hide, .report, .delete]
    }

    var id: String { title }

    var title: String {
        switch self {
        case .detail:
            "詳細を見る"
        case .addToExchangeList:
            "交換リストに追加"
        case .createIndividualListing:
            "これで個別募集する"
        case .edit:
            "編集"
        case .hide:
            "非表示にする"
        case .report:
            "通報する"
        case .delete:
            "削除する"
        }
    }

    var symbolName: String {
        switch self {
        case .detail:
            "info.circle"
        case .addToExchangeList:
            "plus.circle"
        case .createIndividualListing:
            "rectangle.stack.badge.plus"
        case .edit:
            "square.and.pencil"
        case .hide:
            "eye.slash"
        case .report:
            "exclamationmark.bubble"
        case .delete:
            "trash"
        }
    }

    var role: ButtonRole? {
        switch self {
        case .delete:
            .destructive
        case .detail, .addToExchangeList, .createIndividualListing, .edit, .hide, .report:
            nil
        }
    }

    var isDestructive: Bool {
        role == .destructive
    }
}
