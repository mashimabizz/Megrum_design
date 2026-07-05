import Foundation
import MegrumCore

enum GoodsGoogleLensSearchSource: Equatable {
    case upload(GoodsPhotoUpload)
    case imageURL(URL)

    var previewData: Data? {
        if case let .upload(upload) = self {
            return upload.data
        }
        return nil
    }

    var previewURL: URL? {
        if case let .imageURL(url) = self {
            return url
        }
        return nil
    }
}

struct GoodsGoogleLensSearchItem: Identifiable, Equatable {
    var id: UUID
    var title: String
    var detailText: String?
    var source: GoodsGoogleLensSearchSource
}

enum GoodsGoogleLensSearchItemFactory {
    private static let draftSearchItemID = UUID(uuidString: "00000000-0000-0000-0000-00000000c001")!

    static func items(
        metas: [GoodsCreateMetaDraft],
        photos: [GoodsCreatePhotoDraft],
        groupName: String?,
        members: [OshiCharacter],
        goodsTypeName: String?
    ) -> [GoodsGoogleLensSearchItem] {
        let memberNamesByID = Dictionary(uniqueKeysWithValues: members.map { ($0.id, $0.name) })
        return metas.enumerated().compactMap { offset, meta in
            guard let photoID = meta.photoID,
                  let photo = photos.first(where: { $0.id == photoID }),
                  !photo.upload.data.isEmpty
            else {
                return nil
            }
            let memberName = meta.memberID.flatMap { memberNamesByID[$0] }
            let title = meta.resolvedTitle(
                groupName: groupName,
                memberName: memberName,
                goodsTypeName: goodsTypeName
            ).nilIfBlank ?? "画像 \(offset + 1)"
            let tags = meta.tagNames.joined(separator: " / ").nilIfBlank
            let detailText = [memberName, goodsTypeName, tags]
                .compactMap { $0?.nilIfBlank }
                .joined(separator: " ・ ")
                .nilIfBlank

            return GoodsGoogleLensSearchItem(
                id: meta.id,
                title: title,
                detailText: detailText,
                source: .upload(photo.upload)
            )
        }
    }

    static func item(
        draft: GoodsEditorDraft,
        title: String,
        memberName: String?,
        goodsTypeName: String?
    ) -> GoodsGoogleLensSearchItem? {
        let source: GoodsGoogleLensSearchSource?
        if let data = draft.localPhotoData, !data.isEmpty {
            source = .upload(
                GoodsPhotoUpload(data: data, contentType: draft.localPhotoContentType ?? "image/jpeg")
            )
        } else if let imageURL = draft.existingImageURL {
            source = .imageURL(imageURL)
        } else {
            source = nil
        }
        guard let source else {
            return nil
        }
        return GoodsGoogleLensSearchItem(
            id: draft.existingItemID ?? Self.draftSearchItemID,
            title: title.nilIfBlank ?? "画像 1",
            detailText: detailText(memberName: memberName, goodsTypeName: goodsTypeName, tagNames: draft.tagNames),
            source: source
        )
    }

    static func items(from goodsItems: [GoodsItem]) -> [GoodsGoogleLensSearchItem] {
        goodsItems.compactMap { item in
            guard let imageURL = item.imageURL else {
                return nil
            }
            return GoodsGoogleLensSearchItem(
                id: item.id,
                title: item.title.nilIfBlank ?? "画像",
                detailText: detailText(
                    memberName: item.memberName,
                    goodsTypeName: item.goodsTypeName,
                    tagNames: item.tags.map(\.name)
                ),
                source: .imageURL(imageURL)
            )
        }
    }

    static func items(from wishes: [WishItem]) -> [GoodsGoogleLensSearchItem] {
        wishes.compactMap { item in
            guard let imageURL = item.imageURL else {
                return nil
            }
            return GoodsGoogleLensSearchItem(
                id: item.id,
                title: item.title.nilIfBlank ?? "画像",
                detailText: detailText(memberName: nil, goodsTypeName: nil, tagNames: item.tags.map(\.name)),
                source: .imageURL(imageURL)
            )
        }
    }

    static func items(from inventory: [GoodsItem], wishes: [WishItem], selectedGroupID: UUID?) -> [GoodsGoogleLensSearchItem] {
        items(from: inventory.filter { matchesSelectedGroup($0, selectedGroupID: selectedGroupID) })
            + items(from: wishes.filter { matchesSelectedGroup($0, selectedGroupID: selectedGroupID) })
    }

    private static func matchesSelectedGroup(_ item: GoodsItem, selectedGroupID: UUID?) -> Bool {
        guard let selectedGroupID else {
            return true
        }
        return item.groupID == selectedGroupID
    }

    private static func matchesSelectedGroup(_ item: WishItem, selectedGroupID: UUID?) -> Bool {
        guard let selectedGroupID else {
            return true
        }
        return item.groupID == selectedGroupID
    }

    private static func detailText(
        memberName: String?,
        goodsTypeName: String?,
        tagNames: [String]
    ) -> String? {
        let tags = tagNames.joined(separator: " / ").nilIfBlank
        return [memberName, goodsTypeName, tags]
            .compactMap { $0?.nilIfBlank }
            .joined(separator: " ・ ")
            .nilIfBlank
    }
}

enum GoogleLensSearchURLBuilder {
    static func url(forImageURL imageURL: URL) -> URL? {
        var components = URLComponents(string: "https://lens.google.com/uploadbyurl")
        components?.queryItems = [
            URLQueryItem(name: "url", value: imageURL.absoluteString)
        ]
        return components?.url
    }
}
