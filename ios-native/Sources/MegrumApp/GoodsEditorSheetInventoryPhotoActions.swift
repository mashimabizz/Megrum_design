import Foundation
import MegrumCore

extension GoodsEditorSheet {
    func goToCreateShoot() {
        guard canAdvanceFromCreateCommon else {
            createError = "グループとグッズ種別を選択してください"
            return
        }
        createError = nil
        createStep = .shoot
    }

    func goToCreateMetaWithPhotos() {
        guard !createPhotos.isEmpty else {
            createError = "登録する写真を選んでください"
            return
        }
        syncCreateMetasWithPhotos()
        createError = nil
        createStep = .meta
    }

    func resetInventoryCreateFlow() {
        createStep = .common
        createPhotos = []
        createMetas = [GoodsCreateMetaDraft()]
        selectedCreateMetaIDs = []
        createError = nil
        photoError = nil
        tradingCardBulkStatusMessage = nil
        isProcessingTradingCardBulk = false
        cropSession = nil
        pendingCropUploads = []
        showsCreateOshiMasterSheet = false
        createOshiRequestSheet = nil
        #if canImport(PhotosUI)
        selectedCreatePhotoItems = []
        selectedTradingCardBulkPhotoItem = nil
        #endif
    }

    func resetCreateMetaMembers() {
        guard usesInventoryCreateFlow else {
            return
        }
        createMetas = createMetas.map { meta in
            var next = meta
            next.memberID = nil
            return next
        }
    }

    func syncCreateMetasWithPhotos() {
        guard !createPhotos.isEmpty else {
            if createMetas.isEmpty {
                createMetas = [GoodsCreateMetaDraft()]
            }
            return
        }
        let currentByPhotoID = Dictionary(uniqueKeysWithValues: createMetas.compactMap { meta in
            meta.photoID.map { ($0, meta) }
        })
        createMetas = createPhotos.map { photo in
            currentByPhotoID[photo.id] ?? GoodsCreateMetaDraft(photoID: photo.id)
        }
        pruneCreateMetaSelection()
    }

    func removeCreatePhoto(_ photoID: UUID) {
        createPhotos.removeAll { $0.id == photoID }
        if createStep == .meta {
            syncCreateMetasWithPhotos()
        } else {
            createMetas.removeAll { $0.photoID == photoID }
            pruneCreateMetaSelection()
        }
    }

    func showCropForCreatePhoto(_ photoID: UUID) {
        guard let photo = createPhotos.first(where: { $0.id == photoID }) else {
            return
        }
        // iter1226.436：初期枠は置かない（全体枠があるとドラッグが常に「枠の移動」になり
        // 手動で枠を描けない）。枠なしのまま追加＝写真全体を使う。
        cropSession = GoodsPhotoCropSession(
            source: .selectedPhoto(photoID: photoID),
            upload: photo.upload
        )
    }

    /// 追加された写真をトリミング待ちキューへ積む。
    /// カメラ（連続撮影）中はシートが競合するため、閉じたタイミングで presentNextPendingCropSession が拾う。
    func enqueueCropForNewUpload(_ upload: GoodsPhotoUpload) {
        pendingCropUploads.append(upload)
    }

    /// トリミング待ちキューの先頭を crop sheet として提示する。
    /// crop sheet / カメラ sheet の onDismiss から呼ばれて連鎖する。
    func presentNextPendingCropSession() {
        guard cropSession == nil, cameraCaptureRoute == nil, !pendingCropUploads.isEmpty else {
            return
        }
        let upload = pendingCropUploads.removeFirst()
        cropSession = GoodsPhotoCropSession(
            source: .newPhoto,
            upload: upload
        )
    }

    func cropSheetTitle(for session: GoodsPhotoCropSession) -> String {
        switch session.source {
        case .newPhoto:
            pendingCropUploads.isEmpty ? "トリミング" : "トリミング（あと\(pendingCropUploads.count)枚）"
        case .selectedPhoto:
            "トリミング"
        case .tradingCardBulk:
            "まとめて登録"
        }
    }

    func applyCropUploads(_ uploads: [GoodsPhotoUpload], from session: GoodsPhotoCropSession) {
        let nextDrafts = uploads.compactMap { upload -> GoodsCreatePhotoDraft? in
            if let uploadError = goodsEditorPhotoUploadError(for: upload) {
                createError = uploadError
                return nil
            }
            return GoodsCreatePhotoDraft(upload: upload)
        }

        guard !nextDrafts.isEmpty else {
            createError = createError ?? "切り取り画像を追加できませんでした"
            return
        }

        switch session.source {
        case .newPhoto:
            createPhotos.append(contentsOf: nextDrafts)
            tradingCardBulkStatusMessage = nil
        case .selectedPhoto(let photoID):
            if let index = createPhotos.firstIndex(where: { $0.id == photoID }) {
                createPhotos.replaceSubrange(index...index, with: nextDrafts)
            } else {
                createPhotos.append(contentsOf: nextDrafts)
            }
            tradingCardBulkStatusMessage = nil
        case .tradingCardBulk:
            createPhotos.append(contentsOf: nextDrafts)
            tradingCardBulkStatusMessage = "\(nextDrafts.count)枚の切り取り画像を写真一覧へ追加しました。"
        }

        if createStep == .meta {
            syncCreateMetasWithPhotos()
        }
        nextDrafts.forEach { draft in
            analyzeFaceTagsIfNeeded(upload: draft.upload, target: .createPhoto(draft.id))
        }
        createError = nil
        cropSession = nil
    }

    func analyzeFaceTagsIfNeeded(upload: GoodsPhotoUpload, target: FaceTaggingReviewTarget) {
        guard GoodsEditorMemberLinkingPolicy.presentsAutomaticFaceTaggingReview else {
            return
        }
        let imageData = upload.data
        guard let group = selectedGroup, group.supportsMemberSelection else {
            return
        }
        let initialMemberIDs = GoodsEditorMemberScope.memberIDs(for: group, from: appState.oshiCharacters)

        Task {
            do {
                let eligibleMemberIDs: [UUID]
                if initialMemberIDs.isEmpty {
                    await loadMembers(for: group.id)
                    eligibleMemberIDs = GoodsEditorMemberScope.memberIDs(for: group, from: appState.oshiCharacters)
                } else {
                    eligibleMemberIDs = initialMemberIDs
                }
                guard !eligibleMemberIDs.isEmpty else {
                    return
                }

                let memberIDSet = Set(eligibleMemberIDs)
                let loadedProfiles = await appState.loadMemberFaceProfiles(memberIDs: eligibleMemberIDs)
                let memberProfiles = loadedProfiles.filter { memberIDSet.contains($0.memberID) }
                let service = UnifiedMemberTaggingService()
                let analysis = try await service.analyzeImage(
                    imageData,
                    imageID: UUID(),
                    memberProfiles: memberProfiles
                )
                guard !analysis.results.isEmpty else {
                    return
                }
                await MainActor.run {
                    enqueueFaceTaggingReview(
                        FaceTaggingReviewContext(
                            target: target,
                            imageData: imageData,
                            analysis: analysis
                        )
                    )
                }
            } catch {
                #if DEBUG
                MegrumAppLogger.general.debug("Face tagging analysis failed: \(String(describing: error), privacy: .public)")
                #endif
            }
        }
    }

    func enqueueFaceTaggingReview(_ context: FaceTaggingReviewContext) {
        faceTaggingReviewQueue.enqueue(context)
    }

    func presentNextFaceTaggingReview() {
        faceTaggingReviewQueue.presentNextIfNeeded()
    }

    func applyFaceTaggingCorrections(
        _ corrections: [FaceTaggingCorrectionDraft],
        target: FaceTaggingReviewTarget
    ) {
        guard let selectedMemberID = corrections.compactMap(\.selectedMemberID).first else {
            return
        }
        guard GoodsEditorMemberScope.canUseMemberID(
            selectedMemberID,
            group: selectedGroup,
            members: appState.oshiCharacters
        ) else {
            return
        }
        switch target {
        case .draft:
            draft.memberID = selectedMemberID
        case .createPhoto(let photoID):
            if let index = createMetas.firstIndex(where: { $0.photoID == photoID }) {
                createMetas[index].memberID = selectedMemberID
            } else {
                createMetas.append(GoodsCreateMetaDraft(photoID: photoID, memberID: selectedMemberID))
            }
        }
    }
}
