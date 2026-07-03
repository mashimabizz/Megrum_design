import Foundation
import SwiftUI

extension GoodsEditorSheet {
    func showDraftTagSheet() {
        googleLensSearchErrorMessage = nil
        isShowingTagSelectionSheet = true
    }

    var draftGoogleLensItems: [GoodsGoogleLensSearchItem] {
        guard let item = GoodsGoogleLensSearchItemFactory.item(
            draft: draft,
            title: resolvedTitlePreview,
            memberName: selectedMember?.name,
            goodsTypeName: selectedGoodsType?.name
        ) else {
            return []
        }
        return [item]
    }

    var selectedCreateMetaGoogleLensItems: [GoodsGoogleLensSearchItem] {
        GoodsGoogleLensSearchItemFactory.items(
            metas: selectedCreateMetas,
            photos: createPhotos,
            groupName: selectedGroup?.name,
            members: scopedOshiCharacters,
            goodsTypeName: selectedGoodsType?.name
        )
    }

    func openSelectedCreateMetaGoogleLensSearch(itemID: GoodsGoogleLensSearchItem.ID) {
        openGoogleLensSearch(itemID: itemID, in: selectedCreateMetaGoogleLensItems)
    }

    func openDraftGoogleLensSearch(itemID: GoodsGoogleLensSearchItem.ID) {
        openGoogleLensSearch(itemID: itemID, in: draftGoogleLensItems)
    }

    private func openGoogleLensSearch(itemID: GoodsGoogleLensSearchItem.ID, in items: [GoodsGoogleLensSearchItem]) {
        guard !isOpeningGoogleLensSearch else {
            return
        }
        guard let item = items.first(where: { $0.id == itemID }) else {
            googleLensSearchErrorMessage = "画像検索するグッズを選び直してください。"
            return
        }

        isOpeningGoogleLensSearch = true
        googleLensSearchErrorMessage = nil
        Task {
            do {
                let imageURL: URL
                switch item.source {
                case let .upload(upload):
                    imageURL = try await appState.uploadGoodsGoogleLensSearchPhoto(upload)
                case let .imageURL(url):
                    imageURL = url
                }
                guard let lensURL = GoogleLensSearchURLBuilder.url(forImageURL: imageURL) else {
                    throw URLError(.badURL)
                }
                openURL(lensURL)
            } catch {
                googleLensSearchErrorMessage = "Google Lensを開けませんでした。時間をおいて再度お試しください。"
            }
            isOpeningGoogleLensSearch = false
        }
    }
}
