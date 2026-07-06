import Foundation
import MegrumCore

enum SearchSuggestionAction: Hashable, Sendable {
    case group(UUID)
    case member(groupID: UUID, memberID: UUID)
    case wish(groupID: UUID?, memberID: UUID?, goodsTypeID: UUID?, tagNames: [String])
    case goodsType(UUID)
    case tag(String)
    case payment(UserPaymentMethod)
    case meetupPrefecture(String)
    case query(String)
    case listing(UUID)
}

struct SearchSuggestionItem: Identifiable, Equatable, Sendable {
    var id: String
    var title: String
    var subtitle: String?
    var imageURL: URL?
    var systemImageName: String?
    var action: SearchSuggestionAction

    init(
        id: String,
        title: String,
        subtitle: String? = nil,
        imageURL: URL? = nil,
        systemImageName: String? = nil,
        action: SearchSuggestionAction
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.imageURL = imageURL
        self.systemImageName = systemImageName
        self.action = action
    }
}

struct SearchSuggestionSection: Identifiable, Equatable, Sendable {
    var id: String
    var title: String
    var systemImageName: String
    var tintRole: SearchSuggestionTintRole
    var items: [SearchSuggestionItem]

    var isEmpty: Bool {
        items.isEmpty
    }
}

enum SearchSuggestionTintRole: Equatable, Sendable {
    case lavender
    case pink
    case muted
}
