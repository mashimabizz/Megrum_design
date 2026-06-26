import Foundation
import MegrumCore

public enum TradeEvidencePhotoStateReducer {
    public static func photos(
        for proposal: TradeProposal,
        in evidencePhotosByProposalID: [UUID: [TradeEvidencePhoto]],
        viewerID: UUID?
    ) -> [TradeEvidencePhoto] {
        if let photos = evidencePhotosByProposalID[proposal.id] {
            return photos
        }
        return fallbackPhotos(for: proposal, viewerID: viewerID)
    }

    public static func replacingLoadedPhotos(
        in evidencePhotosByProposalID: [UUID: [TradeEvidencePhoto]],
        proposal: TradeProposal,
        loadedPhotos: [TradeEvidencePhoto],
        viewerID: UUID?
    ) -> [UUID: [TradeEvidencePhoto]] {
        var next = evidencePhotosByProposalID
        next[proposal.id] = loadedPhotos.isEmpty ? fallbackPhotos(for: proposal, viewerID: viewerID) : loadedPhotos
        return next
    }

    public static func fallbackPhotos(
        for proposal: TradeProposal,
        viewerID: UUID?
    ) -> [TradeEvidencePhoto] {
        guard let url = proposal.evidencePhotoURL, let takenBy = proposal.evidenceTakenBy ?? viewerID else {
            return []
        }
        return [
            TradeEvidencePhoto(
                id: proposal.id,
                proposalID: proposal.id,
                photoURL: url,
                position: 1,
                takenAt: proposal.evidenceTakenAt,
                takenBy: takenBy,
                approvedBySender: proposal.approvedBySender,
                approvedByReceiver: proposal.approvedByReceiver
            )
        ]
    }
}
