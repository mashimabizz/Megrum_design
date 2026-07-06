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

    /// 同じ写真IDならキャッシュ済みURLを使い続ける。署名URLは取得のたびに変わるため、
    /// そのまま差し替えると画像キャッシュが効かず開くたびに再ダウンロード表示になる。
    public static func preservingCachedURLs(
        loadedPhotos: [TradeEvidencePhoto],
        cachedPhotos: [TradeEvidencePhoto]?
    ) -> [TradeEvidencePhoto] {
        guard let cachedPhotos, !cachedPhotos.isEmpty else {
            return loadedPhotos
        }
        let cachedURLByID = Dictionary(cachedPhotos.map { ($0.id, $0.photoURL) }) { first, _ in first }
        return loadedPhotos.map { photo in
            var photo = photo
            if let cachedURL = cachedURLByID[photo.id] {
                photo.photoURL = cachedURL
            }
            return photo
        }
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
