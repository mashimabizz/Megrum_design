import Foundation
import MegrumCore

enum GoodsInventoryCreateInputBuilder {
    static func inputs(
        metas: [GoodsCreateMetaDraft],
        photos: [GoodsCreatePhotoDraft],
        sharedDraft: GoodsEditorDraft,
        groupName: String?,
        members: [OshiCharacter],
        goodsTypeName: String?
    ) -> [GoodsEntryInput] {
        let uploadsByPhotoID = Dictionary(uniqueKeysWithValues: photos.map { ($0.id, $0.upload) })
        let memberNamesByID = Dictionary(uniqueKeysWithValues: members.map { ($0.id, $0.name) })

        return metas.compactMap { meta in
            meta.createInput(
                sharedDraft: sharedDraft,
                photoUpload: meta.photoID.flatMap { uploadsByPhotoID[$0] },
                groupName: groupName,
                memberName: meta.memberID.flatMap { memberNamesByID[$0] },
                goodsTypeName: goodsTypeName
            )
        }
    }
}
