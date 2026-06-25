import Foundation
import MegrumCore

extension GoodsEditorSheet {
    var canSaveInventoryCreateMetas: Bool {
        !GoodsInventoryCreateValidation.hasMissingPhotos(metas: createMetas, photos: createPhotos)
            && !inventoryCreateInputs().isEmpty
            && !appState.isCreatingGoodsEntry
    }

    var selectedCreateMetas: [GoodsCreateMetaDraft] {
        createMetas.filter { selectedCreateMetaIDs.contains($0.id) }
    }

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
        selectAllCreateMetas()
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
        cropSession = GoodsPhotoCropSession(
            source: .selectedPhoto(photoID: photoID),
            upload: photo.upload
        )
    }

    func cropSheetTitle(for session: GoodsPhotoCropSession) -> String {
        switch session.source {
        case .selectedPhoto:
            "写真を切り取る"
        case .tradingCardBulk:
            "トレカAI一括登録"
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

    func toggleCreateMetaSelection(_ metaID: UUID) {
        if selectedCreateMetaIDs.contains(metaID) {
            selectedCreateMetaIDs.remove(metaID)
        } else {
            selectedCreateMetaIDs.insert(metaID)
        }
        createError = nil
    }

    func selectAllCreateMetas() {
        selectedCreateMetaIDs = Set(createMetas.map(\.id))
    }

    func clearCreateMetaSelection() {
        selectedCreateMetaIDs = []
    }

    func pruneCreateMetaSelection() {
        let validIDs = Set(createMetas.map(\.id))
        selectedCreateMetaIDs = selectedCreateMetaIDs.intersection(validIDs)
    }

    func applyCreateBulkMember(_ memberID: UUID?) {
        guard !selectedCreateMetaIDs.isEmpty else {
            createError = "メンバーを設定する画像を選択してください"
            return
        }
        guard memberID == nil || GoodsEditorMemberScope.canUseMemberID(
            memberID,
            group: selectedGroup,
            members: appState.oshiCharacters
        ) else {
            createError = "この推しに登録できないメンバーです"
            return
        }
        createMetas = createMetas.map { meta in
            guard selectedCreateMetaIDs.contains(meta.id) else {
                return meta
            }
            var next = meta
            next.memberID = memberID
            return next
        }
        createError = nil
    }

    func showCreateBulkTagSheet() {
        guard !selectedCreateMetaIDs.isEmpty else {
            createError = "タグを設定する画像を選択してください"
            return
        }
        createError = nil
        isShowingCreateBulkTagSelectionSheet = true
    }

    func applyCreateBulkTag(_ tagName: String) {
        guard !selectedCreateMetaIDs.isEmpty else {
            createError = "タグを設定する画像を選択してください"
            return
        }
        createMetas = createMetas.map { meta in
            guard selectedCreateMetaIDs.contains(meta.id) else {
                return meta
            }
            var next = meta
            next.addTag(tagName)
            return next
        }
        createError = nil
    }

    func removeCreateMetaTag(metaID: UUID, tagName: String) {
        guard let index = createMetas.firstIndex(where: { $0.id == metaID }) else {
            return
        }
        createMetas[index].removeTag(tagName)
        createError = nil
    }

    func inventoryCreateInputs() -> [GoodsEntryInput] {
        GoodsInventoryCreateInputBuilder.inputs(
            metas: createMetas,
            photos: createPhotos,
            sharedDraft: draft,
            groupName: selectedGroup?.name,
            members: scopedOshiCharacters,
            goodsTypeName: selectedGoodsType?.name
        )
    }

    func saveInventoryCreateFlow() async {
        guard canAdvanceFromCreateCommon else {
            createError = "グループとグッズ種別を選択してください"
            return
        }
        guard !GoodsInventoryCreateValidation.hasMissingPhotos(metas: createMetas, photos: createPhotos) else {
            createError = "譲るグッズは写真が必要です。登録する写真を選んでください"
            return
        }
        guard !GoodsInventoryCreateValidation.hasMissingMemberAssignments(
            metas: createMetas,
            requiresMemberAssignment: inventoryCreateAllowsMemberAssignment
        ) else {
            createError = "メンバーがある推しは、すべての画像にメンバーを登録してください"
            return
        }
        let inputs = inventoryCreateInputs()
        guard !inputs.isEmpty else {
            createError = "登録するアイテムがありません"
            return
        }

        createError = nil
        var savedCount = 0
        for input in inputs {
            let saved = await appState.createGoodsEntry(input)
            if !saved {
                let base = appState.errorMessage ?? "保存に失敗しました"
                createError = savedCount > 0 ? "\(savedCount)件は登録済みです。\(base)" : base
                return
            }
            savedCount += 1
        }
        dismiss()
    }
}
