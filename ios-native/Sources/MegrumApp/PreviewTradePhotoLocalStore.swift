import Foundation
import MegrumCore

actor PreviewTradePhotoLocalStore {
    static let shared = PreviewTradePhotoLocalStore()

    private var evidencePhotosByProposalID: [UUID: [TradeEvidencePhoto]] = [:]
    private var deletedEvidencePhotoIDsByProposalID: [UUID: Set<UUID>] = [:]
    private var suppressesSeedEvidenceProposalIDs: Set<UUID> = []

    func reset() {
        evidencePhotosByProposalID = [:]
        deletedEvidencePhotoIDsByProposalID = [:]
        suppressesSeedEvidenceProposalIDs = []
    }

    func storeChatPhoto(_ input: TradePhotoMessageCreateInput) throws -> URL {
        try writeImage(
            data: input.imageData,
            contentType: input.imageContentType,
            proposalID: input.proposalID,
            category: input.messageType == .outfitPhoto ? "outfit" : "chat"
        )
    }

    func storeEvidencePhoto(_ input: TradeEvidenceCreateInput, proposal: TradeProposal) throws -> TradeEvidencePhoto {
        try storeEvidencePhoto(input, proposal: proposal, uploaderID: NativePreviewData.viewerID)
    }

    func storeEvidencePhoto(
        _ input: TradeEvidenceCreateInput,
        proposal: TradeProposal,
        uploaderID: UUID,
        position: Int? = nil
    ) throws -> TradeEvidencePhoto {
        let url = try writeImage(
            data: input.imageData,
            contentType: input.imageContentType,
            proposalID: input.proposalID,
            category: "evidence"
        )
        let existing = evidencePhotosByProposalID[input.proposalID] ?? []
        suppressesSeedEvidenceProposalIDs.insert(input.proposalID)
        let photo = TradeEvidencePhoto(
            id: UUID(),
            proposalID: input.proposalID,
            photoURL: url,
            position: position ?? existing.count + 1,
            takenAt: .now,
            takenBy: uploaderID,
            approvedBySender: proposal.isSender(uploaderID),
            approvedByReceiver: !proposal.isSender(uploaderID)
        )
        evidencePhotosByProposalID[input.proposalID] = [photo] + existing
        return photo
    }

    func evidencePhotos(for proposalID: UUID) -> [TradeEvidencePhoto] {
        let deletedIDs = deletedEvidencePhotoIDsByProposalID[proposalID] ?? []
        return (evidencePhotosByProposalID[proposalID] ?? []).filter { !deletedIDs.contains($0.id) }
    }

    func deleteEvidencePhoto(proposalID: UUID, photoID: UUID) {
        deletedEvidencePhotoIDsByProposalID[proposalID, default: []].insert(photoID)
        suppressesSeedEvidenceProposalIDs.insert(proposalID)
        evidencePhotosByProposalID[proposalID]?.removeAll { photo in
            if photo.id == photoID {
                if photo.photoURL.isFileURL {
                    try? FileManager.default.removeItem(at: photo.photoURL)
                }
                return true
            }
            return false
        }
    }

    func deletedEvidencePhotoIDs(for proposalID: UUID) -> Set<UUID> {
        deletedEvidencePhotoIDsByProposalID[proposalID] ?? []
    }

    func shouldIncludeSeedEvidence(for proposalID: UUID) -> Bool {
        !suppressesSeedEvidenceProposalIDs.contains(proposalID)
    }

    private func writeImage(data: Data, contentType: String, proposalID: UUID, category: String) throws -> URL {
        let directory = try imageDirectory()
        let filename = [
            proposalID.uuidString.lowercased(),
            category,
            UUID().uuidString.lowercased()
        ].joined(separator: "-")
        let fileURL = directory.appendingPathComponent(filename).appendingPathExtension(fileExtension(for: contentType))
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }

    private func imageDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("megrum-preview-trade-photos", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func fileExtension(for contentType: String) -> String {
        switch contentType.lowercased() {
        case "image/png":
            "png"
        case "image/webp":
            "webp"
        default:
            "jpg"
        }
    }
}
