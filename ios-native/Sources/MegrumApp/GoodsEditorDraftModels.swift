import Foundation
import MegrumCore

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
    var tagNames: [String]

    init(
        id: UUID = UUID(),
        photoID: UUID? = nil,
        memberID: UUID? = nil,
        title: String = "",
        quantity: Int = 1,
        tagNames: [String] = []
    ) {
        self.id = id
        self.photoID = photoID
        self.memberID = memberID
        self.title = title
        self.quantity = quantity
        self.tagNames = Self.normalizedTags(tagNames)
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
            kind: sharedDraft.entryKind,
            title: resolved,
            groupID: groupID,
            memberID: memberID,
            goodsTypeID: goodsTypeID,
            quantity: normalizedQuantity,
            status: sharedDraft.status.persistedStatus,
            tagNames: tagNames,
            photoUpload: photoUpload
        )
    }

    mutating func addTag(_ rawTag: String) {
        let normalized = TagNameNormalizer.normalized(rawTag)
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

    private static func normalizedTags(_ tags: [String]) -> [String] {
        tags.reduce(into: []) { result, tag in
            guard result.count < 5, let normalized = TagNameNormalizer.normalized(tag) else {
                return
            }
            if !result.contains(where: { $0.caseInsensitiveCompare(normalized) == .orderedSame }) {
                result.append(normalized)
            }
        }
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
        TagNameNormalizer.normalized(tag)
    }
}
