import Foundation

enum GoodsInventoryCreateValidation {
    static func hasMissingPhotos(metas: [GoodsCreateMetaDraft], photos: [GoodsCreatePhotoDraft]) -> Bool {
        guard !photos.isEmpty else {
            return true
        }
        let photoIDs = Set(photos.map(\.id))
        return metas.contains { meta in
            guard let photoID = meta.photoID else {
                return true
            }
            return !photoIDs.contains(photoID)
        }
    }

    static func hasMissingMemberAssignments(metas: [GoodsCreateMetaDraft], requiresMemberAssignment: Bool) -> Bool {
        guard requiresMemberAssignment else {
            return false
        }
        return metas.contains { $0.memberID == nil }
    }

    static func hasMissingTags(metas: [GoodsCreateMetaDraft]) -> Bool {
        metas.contains { $0.tagNames.isEmpty }
    }
}
