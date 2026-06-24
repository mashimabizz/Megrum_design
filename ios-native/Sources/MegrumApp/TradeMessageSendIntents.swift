import Foundation
import MegrumCore

struct TradeArrivalStatusSendIntent: Equatable, Sendable {
    var action: TradeArrivalQuickAction

    var messageType: TradeMessageType {
        .arrivalStatus
    }

    var status: TradeArrivalStatus {
        action.tradeStatus
    }

    var body: String {
        action.messageBody
    }

    var metadata: [String: String] {
        ["status": status.rawValue]
    }
}

struct TradeLocationShareIntent: Equatable, Sendable {
    var coordinate: MegrumLocationCoordinate
    var label: String = "現在地"
    var body: String?

    var messageType: TradeMessageType {
        .location
    }

    var normalizedLabel: String {
        label.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isSubmittable: Bool {
        !normalizedLabel.isEmpty
            && coordinate.latitude.isFinite
            && coordinate.longitude.isFinite
            && (-90...90).contains(coordinate.latitude)
            && (-180...180).contains(coordinate.longitude)
    }
}

struct TradeOutfitPhotoSendIntent: Equatable, Sendable {
    var imageContentType: String
    var body: String = "服装写真を共有しました"

    var messageType: TradeMessageType {
        .outfitPhoto
    }
}

struct TradeChatInputAvailability: Equatable, Sendable {
    var canSendMessages: Bool

    init(status: ProposalStatus) {
        self.canSendMessages = [.sent, .negotiating, .agreementOneSide, .agreed].contains(status)
    }

    init(proposal: TradeProposal) {
        self.init(status: proposal.status)
    }
}
