import Foundation
import MegrumCore

enum TradeEvidenceApprovalOptimism {
    static func proposalAfterApproval(_ proposal: TradeProposal?, viewerID: UUID?) -> TradeProposal? {
        guard var next = proposal,
              let viewerID,
              next.isParticipant(viewerID)
        else {
            return nil
        }

        if next.isSender(viewerID) {
            next.approvedBySender = true
        } else {
            next.approvedByReceiver = true
        }

        if next.status == .agreed, next.approvedBySender, next.approvedByReceiver {
            next.status = .completed
            next.completedAt = next.completedAt ?? .now
        }
        return next
    }

    static func photosAfterApproval(
        _ photos: [TradeEvidencePhoto],
        photoID: UUID?,
        viewerID: UUID,
        proposal: TradeProposal?
    ) -> [TradeEvidencePhoto] {
        photos.map { photo in
            guard photoID == nil || photo.id == photoID else {
                return photo
            }
            return photoAfterApproval(photo, viewerID: viewerID, proposal: proposal)
        }
    }

    private static func photoAfterApproval(
        _ photo: TradeEvidencePhoto,
        viewerID: UUID,
        proposal: TradeProposal?
    ) -> TradeEvidencePhoto {
        guard let proposal, proposal.isParticipant(viewerID) else {
            return photo
        }

        var next = photo
        if proposal.isSender(viewerID) {
            next.approvedBySender = true
        } else {
            next.approvedByReceiver = true
        }
        return next
    }
}
