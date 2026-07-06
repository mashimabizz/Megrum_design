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
        let nowDate = Date()
        let now = SupabaseDateEncoding.isoTimestamp(nowDate)
        try await insertEvidencePhoto(
            proposal: proposal,
            userID: userID,
            proposalID: input.proposalID,
            photoURL: signedURL,
            position: nextPosition,
            takenAt: now
        )

        let updated = try await updateProposalMirrorAfterEvidenceInsert(
            proposal: proposal,
            userID: userID,
            proposalID: input.proposalID,
            signedURL: signedURL,
            position: nextPosition,
            takenAt: now,
            takenAtDate: nowDate
        )
        try? await createSystemMessage(
            proposalID: input.proposalID,
            senderID: userID,
            body: SupabaseTextNormalizer.optional(input.systemMessageBody) ?? "取引証跡をアップロードしました",
            meta: ["action": SupabaseProposalSystemAction.evidenceAdded.rawValue]
        )
        return updated
    }

    public func loadEvidencePhotos(proposalID: UUID) async throws -> [TradeEvidencePhoto] {
        let queryItems = [
            URLQueryItem(name: "proposal_id", value: "eq.\(proposalID.uuidString.lowercased())"),
            URLQueryItem(name: "order", value: "position.asc")
        ]
        let rows: [EvidencePhotoRow]
        do {
            rows = try await client.fetchRows(
                from: "proposal_evidence_photos",
                select: EvidencePhotoRow.select,
                queryItems: queryItems
            )
        } catch let error as SupabaseRESTError where error.statusCode == 400 {
            rows = try await client.fetchRows(
                from: "proposal_evidence_photos",
                select: EvidencePhotoRow.legacySelect,
                queryItems: queryItems
            )
        }
        return await refreshedEvidencePhotos(from: rows.compactMap(\.evidencePhoto))
    }

    /// やりとり一覧の先読み用：複数proposalの証跡写真を1リクエストでまとめて取得する。
    public func loadEvidencePhotosBulk(proposalIDs: [UUID]) async throws -> [UUID: [TradeEvidencePhoto]] {
        guard !proposalIDs.isEmpty else {
            return [:]
        }
        let idList = proposalIDs.map { $0.uuidString.lowercased() }.sorted().joined(separator: ",")
        let queryItems = [
            URLQueryItem(name: "proposal_id", value: "in.(\(idList))"),
            URLQueryItem(name: "order", value: "position.asc")
        ]
        let rows: [EvidencePhotoRow]
        do {
            rows = try await client.fetchRows(
                from: "proposal_evidence_photos",
                select: EvidencePhotoRow.select,
                queryItems: queryItems
            )
        } catch let error as SupabaseRESTError where error.statusCode == 400 {
            rows = try await client.fetchRows(
                from: "proposal_evidence_photos",
                select: EvidencePhotoRow.legacySelect,
                queryItems: queryItems
            )
        }
        var photosByProposalID: [UUID: [TradeEvidencePhoto]] = [:]
        for row in rows {
            guard let photo = row.evidencePhoto else {
                continue
            }
            photosByProposalID[row.proposalId, default: []].append(photo)
        }
        var refreshed: [UUID: [TradeEvidencePhoto]] = [:]
        for (proposalID, photos) in photosByProposalID {
            refreshed[proposalID] = await refreshedEvidencePhotos(from: photos)
        }
        return refreshed
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

    private func insertEvidencePhoto(
        proposal: TradeProposal,
        userID: UUID,
        proposalID: UUID,
        photoURL: URL,
        position: Int,
        takenAt: String
    ) async throws {
        do {
            let _: [EvidencePhotoAckRow] = try await client.insertRows(
                into: "proposal_evidence_photos",
                values: [
                    EvidencePhotoInsertPayload(
                        proposalID: proposalID,
                        photoURL: photoURL.absoluteString,
                        position: position,
                        takenAt: takenAt,
                        takenBy: userID,
                        approvedBySender: proposal.isSender(userID),
                        approvedByReceiver: !proposal.isSender(userID)
                    )
                ],
                select: "id"
            )
        } catch let error as SupabaseRESTError where error.statusCode == 400 {
            let _: [EvidencePhotoAckRow] = try await client.insertRows(
                into: "proposal_evidence_photos",
                values: [
                    LegacyEvidencePhotoInsertPayload(
                        proposalID: proposalID,
                        photoURL: photoURL.absoluteString,
                        position: position,
                        takenAt: takenAt,
                        takenBy: userID
                    )
                ],
                select: "id"
            )
        }
    }

    private func updateProposalMirrorAfterEvidenceInsert(
        proposal: TradeProposal,
        userID: UUID,
        proposalID: UUID,
        signedURL: URL,
        position: Int,
        takenAt: String,
        takenAtDate: Date
    ) async throws -> TradeProposal {
        do {
            let rows: [ProposalRow] = try await client.updateRows(
                in: "proposals",
                values: ProposalEvidenceUpdatePayload(
                    evidencePhotoURL: proposal.evidencePhotoURL == nil ? signedURL.absoluteString : nil,
                    evidenceTakenAt: takenAt,
                    evidenceTakenBy: userID,
                    approvedBySender: Self.approvedBySenderAfterEvidenceInsert(
                        proposal: proposal,
                        uploaderID: userID,
                        isFirstPhoto: position == 1
                    ),
                    approvedByReceiver: Self.approvedByReceiverAfterEvidenceInsert(
                        proposal: proposal,
                        uploaderID: userID,
                        isFirstPhoto: position == 1
                    )
                ),
                select: ProposalRow.select,
                queryItems: proposalQueryItems(proposalID: proposalID)
            )
            guard let updated = rows.first?.proposal else {
                throw SupabaseProposalClientError.malformedResponse
            }
            return updated
        } catch let error as SupabaseRESTError where error.statusCode == 400 {
            var fallback = proposal
            if fallback.evidencePhotoURL == nil {
                fallback.evidencePhotoURL = signedURL
                fallback.evidenceTakenAt = takenAtDate
                fallback.evidenceTakenBy = userID
            }
            fallback.approvedBySender = Self.approvedBySenderAfterEvidenceInsert(
                proposal: proposal,
                uploaderID: userID,
                isFirstPhoto: position == 1
            )
            fallback.approvedByReceiver = Self.approvedByReceiverAfterEvidenceInsert(
                proposal: proposal,
                uploaderID: userID,
                isFirstPhoto: position == 1
            )
            return fallback
        }
    }

    private func refreshedEvidencePhotos(from photos: [TradeEvidencePhoto]) async -> [TradeEvidencePhoto] {
        var refreshedPhotos: [TradeEvidencePhoto] = []
        refreshedPhotos.reserveCapacity(photos.count)
        for var photo in photos {
            if let storagePath = SupabaseMessagePhotoStorageMetadata.storagePath(from: photo.photoURL, bucket: Self.chatPhotoBucket),
               let signedURL = try? await client.createSignedURL(
                bucket: Self.chatPhotoBucket,
                path: storagePath,
                expiresIn: 60 * 60 * 24 * 365
               ) {
                photo.photoURL = signedURL
            }
            refreshedPhotos.append(photo)
        }
        return refreshedPhotos
    }

    private static func approvedBySenderAfterEvidenceInsert(
        proposal: TradeProposal,
        uploaderID: UUID,
        isFirstPhoto: Bool
    ) -> Bool {
        if proposal.isSender(uploaderID) {
            return isFirstPhoto ? true : proposal.approvedBySender
        }
        return false
    }

    private static func approvedByReceiverAfterEvidenceInsert(
        proposal: TradeProposal,
        uploaderID: UUID,
        isFirstPhoto: Bool
    ) -> Bool {
        if proposal.isSender(uploaderID) {
            return false
        }
        return isFirstPhoto ? true : proposal.approvedByReceiver
    }
}
