import MegrumCore

struct ProposalCreateConfiguration: Equatable {
    var exchangeMethod: ExchangeMethod
    var hasSelectedSenderGoods: Bool
    var isCreatingProposal: Bool
    var hasReadyMailingAddress: Bool
    var isLoadingMailingAddress: Bool
    var hasValidMeetup: Bool = false
    var receiverGoodsCount: Int
    var isListingSource: Bool

    private static let mailConditionTags = ["即日発送", "同日発送"]
    private static let baseConditionTags = ["開演前OK", "終演後OK", "グッズ販売中OK", "短時間OK", "同種優先"]

    var conditionTagOptions: [String] {
        switch exchangeMethod {
        case .hand:
            Self.baseConditionTags
        case .mail:
            Self.mailConditionTags + Self.baseConditionTags
        case .both:
            Self.mailConditionTags + Self.baseConditionTags
        }
    }

    var requiresMeetupBeforeSubmit: Bool {
        exchangeMethod == .hand || exchangeMethod == .both
    }

    var requiresMailingAddressBeforeSubmit: Bool {
        exchangeMethod == .mail || exchangeMethod == .both
    }

    var canSubmit: Bool {
        hasSelectedSenderGoods
            && receiverGoodsCount > 0
            && !isCreatingProposal
            && !isLoadingMailingAddress
            && targetStatus != nil
    }

    var targetStatus: ProposalStatus? {
        if requiresMailingAddressBeforeSubmit && !hasReadyMailingAddress {
            return nil
        }
        if requiresMeetupBeforeSubmit && !hasValidMeetup {
            return nil
        }
        return .sent
    }

    var submitTitle: String {
        if receiverGoodsCount <= 0 {
            return "受け取るものを選択"
        }
        if requiresMailingAddressBeforeSubmit && !hasReadyMailingAddress {
            return "住所登録が必要"
        }
        if requiresMeetupBeforeSubmit && !hasValidMeetup {
            return "待ち合わせ入力が必要"
        }
        return "この内容で打診を送信"
    }

    var methodNotice: String? {
        if requiresMailingAddressBeforeSubmit && isLoadingMailingAddress {
            return "住所登録を確認しています。"
        }
        if requiresMailingAddressBeforeSubmit && !hasReadyMailingAddress {
            return "郵送交換は住所登録が必要です。設定から住所を登録してください。"
        }
        if requiresMeetupBeforeSubmit && !hasValidMeetup {
            return "現地交換は待ち合わせ候補を入力すると送信できます。"
        }
        return nil
    }

    var targetSubtitle: String {
        isListingSource ? "個別募集から選択" : "相手のマイグッズから選択"
    }

    var targetSupplement: String? {
        guard isListingSource, receiverGoodsCount > 1 else {
            return nil
        }
        return "ほか\(receiverGoodsCount - 1)件も受け取る条件です"
    }
}
