import Foundation
import MegrumCore

enum GoodsEditorMode: String, CaseIterable, Identifiable {
    case create
    case edit
    case readonly

    var id: String { rawValue }

    var badgeTitle: String {
        switch self {
        case .create:
            "NEW"
        case .edit:
            "更新"
        case .readonly:
            "詳細のみ"
        }
    }
}

enum GoodsEditorRoute: Identifiable {
    case create(GoodsEntryKind)
    case edit(GoodsItem, GoodsEntryKind)

    var id: String {
        switch self {
        case let .create(kind):
            "create-\(kind.rawValue)"
        case let .edit(item, kind):
            "edit-\(kind.rawValue)-\(item.id.uuidString)"
        }
    }

    var mode: GoodsEditorMode {
        switch self {
        case .create:
            .create
        case .edit:
            .edit
        }
    }

    var kind: GoodsEntryKind {
        switch self {
        case let .create(kind), let .edit(_, kind):
            kind
        }
    }

    var item: GoodsItem? {
        switch self {
        case .create:
            nil
        case let .edit(item, _):
            item
        }
    }
}

enum GoodsCreateStep: String, CaseIterable, Identifiable, Equatable {
    case common
    case shoot
    case meta

    var id: String { rawValue }

    var title: String {
        switch self {
        case .common:
            "共通条件"
        case .shoot:
            "写真"
        case .meta:
            "詳細"
        }
    }

    var index: Int {
        Self.allCases.firstIndex(of: self).map { $0 + 1 } ?? 1
    }
}

enum GoodsEditorStatus: String, CaseIterable, Identifiable, Equatable {
    case forTrade = "for_trade"
    case keep
    case traded
    case wishActive = "active"
    case wishAchieved = "achieved"

    var id: String { rawValue }

    static func defaultStatus(for kind: GoodsEntryKind) -> GoodsEditorStatus {
        kind == .inventory ? .forTrade : .wishActive
    }

    static func options(for kind: GoodsEntryKind) -> [GoodsEditorStatus] {
        switch kind {
        case .inventory:
            [.forTrade, .keep, .traded]
        case .wish:
            [.wishActive, .wishAchieved]
        }
    }

    func isValid(for kind: GoodsEntryKind) -> Bool {
        Self.options(for: kind).contains(self)
    }

    var title: String {
        switch self {
        case .forTrade:
            "譲る候補"
        case .keep:
            "自分用キープ"
        case .traded:
            "過去に譲った"
        case .wishActive:
            "探し中"
        case .wishAchieved:
            "入手済み"
        }
    }

    var systemImage: String {
        switch self {
        case .forTrade:
            "arrow.left.arrow.right.circle"
        case .keep:
            "archivebox"
        case .traded:
            "checkmark.seal"
        case .wishActive:
            "heart"
        case .wishAchieved:
            "checkmark.seal"
        }
    }

    var persistedStatus: GoodsEntryStatus {
        switch self {
        case .forTrade, .wishActive:
            .active
        case .keep:
            .keep
        case .traded:
            .traded
        case .wishAchieved:
            .archived
        }
    }

    init(entryKind: GoodsEntryKind, persistedStatus: GoodsEntryStatus?) {
        switch entryKind {
        case .inventory:
            switch persistedStatus {
            case .keep:
                self = .keep
            case .traded:
                self = .traded
            case .active, .reserved, .archived, nil:
                self = .forTrade
            }
        case .wish:
            switch persistedStatus {
            case .archived, .traded:
                self = .wishAchieved
            case .active, .keep, .reserved, nil:
                self = .wishActive
            }
        }
    }
}

enum GoodsEditorSaveBlocker: Equatable, Identifiable {
    case tagPersistence
    case photoPersistence

    var id: String {
        switch self {
        case .tagPersistence:
            "tags"
        case .photoPersistence:
            "photo"
        }
    }

    var title: String {
        switch self {
        case .tagPersistence:
            "グッズシリーズ保存が未接続"
        case .photoPersistence:
            "写真アップロード保存が未接続"
        }
    }

    var message: String {
        switch self {
        case .tagPersistence:
            "`goods_inventory_tags` の読み書き境界がSwift Native側に未追加です。"
        case .photoPersistence:
            "`photo_urls` とStorage uploadを保存する境界が未追加です。"
        }
    }
}

struct GoodsEditorSaveFailure: Equatable, Identifiable {
    var appMessage: String
    var includesPhotoUpload: Bool
    var includesTagChanges: Bool

    var id: String {
        [appMessage, includesPhotoUpload.description, includesTagChanges.description].joined(separator: "-")
    }

    var title: String {
        "保存できませんでした"
    }

    var message: String {
        var lines = [appMessage]
        if includesPhotoUpload {
            lines.append("写真アップロードで失敗した可能性があります。写真を外して保存するか、通信状況を確認して再試行できます。")
        }
        if includesTagChanges {
            lines.append("シリーズ保存で失敗した可能性があります。シリーズは画面に残っているので、必要なら削除してもう一度試せます。")
        }
        lines.append("入力内容はこの画面に残しています。")
        return lines.joined(separator: "\n\n")
    }

    static func make(draft: GoodsEditorDraft, appMessage: String?) -> GoodsEditorSaveFailure {
        let fallbackMessage = "通信状況を確認してからもう一度お試しください。"
        return GoodsEditorSaveFailure(
            appMessage: appMessage.nilIfBlank ?? fallbackMessage,
            includesPhotoUpload: draft.hasUnsavedLocalPhoto,
            includesTagChanges: draft.hasTagChanges
        )
    }
}
