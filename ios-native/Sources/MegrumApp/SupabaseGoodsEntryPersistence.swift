import Foundation
import MegrumCore
import MegrumData

final class SupabaseGoodsEntryPersistence: @unchecked Sendable {
    private let goodsInventoryClient: SupabaseGoodsInventoryClient
    private let userID: UUID

    init(goodsInventoryClient: SupabaseGoodsInventoryClient, userID: UUID) {
        self.goodsInventoryClient = goodsInventoryClient
        self.userID = userID
    }

    func createGoodsEntry(_ input: GoodsEntryInput) async throws -> GoodsItem {
        let uploadedPhotoURL = try await uploadGoodsPhotoIfNeeded(input.photoUpload)
        return try await goodsInventoryClient.createGoodsEntry(
            userID: userID,
            input: input,
            photoURLs: Self.createPhotoURLs(
                uploadedPhotoURL: uploadedPhotoURL,
                copiedPhotoURLs: input.photoURLs
            )
        )
    }

    func updateGoodsEntry(itemID: UUID, input: GoodsEntryUpdateInput) async throws -> GoodsItem {
        let uploadedPhotoURL = try await uploadGoodsPhotoIfNeeded(input.photoUpload)
        let updated = try await goodsInventoryClient.updateGoodsItem(
            userID: userID,
            itemID: itemID,
            input: Self.updateInput(from: input, uploadedPhotoURL: uploadedPhotoURL)
        )
        if let updated {
            return updated
        }
        throw MegrumRepositoryError.unsupportedMutation
    }

    static func createPhotoURLs(uploadedPhotoURL: String?, copiedPhotoURLs: [String] = []) -> [String] {
        if let uploadedPhotoURL {
            return [uploadedPhotoURL]
        }

        return copiedPhotoURLs.reduce(into: []) { result, raw in
            let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard result.count < 6,
                  let url = URL(string: normalized),
                  url.scheme?.isEmpty == false,
                  url.host?.isEmpty == false
            else {
                return
            }
            let value = url.absoluteString
            if !result.contains(value) {
                result.append(value)
            }
        }
    }

    static func updateInput(
        from input: GoodsEntryUpdateInput,
        uploadedPhotoURL: String?
    ) -> GoodsInventoryUpdateInput {
        GoodsInventoryUpdateInput(
            title: input.title,
            groupID: input.groupID,
            characterID: input.memberID,
            clearsCharacterID: input.clearsMemberID,
            goodsTypeID: input.goodsTypeID,
            quantity: input.quantity,
            status: GoodsInventoryStatus(rawValue: input.status.rawValue) ?? .active,
            photoURLs: uploadedPhotoURL.map { [$0] } ?? input.photoURLs,
            tagNames: input.tagNames
        )
    }

    private func uploadGoodsPhotoIfNeeded(_ upload: GoodsPhotoUpload?) async throws -> String? {
        guard let upload else {
            return nil
        }
        return try await goodsInventoryClient.uploadGoodsPhoto(
            userID: userID,
            imageData: upload.data,
            contentType: upload.contentType
        )
    }
}
