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
