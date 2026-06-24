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
