import Foundation
import MegrumCore

enum GoodsSharePostKind {
    case inventory
    case wish
    case individualListing

    var promptTitle: String {
        switch self {
        case .inventory, .wish:
            "登録できました"
        case .individualListing:
            "募集を追加しました"
        }
    }

    var promptDescription: String {
        switch self {
        case .inventory:
            "登録した譲れるグッズをXで周知できます。"
        case .wish:
            "登録した欲しいものをXで周知できます。"
        case .individualListing:
            "求めるものと譲るものを画像にしてXで周知できます。"
        }
    }

    var shareButtonTitle: String {
        switch self {
        case .inventory:
            "Xで作成したマイグッズをポストする"
        case .wish:
            "Xで作成したほしいものをポストする"
        case .individualListing:
            "Xで個別募集をポストする"
        }
    }

    func imageTitle(displayName: String) -> String {
        switch self {
        case .inventory:
            "\(displayName)さんが登録した譲れるグッズ一覧"
        case .wish:
            "\(displayName)さんが欲しいものを登録しました"
        case .individualListing:
            "\(displayName)さんの個別募集"
        }
    }
}

struct GoodsSharePostContext: Identifiable {
    let id = UUID()
    var kind: GoodsSharePostKind
    var items: [GoodsItem]
    var displayName: String
    var listingSnapshot: IndividualListingShareSnapshot?
    var promptTitle: String
    var promptDescription: String
    var shareButtonTitle: String
    var postTextLeadingText: String?

    init(
        kind: GoodsSharePostKind,
        items: [GoodsItem],
        displayName: String,
        listingSnapshot: IndividualListingShareSnapshot? = nil,
        promptTitle: String? = nil,
        promptDescription: String? = nil,
        shareButtonTitle: String? = nil,
        postTextLeadingText: String? = nil
    ) {
        self.kind = kind
        self.items = items
        self.displayName = displayName
        self.listingSnapshot = listingSnapshot
        self.promptTitle = promptTitle ?? kind.promptTitle
        self.promptDescription = promptDescription ?? kind.promptDescription
        self.shareButtonTitle = shareButtonTitle ?? kind.shareButtonTitle
        self.postTextLeadingText = postTextLeadingText
    }

    var shareItems: [GoodsItem] {
        if let listingSnapshot {
            return Array(listingSnapshot.previewItems.prefix(20))
        }
        return Array(items.prefix(20))
    }
}
