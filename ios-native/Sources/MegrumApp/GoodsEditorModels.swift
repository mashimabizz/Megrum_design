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

struct GoodsCreatePhotoDraft: Identifiable, Equatable {
    var id: UUID
    var upload: GoodsPhotoUpload

    init(id: UUID = UUID(), upload: GoodsPhotoUpload) {
        self.id = id
        self.upload = upload
    }
}

struct GoodsCreateMetaDraft: Identifiable, Equatable {
    var id: UUID
    var photoID: UUID?
    var memberID: UUID?
    var title: String
    var quantity: Int

    init(id: UUID = UUID(), photoID: UUID? = nil, memberID: UUID? = nil, title: String = "", quantity: Int = 1) {
        self.id = id
        self.photoID = photoID
        self.memberID = memberID
        self.title = title
        self.quantity = quantity
    }

    var normalizedQuantity: Int {
        max(1, min(quantity, 999))
    }

    func resolvedTitle(groupName: String?, memberName: String?, goodsTypeName: String?) -> String {
        if let trimmedTitle = title.nilIfBlank {
            return trimmedTitle
        }
        return [memberName, groupName, goodsTypeName]
            .compactMap(\.nilIfBlank)
            .joined(separator: " ")
    }

    func createInput(
        sharedDraft: GoodsEditorDraft,
        photoUpload: GoodsPhotoUpload?,
        groupName: String?,
        memberName: String?,
        goodsTypeName: String?
    ) -> GoodsEntryInput? {
        guard sharedDraft.mode == .create,
              sharedDraft.entryKind == .inventory,
              sharedDraft.blockingReasons.isEmpty,
              let groupID = sharedDraft.groupID,
              let goodsTypeID = sharedDraft.goodsTypeID
        else {
            return nil
        }
        let resolved = resolvedTitle(groupName: groupName, memberName: memberName, goodsTypeName: goodsTypeName)
        guard !resolved.isEmpty else {
            return nil
        }
        return GoodsEntryInput(
            kind: .inventory,
            title: resolved,
            groupID: groupID,
            memberID: memberID,
            goodsTypeID: goodsTypeID,
            quantity: normalizedQuantity,
            status: sharedDraft.status.persistedStatus,
            tagNames: sharedDraft.tagNames,
            photoUpload: photoUpload
        )
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
            "グッズタグ保存が未接続"
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
            lines.append("タグ保存で失敗した可能性があります。タグは画面に残っているので、必要なら削除してもう一度試せます。")
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

struct GoodsEditorDraft: Equatable {
    var mode: GoodsEditorMode
    var entryKind: GoodsEntryKind
    var title: String
    var groupID: UUID?
    var memberID: UUID?
    var goodsTypeID: UUID?
    var quantity: Int
    var status: GoodsEditorStatus
    var tagNames: [String]
    var originalTagNames: [String]
    var hasLocalPhoto: Bool
    var localPhotoData: Data?
    var localPhotoContentType: String?
    var existingImageURL: URL?
    var didRemoveExistingPhoto: Bool
    var existingItemID: UUID?

    init(mode: GoodsEditorMode = .create, entryKind: GoodsEntryKind = .inventory, item: GoodsItem? = nil) {
        let normalizedItemTags = Self.normalizedTags(item?.tags.map(\.name) ?? [])
        self.mode = mode
        self.entryKind = entryKind
        self.title = item?.title ?? ""
        self.groupID = item?.groupID
        self.memberID = item?.memberID
        self.goodsTypeID = item?.goodsTypeID
        self.quantity = max(1, min(item?.quantity ?? 1, 999))
        self.status = item.map { GoodsEditorStatus(entryKind: entryKind, persistedStatus: $0.status) }
            ?? Self.defaultStatus(mode: mode, entryKind: entryKind)
        self.tagNames = normalizedItemTags
        self.originalTagNames = normalizedItemTags
        self.hasLocalPhoto = false
        self.localPhotoData = nil
        self.localPhotoContentType = nil
        self.existingImageURL = item?.imageURL
        self.didRemoveExistingPhoto = false
        self.existingItemID = item?.id
    }

    var isEditingExistingItem: Bool {
        mode != .create || existingItemID != nil
    }

    var normalizedQuantity: Int {
        max(1, min(quantity, 999))
    }

    var hasDisplayPhoto: Bool {
        hasLocalPhoto || existingImageURL != nil
    }

    var hasUnsavedLocalPhoto: Bool {
        hasLocalPhoto || localPhotoData != nil
    }

    var hasTagChanges: Bool {
        tagNames != originalTagNames
    }

    var photoStatusText: String {
        if hasUnsavedLocalPhoto {
            return existingImageURL == nil ? "選択済み（保存前）" : "選び直し済み（保存前）"
        }
        if didRemoveExistingPhoto {
            return "削除予定（保存前）"
        }
        if existingImageURL != nil {
            return "保存済み写真あり"
        }
        return "未選択"
    }

    mutating func setEntryKind(_ kind: GoodsEntryKind) {
        entryKind = kind
        if !status.isValid(for: kind) {
            status = Self.defaultStatus(mode: mode, entryKind: kind)
        }
    }

    mutating func addTag(_ rawTag: String) {
        let normalized = Self.normalizedTag(rawTag)
        guard let normalized, tagNames.count < 5 else {
            return
        }
        if !tagNames.contains(where: { $0.caseInsensitiveCompare(normalized) == .orderedSame }) {
            tagNames.append(normalized)
        }
    }

    mutating func removeTag(_ tag: String) {
        tagNames.removeAll { $0 == tag }
    }

    mutating func clearLocalPhotoSelection() {
        hasLocalPhoto = false
        localPhotoData = nil
        localPhotoContentType = nil
    }

    mutating func removeDisplayPhoto() {
        if existingImageURL != nil {
            didRemoveExistingPhoto = true
            existingImageURL = nil
        }
        clearLocalPhotoSelection()
    }

    mutating func setLocalPhotoUpload(_ upload: GoodsPhotoUpload) {
        hasLocalPhoto = true
        localPhotoData = upload.data
        localPhotoContentType = upload.contentType
    }

    func resolvedTitle(groupName: String?, memberName: String?, goodsTypeName: String?) -> String {
        if let trimmedTitle = title.nilIfBlank {
            return trimmedTitle
        }
        return [memberName, groupName, goodsTypeName]
            .compactMap(\.nilIfBlank)
            .joined(separator: " ")
    }

    func createInput(groupName: String? = nil, memberName: String? = nil, goodsTypeName: String? = nil) -> GoodsEntryInput? {
        guard mode == .create,
              blockingReasons.isEmpty,
              let groupID,
              let goodsTypeID
        else {
            return nil
        }
        let resolved = resolvedTitle(groupName: groupName, memberName: memberName, goodsTypeName: goodsTypeName)
        guard !resolved.isEmpty else {
            return nil
        }
        return GoodsEntryInput(
            kind: entryKind,
            title: resolved,
            groupID: groupID,
            memberID: memberID,
            goodsTypeID: goodsTypeID,
            quantity: normalizedQuantity,
            status: status.persistedStatus,
            tagNames: tagNames,
            photoUpload: photoUpload
        )
    }

    func updateInput(groupName: String? = nil, memberName: String? = nil, goodsTypeName: String? = nil) -> GoodsEntryUpdateInput? {
        guard mode == .edit,
              blockingReasons.isEmpty,
              let groupID,
              let goodsTypeID
        else {
            return nil
        }
        let resolved = resolvedTitle(groupName: groupName, memberName: memberName, goodsTypeName: goodsTypeName)
        guard !resolved.isEmpty else {
            return nil
        }
        let currentPhotoURLs: [String]? = didRemoveExistingPhoto ? [] : existingImageURL.map { [$0.absoluteString] }
        return GoodsEntryUpdateInput(
            title: resolved,
            groupID: groupID,
            memberID: memberID,
            clearsMemberID: memberID == nil,
            goodsTypeID: goodsTypeID,
            quantity: normalizedQuantity,
            status: status.persistedStatus,
            photoURLs: currentPhotoURLs,
            tagNames: tagNames,
            photoUpload: photoUpload
        )
    }

    var blockingReasons: [GoodsEditorSaveBlocker] {
        []
    }

    private var photoUpload: GoodsPhotoUpload? {
        guard let localPhotoData else {
            return nil
        }
        return GoodsPhotoUpload(data: localPhotoData, contentType: localPhotoContentType ?? "image/jpeg")
    }

    static func defaultStatus(mode: GoodsEditorMode, entryKind: GoodsEntryKind) -> GoodsEditorStatus {
        if mode == .readonly {
            return entryKind == .inventory ? .forTrade : .wishActive
        }
        return GoodsEditorStatus.defaultStatus(for: entryKind)
    }

    private static func normalizedTags(_ tags: [String]) -> [String] {
        tags.reduce(into: []) { result, tag in
            guard result.count < 5, let normalized = normalizedTag(tag) else {
                return
            }
            if !result.contains(where: { $0.caseInsensitiveCompare(normalized) == .orderedSame }) {
                result.append(normalized)
            }
        }
    }

    private static func normalizedTag(_ tag: String) -> String? {
        let normalized = tag
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "#＃"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return normalized.isEmpty ? nil : String(normalized.prefix(40))
    }
}
