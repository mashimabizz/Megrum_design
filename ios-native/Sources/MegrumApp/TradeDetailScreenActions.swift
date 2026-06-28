import Foundation
import MegrumCore
import PhotosUI
import SwiftUI
#if os(iOS)
import UIKit
#endif

extension TradeDetailScreen {
    var evidencePhotoPickerSelection: Binding<PhotosPickerItem?> {
        Binding(
            get: { selectedEvidencePhotoItem },
            set: { item in
                selectedEvidencePhotoItem = item
                handleSelectedEvidencePhoto(item)
            }
        )
    }

    var tradeSummaryLine: String {
        "受け取る \(receiveSummaryText)  ⇄  出す \(goodsSummary(for: offeredGoodsIDs))"
    }

    var receiveSummaryText: String {
        if currentProposal.cashOffer, requestedGoodsIDs.isEmpty {
            return TradeAmountFormatter.fixedPrice(amount: currentProposal.cashAmount, fallback: "定価交換")
        }
        return goodsSummary(for: requestedGoodsIDs)
    }

    func goodsSummary(for ids: [UUID]) -> String {
        let items = tradeItems(for: ids)
        guard let first = items.first else {
            return ids.isEmpty ? "未設定" : "\(ids.count)点"
        }
        let suffix = items.count > 1 ? " 他\(items.count - 1)点" : ""
        return "\(first.title)\(first.quantity > 1 ? "×\(first.quantity)" : "")\(suffix)"
    }

    func openDisputeDetail(_ summary: TradeDisputeSummary) {
        disputeDetailRoute = TradeDisputeDetailRoute(
            summary: summary,
            model: summary.detailModel(proposal: currentProposal, viewerID: viewerID)
        )
    }

    func openPartnerProfile() {
        guard let partnerID else {
            return
        }
        partnerProfileRoute = TradePartnerProfileRoute(userID: partnerID)
    }

    func handleSelectedEvidencePhoto(_ item: PhotosPickerItem?) {
        guard let item else {
            return
        }
        Task {
            await addEvidence(from: item)
        }
    }

    func handleSelectedChatPhoto(_ item: PhotosPickerItem?) {
        guard let item else {
            return
        }
        Task {
            await addChatPhoto(from: item, messageType: .photo)
        }
    }

    func handleSelectedOutfitPhoto(_ item: PhotosPickerItem?) {
        guard let item else {
            return
        }
        Task {
            await addChatPhoto(from: item, messageType: .outfitPhoto)
        }
    }

    func handleCapturedEvidenceImage(_ imageData: Data) {
        Task {
            await addEvidence(data: imageData, imageContentType: "image/jpeg")
        }
    }

    func handleCapturedOutfitImage(_ imageData: Data) {
        Task {
            await addChatPhoto(
                data: imageData,
                messageType: .outfitPhoto,
                imageContentType: "image/jpeg"
            )
        }
    }

    func handleCapturedChatImage(_ imageData: Data) {
        Task {
            await addChatPhoto(
                data: imageData,
                messageType: .photo,
                imageContentType: "image/jpeg"
            )
        }
    }

    func openEvidenceList() {
        isShowingEvidenceList = true
        Task {
            await appState.loadTradeEvidencePhotos(proposal: currentProposal, reportsFailure: false)
        }
    }

    func openEvidencePhoto(_ photo: TradeEvidencePhoto) {
        selectedRemoteImage = RemoteImageSelection(
            url: photo.photoURL,
            evidencePhotoID: photo.id,
            canDeleteEvidencePhoto: currentProposal.status == .agreed && photo.isUploadedBy(viewerID)
        )
    }

    func selectedRemoteImageDeleteAction(for selection: RemoteImageSelection) -> (() -> Void)? {
        guard selection.canDeleteEvidencePhoto,
              let photoID = selection.evidencePhotoID,
              appState.deletingEvidencePhotoID != photoID else {
            return nil
        }
        return {
            selectedRemoteImage = nil
            Task {
                await appState.deleteTradeEvidencePhoto(
                    proposalID: currentProposal.id,
                    photoID: photoID
                )
            }
        }
    }

    func sendDraftMessage() {
        Task {
            let sent = await appState.sendMessage(proposalID: proposal.id, body: draftMessage)
            if sent {
                draftMessage = ""
            }
        }
    }

    func handleLocationCoordinateChange(_ coordinate: MegrumLocationCoordinate?) {
        guard isWaitingToShareLocation, let coordinate else {
            return
        }
        isWaitingToShareLocation = false
        sendLocationMessage(coordinate)
    }

    func handleLocationErrorChange(_ errorMessage: String?) {
        guard isWaitingToShareLocation, errorMessage != nil else {
            return
        }
        isWaitingToShareLocation = false
        unavailableChatAction = .location
    }

    func addEvidence(from item: PhotosPickerItem) async {
        defer {
            selectedEvidencePhotoItem = nil
        }
        guard let data = try? await item.loadTransferable(type: Data.self) else {
            return
        }
        let upload = normalizedChatPhotoUpload(from: data)
        await addEvidence(data: upload.data, imageContentType: upload.contentType)
    }

    func addEvidence(data: Data, imageContentType: String) async {
        let added = await appState.addTradeEvidence(
            proposalID: currentProposal.id,
            imageData: data,
            imageContentType: imageContentType
        )
        if added {
            isShowingEvidenceList = true
        }
    }

    func addChatPhoto(from item: PhotosPickerItem, messageType: TradeMessageType) async {
        defer {
            switch messageType {
            case .outfitPhoto:
                selectedOutfitPhotoItem = nil
            case .photo:
                selectedChatPhotoItem = nil
            case .text, .location, .arrivalStatus, .system:
                break
            }
        }
        guard let data = try? await item.loadTransferable(type: Data.self) else {
            unavailableChatAction = TradeUnavailableChatAction.messageFailureAction(for: messageType)
            return
        }
        let upload = normalizedChatPhotoUpload(from: data)
        await addChatPhoto(
            data: upload.data,
            messageType: messageType,
            imageContentType: upload.contentType
        )
    }

    func addChatPhoto(data: Data, messageType: TradeMessageType, imageContentType: String) async {
        let intent = TradeOutfitPhotoSendIntent(
            imageContentType: imageContentType
        )
        let sent = await appState.sendPhotoMessage(
            proposalID: currentProposal.id,
            imageData: data,
            imageContentType: intent.imageContentType,
            messageType: messageType == .outfitPhoto ? intent.messageType : messageType,
            body: messageType == .outfitPhoto ? intent.body : nil
        )
        if !sent {
            unavailableChatAction = TradeUnavailableChatAction.messageFailureAction(for: messageType)
        }
    }

    func sendArrivalQuickAction(_ action: TradeArrivalQuickAction) {
        let intent = TradeArrivalStatusSendIntent(action: action)
        Task {
            _ = await appState.sendArrivalStatusMessage(
                proposalID: currentProposal.id,
                status: intent.status,
                body: intent.body
            )
        }
    }

    func shareCurrentLocation() {
        isWaitingToShareLocation = true
        locationState.requestCurrentLocation(clearsPreviousCoordinate: true)
    }

    func sendLocationMessage(_ coordinate: MegrumLocationCoordinate) {
        let intent = TradeLocationShareIntent(coordinate: coordinate)
        guard intent.isSubmittable else {
            unavailableChatAction = .location
            return
        }
        Task {
            _ = await appState.sendLocationMessage(
                proposalID: currentProposal.id,
                latitude: intent.coordinate.latitude,
                longitude: intent.coordinate.longitude,
                label: intent.normalizedLabel,
                body: intent.body
            )
        }
    }

    var canUseCamera: Bool {
#if os(iOS)
        UIImagePickerController.isSourceTypeAvailable(.camera)
#else
        false
#endif
    }

    func tradeItems(for ids: [UUID]) -> [GoodsItem] {
        ids.compactMap { goodsByID[$0] }
    }
}
