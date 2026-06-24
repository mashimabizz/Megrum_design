import MegrumCore

enum TradeArrivalQuickAction: String, CaseIterable, Identifiable, Sendable {
    case enroute
    case arrived
    case left

    var id: String { rawValue }

    var title: String {
        switch self {
        case .enroute:
            "向かっています"
        case .arrived:
            "到着しました"
        case .left:
            "離れました"
        }
    }

    var messageBody: String {
        title
    }

    var tradeStatus: TradeArrivalStatus {
        switch self {
        case .enroute:
            .enroute
        case .arrived:
            .arrived
        case .left:
            .left
        }
    }

    var systemImage: String {
        switch self {
        case .enroute:
            "figure.walk"
        case .arrived:
            "checkmark.circle.fill"
        case .left:
            "arrow.turn.up.left"
        }
    }
}

enum TradeMessageQuickActionKind: Equatable, Identifiable, Sendable {
    case location
    case arrival(TradeArrivalQuickAction)
    case outfitPhoto
    case assistance(TradeAssistanceRequestKind)
    case schedule
    case counterProposal
    case chatPhoto

    var id: String {
        switch self {
        case .location:
            "location"
        case .arrival(let action):
            "arrival-\(action.rawValue)"
        case .outfitPhoto:
            "outfit-photo"
        case .assistance(let kind):
            "assistance-\(kind.rawValue)"
        case .schedule:
            "schedule"
        case .counterProposal:
            "counter-proposal"
        case .chatPhoto:
            "chat-photo"
        }
    }

    var title: String {
        switch self {
        case .location:
            "現在地を送る"
        case .arrival(let action):
            action.title
        case .outfitPhoto:
            "服装写真"
        case .assistance(let kind):
            kind.title
        case .schedule:
            "スケジュール"
        case .counterProposal:
            "条件を変えて再打診"
        case .chatPhoto:
            "写真"
        }
    }

    var systemImage: String {
        switch self {
        case .location:
            "location.fill"
        case .arrival(.enroute):
            "paperplane.fill"
        case .arrival(.arrived):
            "checkmark.circle.fill"
        case .arrival(.left):
            "arrow.turn.up.left"
        case .outfitPhoto:
            "tshirt.fill"
        case .assistance(let kind):
            kind.systemImage
        case .schedule:
            "calendar"
        case .counterProposal:
            "arrow.triangle.2.circlepath"
        case .chatPhoto:
            "photo.on.rectangle"
        }
    }
}

enum TradeMessageOverflowActionKind: Equatable, Identifiable, Sendable {
    case arrivalStatusMenu
    case location
    case outfitCamera
    case outfitLibrary
    case assistance(TradeAssistanceRequestKind)
    case schedule
    case counterProposal
    case chatCamera
    case chatLibrary

    var id: String {
        switch self {
        case .arrivalStatusMenu:
            "arrival-status-menu"
        case .location:
            "location"
        case .outfitCamera:
            "outfit-camera"
        case .outfitLibrary:
            "outfit-library"
        case .assistance(let kind):
            "assistance-\(kind.rawValue)"
        case .schedule:
            "schedule"
        case .counterProposal:
            "counter-proposal"
        case .chatCamera:
            "chat-camera"
        case .chatLibrary:
            "chat-library"
        }
    }
}

struct TradeMessageInputActionPolicy: Equatable, Sendable {
    var proposalStatus: ProposalStatus
    var supportsHandExchange: Bool
    var showsCounterProposal: Bool

    var quickActions: [TradeMessageQuickActionKind] {
        if proposalStatus == .agreed {
            var actions: [TradeMessageQuickActionKind] = []
            if supportsHandExchange {
                actions.append(.location)
            }
            return actions
        }

        var actions: [TradeMessageQuickActionKind] = [.schedule]
        if showsCounterProposal {
            actions.append(.counterProposal)
        }
        return actions
    }

    var overflowActions: [TradeMessageOverflowActionKind] {
        if proposalStatus == .agreed {
            var actions: [TradeMessageOverflowActionKind] = []
            if supportsHandExchange {
                actions.append(.location)
            }
            actions.append(contentsOf: [
                .chatCamera,
                .chatLibrary
            ])
            return actions
        }

        var actions: [TradeMessageOverflowActionKind] = [.schedule]
        if showsCounterProposal {
            actions.append(.counterProposal)
        }
        actions.append(contentsOf: [.chatCamera, .chatLibrary])
        return actions
    }
}

struct TradeMessageInputContext: Equatable, Sendable {
    var isSending: Bool
    var canUseCamera: Bool
    var actionPolicy: TradeMessageInputActionPolicy

    init(
        isSending: Bool,
        canUseCamera: Bool,
        proposalStatus: ProposalStatus,
        supportsHandExchange: Bool,
        showsCounterProposal: Bool
    ) {
        self.init(
            isSending: isSending,
            canUseCamera: canUseCamera,
            actionPolicy: TradeMessageInputActionPolicy(
                proposalStatus: proposalStatus,
                supportsHandExchange: supportsHandExchange,
                showsCounterProposal: showsCounterProposal
            )
        )
    }

    init(
        isSending: Bool,
        canUseCamera: Bool,
        actionPolicy: TradeMessageInputActionPolicy
    ) {
        self.isSending = isSending
        self.canUseCamera = canUseCamera
        self.actionPolicy = actionPolicy
    }

    var quickActions: [TradeMessageQuickActionKind] {
        actionPolicy.quickActions
    }

    var overflowActions: [TradeMessageOverflowActionKind] {
        actionPolicy.overflowActions
    }

    func shouldShowQuickActions(isComposerFocused: Bool) -> Bool {
        !isComposerFocused && !quickActions.isEmpty
    }
}

enum TradeUnavailableChatAction: String, Identifiable {
    case location
    case photo
    case outfitPhoto

    var id: String { rawValue }

    var title: String {
        switch self {
        case .location:
            "現在地を共有"
        case .photo:
            "写真を送信"
        case .outfitPhoto:
            "服装写真を共有"
        }
    }

    var systemImage: String {
        switch self {
        case .location:
            "location.fill"
        case .photo:
            "photo.on.rectangle"
        case .outfitPhoto:
            "person.crop.rectangle"
        }
    }

    var description: String {
        switch self {
        case .location:
            "現在地を取得できませんでした。端末の位置情報許可を確認してください。"
        case .photo:
            "写真を送信できませんでした。写真の選択権限と通信状態を確認してください。"
        case .outfitPhoto:
            "服装写真を送信できませんでした。写真の選択権限と通信状態を確認してください。"
        }
    }
}
