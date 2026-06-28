import Foundation
import MegrumCore

extension GoodsEditorSheet {
    var draftSeriesSuggestionInput: GoodsSeriesSuggestionInput? {
        let images = draftSeriesSuggestionImages()
        guard !images.isEmpty else {
            return nil
        }
        return GoodsSeriesSuggestionInput(
            images: images,
            groupName: selectedGroup?.name,
            memberName: selectedMember?.name,
            goodsTypeName: selectedGoodsType?.name,
            existingCandidateNames: editorTagSuggestions + draft.tagNames
        )
    }

    var selectedCreateMetaSeriesSuggestionInput: GoodsSeriesSuggestionInput? {
        let images = selectedCreateMetaSeriesSuggestionImages()
        guard !images.isEmpty else {
            return nil
        }
        return GoodsSeriesSuggestionInput(
            images: images,
            groupName: selectedGroup?.name,
            memberName: selectedCreateMetaSuggestionMemberName,
            goodsTypeName: selectedGoodsType?.name,
            existingCandidateNames: createBulkTagSuggestions + selectedCreateMetas.flatMap(\.tagNames)
        )
    }

    var selectedCreateMetaSuggestionMemberName: String? {
        let memberIDs = Set(selectedCreateMetas.compactMap(\.memberID))
        guard memberIDs.count == 1, let memberID = memberIDs.first else {
            return selectedMember?.name
        }
        return scopedOshiCharacters.first { $0.id == memberID }?.name
    }

    func showDraftTagSheet() {
        resetImageSeriesSuggestions()
        isShowingTagSelectionSheet = true
    }

    func requestDraftImageSeriesSuggestions() {
        requestImageSeriesSuggestions(target: .draft)
    }

    func requestSelectedCreateMetaImageSeriesSuggestions() {
        requestImageSeriesSuggestions(target: .selectedCreateMetas)
    }

    func resetImageSeriesSuggestions() {
        imageSeriesSuggestionState.reset()
    }

    private func requestImageSeriesSuggestions(target: SeriesSuggestionTarget) {
        guard !imageSeriesSuggestionState.isLoading else {
            return
        }
        guard let input = seriesSuggestionInput(for: target) else {
            imageSeriesSuggestionState.errorMessage = "画像を登録すると候補を検索できます。"
            return
        }

        imageSeriesSuggestionState.isLoading = true
        imageSeriesSuggestionState.errorMessage = nil
        Task {
            do {
                let names = try await appState.suggestGoodsSeriesNamesFromImage(input)
                imageSeriesSuggestionState.names = TagNameNormalizer.uniquePreservingOrder(names, limit: 6)
                if imageSeriesSuggestionState.names.isEmpty {
                    imageSeriesSuggestionState.errorMessage = "候補を見つけられませんでした。手入力で追加してください。"
                }
            } catch {
                imageSeriesSuggestionState.errorMessage = "画像からシリーズ候補を取得できませんでした。時間をおいて再度お試しください。"
            }
            imageSeriesSuggestionState.isLoading = false
        }
    }

    private func seriesSuggestionInput(for target: SeriesSuggestionTarget) -> GoodsSeriesSuggestionInput? {
        switch target {
        case .draft:
            draftSeriesSuggestionInput
        case .selectedCreateMetas:
            selectedCreateMetaSeriesSuggestionInput
        }
    }

    private func draftSeriesSuggestionImages() -> [GoodsSeriesSuggestionImage] {
        if let data = draft.localPhotoData, !data.isEmpty {
            return [
                GoodsSeriesSuggestionImage(
                    data: data,
                    contentType: draft.localPhotoContentType ?? "image/jpeg"
                )
            ]
        }
        if let imageURL = draft.existingImageURL {
            return [GoodsSeriesSuggestionImage(imageURL: imageURL)]
        }
        return []
    }

    private func selectedCreateMetaSeriesSuggestionImages() -> [GoodsSeriesSuggestionImage] {
        let photoIDs = selectedCreateMetas.compactMap(\.photoID)
        guard !photoIDs.isEmpty else {
            return []
        }
        var images: [GoodsSeriesSuggestionImage] = []
        for photoID in photoIDs {
            guard images.count < 3,
                  let photo = createPhotos.first(where: { $0.id == photoID }),
                  !photo.upload.data.isEmpty
            else {
                continue
            }
            images.append(
                GoodsSeriesSuggestionImage(
                    data: photo.upload.data,
                    contentType: photo.upload.contentType
                )
            )
        }
        return images
    }
}
