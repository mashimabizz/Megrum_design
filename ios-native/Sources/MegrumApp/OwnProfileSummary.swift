import Foundation
import MegrumCore

struct OwnProfileSummary: Equatable, Sendable {
    var displayName: String
    var handle: String
    var prefecture: String?
    var gender: UserGender?
    var paymentMethods: [UserPaymentMethod]
    var paymentNote: String?
    var avatarURL: URL?
    var inventoryCount: Int
    var wishCount: Int
    var activeTradeCount: Int
    var completedTradeCount: Int
    var listingCount: Int

    var prefectureText: String {
        prefecture.nilIfBlank ?? "未設定"
    }

    var handleText: String {
        "@\(handle)"
    }

    var genderText: String {
        gender?.label ?? "未設定"
    }

    var paymentMethodsText: String {
        UserPaymentMethod.displayText(for: paymentMethods, otherNote: paymentNote)
    }

    var activeTradeText: String {
        "\(activeTradeCount)件"
    }

    var completedTradeText: String {
        "\(completedTradeCount)"
    }

    var listingText: String {
        "\(listingCount)"
    }

    init?(
        viewer: UserProfile?,
        inventoryCount: Int,
        wishCount: Int,
        listingCount: Int = 0,
        proposals: [TradeProposal],
        localDraft: OwnProfileEditDraft? = nil
    ) {
        guard let viewer else {
            return nil
        }
        self.displayName = localDraft?.normalizedDisplayName ?? viewer.displayName
        self.handle = localDraft?.normalizedHandle ?? viewer.handle
        if let localDraft {
            self.prefecture = localDraft.normalizedPrefecture.nilIfBlank
        } else {
            self.prefecture = viewer.prefectureForDisplay
        }
        self.gender = localDraft?.gender ?? viewer.gender
        self.paymentMethods = localDraft?.paymentMethods ?? viewer.paymentMethods
        self.paymentNote = viewer.paymentNote
        if let localDraft {
            self.avatarURL = localDraft.visibleAvatarURL
        } else {
            self.avatarURL = viewer.avatarURL
        }
        self.inventoryCount = inventoryCount
        self.wishCount = wishCount
        self.listingCount = listingCount
        self.activeTradeCount = proposals.filter(\.status.isOwnProfileActiveTrade).count
        self.completedTradeCount = proposals.filter { $0.status == .completed }.count
    }
}

private extension UserGender {
    var label: String {
        displayName
    }
}

private extension UserProfile {
    var prefectureForDisplay: String? {
        prefecture.nilIfBlank
    }
}

private extension ProposalStatus {
    var isOwnProfileActiveTrade: Bool {
        switch self {
        case .sent, .negotiating, .agreementOneSide, .agreed:
            true
        case .draft, .rejected, .expired, .cancelled, .completed:
            false
        }
    }
}
