import Foundation
import MegrumCore
import SwiftUI

enum OshiMasterSelectLayoutMetrics {
    static let candidateTagMinimumWidth: CGFloat = 44
    static let candidateTagMinHeight: CGFloat = 44
    static let candidateTagHorizontalPadding: CGFloat = 12
    static let candidateTagSpacing: CGFloat = 8
    static let candidateTagRowSpacing: CGFloat = 8
    static let registerButtonHeight: CGFloat = 54
    static let genreSegmentHeight: CGFloat = 38
    static let genreSegmentMinWidth: CGFloat = 72
    static let searchHeight: CGFloat = 54
    static let bottomContentPadding: CGFloat = 132
    static let selectedActionExtraPadding: CGFloat = 74
}

enum OshiRequestSheetLayoutMetrics {
    static let submitButtonHeight: CGFloat = 58
    static let scrollBottomPadding: CGFloat = 104
}

struct OshiCategoryOption: Identifiable {
    var id: UUID?
    var title: String
}

enum OshiRequestSheetState: Identifiable, Hashable {
    case oshi(initialName: String?)
    case member(OshiMemberRequestContext)

    var id: String {
        switch self {
        case .oshi(let initialName):
            "oshi:\(initialName ?? "")"
        case .member(let context):
            "member:\(context.id)"
        }
    }

    var initialName: String? {
        if case .oshi(let initialName) = self {
            return initialName
        }
        return nil
    }
}

struct OshiRequestSheetPayload {
    var name: String
    var note: String?
    var kind: OshiRequestKind
    var genreID: UUID?
}

struct OshiMemberRequestSheetPayload {
    var name: String
    var note: String?
}
