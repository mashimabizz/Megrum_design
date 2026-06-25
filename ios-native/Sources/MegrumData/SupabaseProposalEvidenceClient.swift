import Foundation
import MegrumCore

extension SupabaseProposalClient {
    public func addEvidencePhoto(userID: UUID, input: TradeEvidenceCreateInput) async throws -> TradeProposal {
        guard input.imageData.count <= Self.maxUploadBytes else {
            throw SupabaseProposalClientError.imageTooLarge
        }

        let proposal = try await loadProposal(proposalID: input.proposalID)
        guard proposal.isParticipant(userID) else {
            throw SupabaseProposalClientError.notParticipant
        }
        guard proposal.status == .agreed else {
            throw SupabaseProposalClientError.invalidStatus
        }

        let contentType = SupabaseImageContentTypeNormalizer.lenient(input.imageContentType)
        let path = evidencePhotoPath(proposalID: input.proposalID, contentType: contentType)
        try await client.uploadObject(
            bucket: Self.chatPhotoBucket,
            path: path,
            data: input.imageData,
            contentType: contentType,
            upsert: false
        )
        let signedURL = try await client.createSignedURL(
            bucket: Self.chatPhotoBucket,
            path: path,
            expiresIn: 60 * 60 * 24 * 365
        )

        let nextPosition = try await nextEvidencePhotoPosition(proposalID: input.proposalID)
        let now = SupabaseDateEncoding.isoTimestamp(.now)
        let _: [EvidencePhotoAckRow] = try await client.insertRows(
            into: "proposal_evidence_photos",
            values: [
                EvidencePhotoInsertPayload(
                    proposalID: input.proposalID,
                    photoURL: signedURL.absoluteString,
                    position: nextPosition,
                    takenAt: now,
                    takenBy: userID
                )
            ],
            select: "id"
        )

        let rows: [ProposalRow] = try await client.updateRows(
            in: "proposals",
            values: ProposalEvidenceUpdatePayload(
                evidencePhotoURL: proposal.evidencePhotoURL == nil ? signedURL.absoluteString : nil,
                evidenceTakenAt: now,
                evidenceTakenBy: userID
            ),
            select: ProposalRow.select,
            queryItems: proposalQueryItems(proposalID: input.proposalID)
        )
        guard let updated = rows.first?.proposal else {
            throw SupabaseProposalClientError.malformedResponse
        }
        try? await createSystemMessage(
            proposalID: input.proposalID,
            senderID: userID,
            body: "取引証跡が追加されました",
            meta: ["action": SupabaseProposalSystemAction.evidenceAdded.rawValue]
        )
        return updated
    }

    public func loadEvidencePhotos(proposalID: UUID) async throws -> [TradeEvidencePhoto] {
        let rows: [EvidencePhotoRow] = try await client.fetchRows(
            from: "proposal_evidence_photos",
            select: EvidencePhotoRow.select,
            queryItems: [
                URLQueryItem(name: "proposal_id", value: "eq.\(proposalID.uuidString.lowercased())"),
                URLQueryItem(name: "order", value: "position.asc")
            ]
        )
        return rows.compactMap(\.evidencePhoto)
    }

    public func deleteEvidencePhoto(userID: UUID, proposalID: UUID, photoID: UUID) async throws -> TradeProposal {
        let proposal = try await loadProposal(proposalID: proposalID)
        guard proposal.isParticipant(userID) else {
            throw SupabaseProposalClientError.notParticipant
        }
        guard proposal.status == .agreed else {
            throw SupabaseProposalClientError.invalidStatus
        }

        let photos = try await loadEvidencePhotos(proposalID: proposalID)
        guard let target = photos.first(where: { $0.id == photoID }) else {
            throw SupabaseProposalClientError.malformedResponse
        }
        guard target.takenBy == userID else {
            throw SupabaseProposalClientError.notParticipant
        }

        try await client.deleteRows(
            from: "proposal_evidence_photos",
            queryItems: evidencePhotoDeleteQueryItems(userID: userID, proposalID: proposalID, photoID: photoID)
        )

        let remainingPhotos = photos
            .filter { $0.id != photoID }
            .sorted { $0.position < $1.position }
        let rows: [ProposalRow] = try await client.updateRows(
            in: "proposals",
            values: ProposalEvidenceReplacementPayload(photo: remainingPhotos.first),
            select: ProposalRow.select,
            queryItems: proposalQueryItems(proposalID: proposalID)
        )
        guard let updated = rows.first?.proposal else {
            throw SupabaseProposalClientError.malformedResponse
        }
        return updated
    }

    private func nextEvidencePhotoPosition(proposalID: UUID) async throws -> Int {
        let rows: [EvidencePhotoPositionRow] = try await client.fetchRows(
            from: "proposal_evidence_photos",
            select: "position",
            queryItems: [
                URLQueryItem(name: "proposal_id", value: "eq.\(proposalID.uuidString.lowercased())"),
                URLQueryItem(name: "order", value: "position.desc"),
                URLQueryItem(name: "limit", value: "1")
            ]
        )
        return (rows.first?.position ?? 0) + 1
    }

    private func evidencePhotoPath(proposalID: UUID, contentType: String) -> String {
        let milliseconds = Int(Date().timeIntervalSince1970 * 1_000)
        return "\(proposalID.uuidString.lowercased())/evidence-\(milliseconds)-\(UUID().uuidString.lowercased()).\(SupabaseImageContentTypeNormalizer.lenientFileExtension(for: contentType))"
    }
}
