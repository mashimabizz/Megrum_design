import Foundation
import MegrumCore

struct TradeEvidenceListPresentationState {
    var pendingDeletePhoto: TradeEvidencePhoto?
    var presentedPhoto: TradeEvidencePhoto?
    private var locallyDeletedPhotoIDs: Set<UUID> = []

    var isDeleteConfirmationPresented: Bool {
        pendingDeletePhoto != nil
    }

    func displayedPhotos(from photos: [TradeEvidencePhoto]) -> [TradeEvidencePhoto] {
        photos.filter { !locallyDeletedPhotoIDs.contains($0.id) }
    }

    mutating func openPhoto(_ photo: TradeEvidencePhoto) {
        presentedPhoto = photo
    }

    mutating func requestDelete(_ photo: TradeEvidencePhoto) {
        pendingDeletePhoto = photo
    }

    mutating func clearPendingDelete() {
        pendingDeletePhoto = nil
    }

    mutating func clearPresentedPhoto() {
        presentedPhoto = nil
    }

    mutating func markDeleted(_ photo: TradeEvidencePhoto) {
        locallyDeletedPhotoIDs.insert(photo.id)
        if presentedPhoto?.id == photo.id {
            presentedPhoto = nil
        }
    }
}
