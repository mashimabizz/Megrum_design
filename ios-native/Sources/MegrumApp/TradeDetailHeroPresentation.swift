import Foundation
import MegrumCore

struct TradeDetailHeroPresentation: Equatable, Sendable {
    var partnerDisplayName: String
    var partnerHandle: String
    var partnerInitial: String
    var partnerAvatarURL: URL?
    var partnerMetaText: String
    var partnerAverageStars: Double?
    var partnerEvaluationCount: Int?
    var relationText: String
    var statusLabel: String
    var agreementLabel: String
    var guidanceText: String
    var myAgreementText: String
    var partnerAgreementText: String
    var myAgreementDone: Bool
    var partnerAgreementDone: Bool
    var exchangeMethodText: String
    var summaryText: String

    init(
        proposal: TradeProposal,
        viewerID: UUID?,
        profilesByUserID: [UUID: PublicUserProfile],
        viewerHasCounterProposal: Bool = false
    ) {
        let partnerID = viewerID.flatMap { proposal.partnerID(for: $0) }
            ?? proposal.receiverID
        let publicProfile = profilesByUserID[partnerID]
        let profile = publicProfile?.profile
        let handle = profile?.handle
            ?? "user_\(partnerID.uuidString.prefix(4).lowercased())"
        self.partnerDisplayName = (profile?.displayName).nilIfBlank ?? handle
        self.partnerHandle = handle
        self.partnerInitial = String(self.partnerDisplayName.prefix(1)).uppercased()
        self.partnerAvatarURL = profile?.avatarURL
        self.exchangeMethodText = proposal.exchangeMethod.displayName
        self.partnerMetaText = Self.partnerMetaText(for: profile)
        self.partnerAverageStars = publicProfile?.averageStars
        self.partnerEvaluationCount = publicProfile.map(\.evaluationCount)

        let isSender = viewerID.map { proposal.senderID == $0 } ?? false
        let isReceiver = viewerID.map { proposal.receiverID == $0 } ?? false
        let showsOutgoingWaitingState = isSender || viewerHasCounterProposal
        self.relationText = Self.relationText(isSender: showsOutgoingWaitingState, isReceiver: isReceiver && !viewerHasCounterProposal)

        let myAgreed = viewerID.map { proposal.agreementBy($0) } ?? false
        let partnerAgreed = viewerID.map { proposal.partnerAgreement(for: $0) } ?? false
        self.myAgreementDone = myAgreed
        self.partnerAgreementDone = partnerAgreed
        self.myAgreementText = myAgreed ? "私 合意済" : "私 未合意"
        self.partnerAgreementText = partnerAgreed ? "相手 合意済" : "相手 未合意"
        self.statusLabel = Self.statusLabel(
            for: proposal.status,
            isSender: showsOutgoingWaitingState,
            isReceiver: isReceiver && !viewerHasCounterProposal,
            myAgreed: myAgreed
        )
        self.agreementLabel = Self.agreementLabel(
            for: proposal.status,
            isSender: showsOutgoingWaitingState,
            myAgreed: myAgreed
        )
        self.guidanceText = Self.guidanceText(
            for: proposal.status,
            isSender: showsOutgoingWaitingState,
            myAgreed: myAgreed,
            partnerAgreed: partnerAgreed
        )
        self.summaryText = Self.summaryText(for: proposal, viewerID: viewerID)
    }

    private static func relationText(isSender: Bool, isReceiver: Bool) -> String {
        if isSender {
            return "あなたから送った打診"
        }
        if isReceiver {
            return "相手から届いた打診"
        }
        return "取引のやりとり"
    }

    private static func statusLabel(
        for status: ProposalStatus,
        isSender: Bool,
        isReceiver: Bool,
        myAgreed: Bool
    ) -> String {
        switch status {
        case .draft:
            return "下書き"
        case .sent:
            return isReceiver ? "新着打診" : "現在打診中"
        case .negotiating:
            return "ネゴ中"
        case .agreementOneSide:
            return myAgreed ? "相手待ち" : "合意待ち"
        case .agreed:
            return "取引予定"
        case .completed:
            return "完了"
        case .cancelled:
            return "キャンセル"
        case .rejected:
            return "見送り"
        case .expired:
            return "期限切れ"
        }
    }

    private static func agreementLabel(for status: ProposalStatus, isSender: Bool, myAgreed: Bool) -> String {
        switch status {
        case .completed:
            return "完了"
        case .agreed:
            return "合意済"
        case .agreementOneSide:
            return myAgreed ? "相手の合意待ち" : "あなたの合意待ち"
        case .negotiating:
            return "相談中"
        case .sent:
            return isSender ? "相手からの返信待ち" : "未合意"
        case .rejected:
            return "見送り"
        case .cancelled:
            return "キャンセル"
        case .expired:
            return "期限切れ"
        case .draft:
            return "下書き"
        }
    }

    private static func guidanceText(
        for status: ProposalStatus,
        isSender: Bool,
        myAgreed: Bool,
        partnerAgreed: Bool
    ) -> String {
        switch status {
        case .sent:
            return isSender
                ? "現在打診中です。相手からの返信待ちです。"
                : "内容を確認して、承諾・再打診・見送りを選べます。"
        case .negotiating:
            return "条件を相談中です。双方が納得した内容で合意すると取引予定に進みます。"
        case .agreementOneSide:
            if myAgreed && !partnerAgreed {
                return "あなたは合意済みです。相手の合意を待っています。"
            }
            return "相手は合意済みです。この内容で進める場合は合意してください。"
        case .agreed:
            return "取引成立済みです。チャット、現在地、服装写真、証跡撮影をここから使えます。"
        case .completed:
            return "取引完了済みです。証跡と評価を確認できます。"
        case .rejected:
            return "この打診は見送りになりました。"
        case .cancelled:
            return "この取引はキャンセル済みです。"
        case .expired:
            return "この打診は期限切れです。"
        case .draft:
            return "下書きの打診です。"
        }
    }

    private static func summaryText(for proposal: TradeProposal, viewerID: UUID?) -> String {
        let offeredCount = viewerID.flatMap { proposal.goodsOffered(by: $0)?.count } ?? proposal.senderGoodsIDs.count
        let requestedCount = viewerID.flatMap { proposal.goodsRequested(by: $0)?.count } ?? proposal.receiverGoodsIDs.count
        return "ゆずる \(offeredCount)点 / 求める \(requestedCount)点"
    }

    private static func partnerMetaText(for profile: UserProfile?) -> String {
        guard let profile else {
            return "未共有"
        }
        let ageDecade = profile.age.flatMap(ageDecadeText)
        let gender = profile.gender.flatMap(publicGenderText)
        let prefecture = profile.prefecture.nilIfBlank
        let parts = [ageDecade, gender, prefecture].compactMap(\.self)
        return parts.isEmpty ? "未共有" : parts.joined(separator: "・")
    }

    private static func ageDecadeText(for age: Int) -> String? {
        guard age > 0 else {
            return nil
        }
        if age < 10 {
            return "10歳未満"
        }
        return "\(age / 10 * 10)代"
    }

    private static func publicGenderText(for gender: UserGender) -> String? {
        switch gender {
        case .noAnswer:
            return nil
        case .female, .male, .other:
            return gender.displayName
        }
    }
}
