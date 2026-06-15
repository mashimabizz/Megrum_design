import Foundation
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

enum TradeAssistanceRequestKind: String, CaseIterable, Identifiable, Sendable {
    case late
    case cancel

    var id: String { rawValue }

    var title: String {
        switch self {
        case .late:
            "遅刻を申請"
        case .cancel:
            "キャンセル申請"
        }
    }

    var systemImage: String {
        switch self {
        case .late:
            "clock.badge.exclamationmark"
        case .cancel:
            "xmark.circle"
        }
    }

    var messagePrefix: String {
        switch self {
        case .late:
            "遅刻申請"
        case .cancel:
            "キャンセル申請"
        }
    }

    var reasonPlaceholder: String {
        switch self {
        case .late:
            "遅れる理由"
        case .cancel:
            "キャンセルが必要な理由"
        }
    }

    var notePlaceholder: String {
        switch self {
        case .late:
            "待ち合わせ場所への向かい方や到着見込みなど（任意）"
        case .cancel:
            "相手への補足や代替案など（任意）"
        }
    }

    var acknowledgementText: String {
        switch self {
        case .late:
            "遅刻連絡が相手の判断材料になることを確認しました。"
        case .cancel:
            "キャンセル申請後も相手の確認が必要なことを確認しました。"
        }
    }

    var placeholder: String {
        reasonPlaceholder
    }

    var menuAccessibilityLabel: String {
        switch self {
        case .late:
            "遅刻申請を開く"
        case .cancel:
            "キャンセル申請を開く"
        }
    }

    var reasonAccessibilityLabel: String {
        switch self {
        case .late:
            "遅刻理由"
        case .cancel:
            "キャンセル理由"
        }
    }

    var noteAccessibilityLabel: String {
        switch self {
        case .late:
            "遅刻申請の補足"
        case .cancel:
            "キャンセル申請の補足"
        }
    }

    var acknowledgementAccessibilityLabel: String {
        switch self {
        case .late:
            "遅刻申請の確認事項"
        case .cancel:
            "キャンセル申請の確認事項"
        }
    }

    func systemMessageBody(from memo: String) -> String {
        let draft = TradeAssistanceRequestDraft(
            kind: self,
            reason: memo,
            acknowledgesImpact: true
        )
        return draft.systemIntent?.messageBody ?? messagePrefix
    }
}

enum TradeLateDelayBucket: Int, CaseIterable, Identifiable, Equatable, Sendable {
    case ten = 10
    case twenty = 20
    case thirty = 30
    case sixty = 60
    case ninety = 90

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .ten, .twenty, .thirty:
            "\(rawValue)分"
        case .sixty:
            "1時間"
        case .ninety:
            "1時間以上"
        }
    }

    var accessibilityLabel: String {
        "遅れる見込み \(title)"
    }
}

struct TradeAssistanceSystemIntent: Equatable, Sendable {
    enum Action: String, Equatable, Sendable {
        case lateNotice = "late_notice"
        case cancelRequested = "cancel_requested"
    }

    var kind: TradeAssistanceRequestKind
    var action: Action
    var delayBucket: TradeLateDelayBucket?
    var reason: String
    var note: String?
    var acknowledgedImpact: Bool

    var lateMinutes: Int? {
        delayBucket?.rawValue
    }

    var metadata: [String: String] {
        var values = [
            "action": action.rawValue,
            "reason": reason
        ]
        if let lateMinutes {
            values["late_minutes"] = "\(lateMinutes)"
        }
        if let note {
            values["note"] = note
        }
        return values
    }

    var messageBody: String {
        let noteSuffix = note.map { "\n\($0)" } ?? ""
        switch kind {
        case .late:
            let delay = delayBucket?.title ?? TradeLateDelayBucket.ten.title
            return "\(delay)遅れる旨が通知されました\n理由：\(reason)\(noteSuffix)"
        case .cancel:
            return "取引キャンセルが申請されました\n理由：\(reason)\(noteSuffix)"
        }
    }
}

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

struct TradeAssistanceRequestDraft: Equatable, Sendable {
    var kind: TradeAssistanceRequestKind
    var delayBucket: TradeLateDelayBucket = .ten
    var reason: String = ""
    var note: String = ""
    var acknowledgesImpact = false

    var normalizedReason: String {
        reason.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedNote: String? {
        note.nilIfBlank
    }

    var isSubmittable: Bool {
        !normalizedReason.isEmpty && acknowledgesImpact
    }

    var systemIntent: TradeAssistanceSystemIntent? {
        guard isSubmittable else {
            return nil
        }

        switch kind {
        case .late:
            return TradeAssistanceSystemIntent(
                kind: kind,
                action: .lateNotice,
                delayBucket: delayBucket,
                reason: normalizedReason,
                note: normalizedNote,
                acknowledgedImpact: acknowledgesImpact
            )
        case .cancel:
            return TradeAssistanceSystemIntent(
                kind: kind,
                action: .cancelRequested,
                delayBucket: nil,
                reason: normalizedReason,
                note: normalizedNote,
                acknowledgedImpact: acknowledgesImpact
            )
        }
    }
}
