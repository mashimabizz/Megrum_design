import MegrumCore
import MegrumDesign
import Foundation
import PhotosUI
import SwiftUI
#if os(iOS)
import UIKit
#endif

struct TradesScreen: View {
    @ObservedObject var appState: MegrumAppState
    @Binding var requestedStage: TradeStage?

    @State private var selectedStage: TradeStage = .pending
    @State private var selectedProposal: TradeProposal?

    private var proposals: [TradeProposal] {
        appState.proposals
    }

    private var visibleProposals: [TradeProposal] {
        proposals
            .filter { selectedStage.contains($0.status) }
            .sorted(by: compareForRnPendingList)
    }

    private var goodsByID: [UUID: GoodsItem] {
        var lookup: [UUID: GoodsItem] = [:]
        let localWishGoods = appState.wishes.map {
            GoodsItem(
                id: $0.id,
                ownerID: $0.ownerID,
                kind: .wish,
                status: .active,
                groupID: $0.groupID,
                memberID: $0.memberID,
                goodsTypeID: $0.goodsTypeID,
                title: $0.title,
                imageURL: $0.imageURL,
                tags: $0.tags,
                quantity: $0.quantity
            )
        }
        let allKnownGoods = appState.inventory
            + appState.homeMatchedItems
            + appState.homePossibleItems
            + localWishGoods
            + appState.publicTradeGoodsByUserID.values.flatMap { $0 }
        for item in allKnownGoods {
            lookup[item.id] = item
        }
        return lookup
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if visibleProposals.isEmpty {
                    EmptyTradeStage(stage: selectedStage)
                } else {
                    ForEach(visibleProposals) { proposal in
                        TradeCard(
                            proposal: proposal,
                            viewerID: appState.viewer?.id,
                            profilesByUserID: appState.publicProfilesByUserID,
                            goodsByID: goodsByID
                        ) {
                            selectedProposal = proposal
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 132)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .megrumHiddenNavigationBar()
        .safeAreaInset(edge: .bottom) {
            TradeStageBar(
                selectedStage: $selectedStage,
                pendingCount: proposals.filter { TradeStage.pending.contains($0.status) }.count,
                inProgressCount: proposals.filter { TradeStage.inProgress.contains($0.status) }.count,
                completedCount: proposals.filter { TradeStage.completed.contains($0.status) }.count
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
        }
        .gesture(
            DragGesture(minimumDistance: 32)
                .onEnded { value in
                    if value.translation.width < -44 {
                        selectedStage = selectedStage.next
                    } else if value.translation.width > 44 {
                        selectedStage = selectedStage.previous
                    }
                }
        )
        .sheet(item: $selectedProposal) { proposal in
            NavigationStack {
                TradeDetailScreen(appState: appState, proposal: proposal)
            }
        }
        .onAppear {
            consumeRequestedStage()
        }
        .onChange(of: requestedStage) { _, _ in
            consumeRequestedStage()
        }
        .task(id: partnerProfileTaskKey) {
            for userID in visiblePartnerIDs where appState.publicProfilesByUserID[userID] == nil {
                await appState.loadPublicUserProfile(userID: userID)
            }
        }
    }

    private var selectedStageSubtitle: String {
        "\(selectedStage.subtitle) ・ \(visibleProposals.count)件"
    }

    private var partnerProfileTaskKey: String {
        visiblePartnerIDs
            .map(\.uuidString)
            .sorted()
            .joined(separator: ",")
    }

    private var visiblePartnerIDs: [UUID] {
        guard let viewerID = appState.viewer?.id else {
            return []
        }
        var seen: Set<UUID> = []
        return visibleProposals.compactMap { proposal in
            guard let partnerID = proposal.partnerID(for: viewerID), !seen.contains(partnerID) else {
                return nil
            }
            seen.insert(partnerID)
            return partnerID
        }
    }

    private func compareForRnPendingList(_ lhs: TradeProposal, _ rhs: TradeProposal) -> Bool {
        let lhsPriority = rnPendingPriority(for: lhs)
        let rhsPriority = rnPendingPriority(for: rhs)
        if lhsPriority != rhsPriority {
            return lhsPriority < rhsPriority
        }
        return lhs.createdAt > rhs.createdAt
    }

    private func rnPendingPriority(for proposal: TradeProposal) -> Int {
        switch proposal.status {
        case .negotiating:
            return 0
        case .agreementOneSide:
            return 1
        case .sent:
            return proposal.senderID == appState.viewer?.id ? 2 : 3
        case .agreed:
            return 4
        case .completed:
            return 5
        case .cancelled, .rejected, .expired:
            return 6
        case .draft:
            return 7
        }
    }

    private func consumeRequestedStage() {
        guard let requestedStage else {
            return
        }
        selectedStage = TradeStageRouteRequestResolver.resolve(
            current: selectedStage,
            requested: requestedStage
        )
        self.requestedStage = nil
    }
}

enum TradeStageRouteRequestResolver {
    static func resolve(current: TradeStage, requested: TradeStage?) -> TradeStage {
        requested ?? current
    }
}

struct TradeCardPresentation: Equatable {
    var partnerHandle: String
    var partnerInitial: String
    var updatedText: String
    var directionText: String
    var isReceived: Bool
    var statusText: String
    var responseText: String?
    var needsAction: Bool
    var tone: Tone
    var meetupTimeText: String
    var meetupPlaceText: String

    enum Tone: Equatable {
        case action
        case live
        case idle
    }

    init(
        proposal: TradeProposal,
        viewerID: UUID?,
        profilesByUserID: [UUID: PublicUserProfile],
        now: Date = .now
    ) {
        let partnerID = viewerID.flatMap { proposal.partnerID(for: $0) }
            ?? proposal.receiverID
        let handle = profilesByUserID[partnerID]?.profile.handle
            ?? Self.fallbackHandle(for: partnerID)
        self.partnerHandle = handle
        self.partnerInitial = String(handle.prefix(1)).uppercased()
        self.updatedText = Self.relativeTimeText(from: proposal.createdAt, now: now)
        self.isReceived = viewerID.map { proposal.receiverID == $0 } ?? false
        self.directionText = isReceived ? "届いた" : "送った"
        self.needsAction = Self.needsAction(proposal: proposal, viewerID: viewerID)
        self.statusText = Self.statusText(for: proposal.status, needsAction: needsAction)
        self.responseText = Self.responseText(for: proposal.status, needsAction: needsAction)
        self.tone = needsAction ? .action : (proposal.status == .agreed ? .live : .idle)
        self.meetupTimeText = Self.meetupTimeText(for: proposal)
        self.meetupPlaceText = Self.meetupPlaceText(for: proposal)
    }

    private static func fallbackHandle(for userID: UUID) -> String {
        "user_\(userID.uuidString.prefix(4).lowercased())"
    }

    private static func needsAction(proposal: TradeProposal, viewerID: UUID?) -> Bool {
        guard let viewerID else {
            return false
        }
        switch proposal.status {
        case .sent:
            return proposal.receiverID == viewerID
        case .negotiating:
            return proposal.receiverID == viewerID
        case .agreementOneSide:
            return !proposal.agreementBy(viewerID)
        case .agreed:
            return false
        case .draft, .completed, .cancelled, .rejected, .expired:
            return false
        }
    }

    static func statusText(for status: ProposalStatus, needsAction: Bool) -> String {
        switch status {
        case .draft:
            return "下書き"
        case .sent:
            return needsAction ? "新着打診" : "送信済み"
        case .negotiating:
            return needsAction ? "返信が届いています" : "ネゴ中"
        case .agreementOneSide:
            return needsAction ? "合意待ち" : "相手の合意待ち"
        case .agreed:
            return needsAction ? "要確認" : "取引予定"
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

    static func responseText(for status: ProposalStatus, needsAction: Bool) -> String? {
        switch status {
        case .sent, .negotiating, .agreementOneSide:
            return needsAction ? "要対応" : "相手待ち"
        default:
            return nil
        }
    }

    private static func relativeTimeText(from date: Date, now: Date) -> String {
        let seconds = max(0, Int(now.timeIntervalSince(date)))
        if seconds < 60 {
            return "たった今"
        }
        let minutes = seconds / 60
        if minutes < 60 {
            return "\(minutes)分前"
        }
        let hours = minutes / 60
        if hours < 24 {
            return "\(hours)時間前"
        }
        return "\(hours / 24)日前"
    }

    private static func meetupTimeText(for proposal: TradeProposal) -> String {
        proposal.status == .agreed ? "今日 18:15 - 18:45" : "候補確認中"
    }

    private static func meetupPlaceText(for proposal: TradeProposal) -> String {
        switch proposal.exchangeMethod {
        case .hand:
            return proposal.status == .agreed ? "横浜アリーナ 北口" : "横浜アリーナ"
        case .mail:
            return "住所確認中"
        case .both:
            return "どちらもOK"
        }
    }
}

private struct TradeCard: View {
    private static let actionColor = Color(red: 0.84, green: 0.46, blue: 0.36)
    private static let calmColor = Color(red: 0.23, green: 0.49, blue: 0.58)

    var proposal: TradeProposal
    var viewerID: UUID?
    var profilesByUserID: [UUID: PublicUserProfile] = [:]
    var goodsByID: [UUID: GoodsItem] = [:]
    var onOpen: () -> Void

    private var presentation: TradeCardPresentation {
        TradeCardPresentation(
            proposal: proposal,
            viewerID: viewerID,
            profilesByUserID: profilesByUserID
        )
    }

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 7) {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(MegrumTheme.lavender.opacity(0.16))
                        .frame(width: 28, height: 28)
                        .overlay {
                            Text(presentation.partnerInitial)
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundStyle(MegrumTheme.lavender)
                        }

                    VStack(alignment: .leading, spacing: 1) {
                        Text("@\(presentation.partnerHandle)")
                            .font(.system(size: 11.5, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink)
                            .lineLimit(1)
                        Text(presentation.updatedText)
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                    }

                    Spacer(minLength: 8)

                    Text(presentation.directionText)
                        .font(.system(size: 9.5, weight: .black, design: .rounded))
                        .foregroundStyle(directionForegroundColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(directionBackgroundColor, in: Capsule())
                }

                HStack(spacing: 8) {
                    Text(presentation.statusText)
                        .font(.system(size: 10.5, weight: .black, design: .rounded))
                        .foregroundStyle(statusColor)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(statusColor.opacity(0.12), in: Capsule())

                    if let responseText = presentation.responseText {
                        Text(responseText)
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(responseColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(responseColor.opacity(0.10), in: Capsule())
                    }

                    Spacer(minLength: 0)
                }
                .padding(.top, 9)

                TradePairPreview(
                    receiverItems: previewItems(for: proposal.receiverGoodsIDs),
                    senderItems: previewItems(for: proposal.senderGoodsIDs)
                )
                .padding(9)
                .background(MegrumTheme.sky.opacity(0.10), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                .padding(.top, 9)

                HStack(spacing: 8) {
                    Text(presentation.meetupTimeText)
                        .font(.system(size: 10.5, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Text(presentation.meetupPlaceText)
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .lineLimit(1)
                }
                .padding(.top, 9)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(alignment: .leading) {
                if presentation.needsAction {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(Self.actionColor)
                        .frame(width: 3)
                        .padding(.vertical, 12)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(cardBorderColor, lineWidth: presentation.needsAction ? 1.4 : 1)
            }
            .shadow(color: MegrumTheme.ink.opacity(0.04), radius: 14, y: 8)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("取引詳細を開きます")
    }

    private var statusColor: Color {
        switch presentation.tone {
        case .action:
            Self.actionColor
        case .live:
            Self.calmColor
        case .idle:
            MegrumTheme.ink
        }
    }

    private var cardBorderColor: Color {
        presentation.needsAction ? Self.actionColor.opacity(0.24) : MegrumTheme.ink.opacity(0.08)
    }

    private var directionForegroundColor: Color {
        presentation.isReceived ? MegrumTheme.lavender : Self.calmColor
    }

    private var directionBackgroundColor: Color {
        if presentation.isReceived {
            return MegrumTheme.lavender.opacity(0.14)
        }
        return MegrumTheme.sky.opacity(0.22)
    }

    private var responseColor: Color {
        presentation.needsAction ? Self.actionColor : Self.calmColor
    }

    private func previewItems(for ids: [UUID]) -> [GoodsItem] {
        ids.compactMap { goodsByID[$0] }
    }

    private var accessibilityLabel: String {
        var parts = [
            "取引",
            presentation.statusText,
            proposal.exchangeMethod.displayName,
            "受け取る \(proposal.receiverGoodsIDs.count)件",
            "私が出す \(proposal.senderGoodsIDs.count)件"
        ]
        if !proposal.conditionTags.isEmpty {
            parts.append("条件 \(proposal.conditionTags.joined(separator: "、"))")
        }
        return parts.joined(separator: "、")
    }
}

enum TradeStage: String, CaseIterable, Identifiable {
    case pending
    case inProgress
    case completed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pending:
            "打診中"
        case .inProgress:
            "進行中"
        case .completed:
            "完了済み"
        }
    }

    var subtitle: String {
        switch self {
        case .pending:
            "送信済み・調整中の打診"
        case .inProgress:
            "成立後の取引"
        case .completed:
            "完了・キャンセル・終了した取引"
        }
    }

    func contains(_ status: ProposalStatus) -> Bool {
        switch self {
        case .pending:
            [.draft, .sent, .negotiating, .agreementOneSide].contains(status)
        case .inProgress:
            status == .agreed
        case .completed:
            [.completed, .cancelled, .rejected, .expired].contains(status)
        }
    }

    var next: TradeStage {
        switch self {
        case .pending:
            .inProgress
        case .inProgress:
            .completed
        case .completed:
            .completed
        }
    }

    var previous: TradeStage {
        switch self {
        case .pending:
            .pending
        case .inProgress:
            .pending
        case .completed:
            .inProgress
        }
    }

    var emptyTitle: String {
        switch self {
        case .pending:
            "打診中の取引はありません"
        case .inProgress:
            "進行中の取引はありません"
        case .completed:
            "完了済みの取引はありません"
        }
    }

    var emptyMessage: String {
        switch self {
        case .pending:
            "送信済み・調整中の打診が届くとここに表示されます。"
        case .inProgress:
            "成立した取引はここから取引チャットを開けます。"
        case .completed:
            "完了後の証跡・評価や終了した打診をここから確認できます。"
        }
    }
}

private extension TradeProposal {
    var isProposalResponsePending: Bool {
        [.sent, .negotiating, .agreementOneSide].contains(status)
    }
}

enum TradeArrivalQuickAction: String, CaseIterable, Identifiable {
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

private enum TradeUnavailableChatAction: String, Identifiable {
    case location
    case outfitPhoto

    var id: String { rawValue }

    var title: String {
        switch self {
        case .location:
            "現在地を共有"
        case .outfitPhoto:
            "服装写真を共有"
        }
    }

    var systemImage: String {
        switch self {
        case .location:
            "location.fill"
        case .outfitPhoto:
            "person.crop.rectangle"
        }
    }

    var description: String {
        switch self {
        case .location:
            "現在地を取得できませんでした。端末の位置情報許可を確認してください。"
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

struct TradeEvaluationPromptState: Equatable, Sendable {
    var hasSubmittedEvaluation: Bool

    init(
        proposal: TradeProposal,
        viewerID: UUID?,
        messages: [TradeMessage],
        localSubmission: Bool = false
    ) {
        guard proposal.status == .completed, let viewerID else {
            self.hasSubmittedEvaluation = false
            return
        }
        self.hasSubmittedEvaluation = localSubmission || messages.contains { message in
            Self.isViewerEvaluationMessage(message, viewerID: viewerID)
        }
    }

    private static func isViewerEvaluationMessage(_ message: TradeMessage, viewerID: UUID) -> Bool {
        guard message.senderID == viewerID, message.messageType == .system else {
            return false
        }
        if message.meta["action"] == "evaluation_submitted" || message.meta["event_type"] == "evaluation_submitted" {
            return true
        }
        return message.body?.contains("取引評価を送信しました") == true
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
        note.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
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

struct TradeDisputeSummary: Identifiable, Equatable, Sendable {
    var id: UUID
    var sourceMessageID: UUID
    var proposalID: UUID
    var reporterID: UUID
    var ticketNo: String
    var status: DisputeDetailStatus
    var category: TradeDisputeCategory?
    var factMemo: String?
    var body: String
    var submittedAt: Date

    init?(message: TradeMessage) {
        guard message.messageType == .system else {
            return nil
        }

        let body = message.body?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        let ticketNo = message.meta.firstNonBlank([
            "ticket_no",
            "ticketNo",
            "dispute_ticket_no",
            "disputeTicketNo"
        ]) ?? body?.firstDisputeTicketNumber
        let action = message.meta.firstNonBlank(["action", "event"])
        let hasDisputeAction = action.map(Self.isDisputeAction) ?? false
        let hasDisputeBody = body?.contains("申告") == true

        guard ticketNo != nil || hasDisputeAction || hasDisputeBody else {
            return nil
        }

        self.id = message.meta.uuidValue(for: ["dispute_id", "disputeID", "ticket_id", "ticketID"]) ?? message.id
        self.sourceMessageID = message.id
        self.proposalID = message.proposalID
        self.reporterID = message.senderID
        self.ticketNo = ticketNo ?? "受付済み"
        self.status = Self.status(from: message.meta, action: action)
        self.category = message.meta.firstNonBlank(["category", "dispute_category"]).flatMap(TradeDisputeCategory.init(rawValue:))
        self.factMemo = message.meta.firstNonBlank(["fact_memo", "factMemo", "memo"])
        self.body = body ?? "取引の申告を受け付けました。"
        self.submittedAt = message.createdAt
    }

    var bannerTitle: String {
        switch status {
        case .resolved:
            "申告の結果が届いています"
        case .withdrawn:
            "申告は取り下げ済みです"
        case .replyReceived, .arbitration:
            "申告を運営が確認中です"
        default:
            "申告を受け付けました"
        }
    }

    var bannerBody: String {
        if ticketNo == "受付済み" {
            return status.displayName
        }
        return "\(ticketNo) · \(status.displayName)"
    }

    func detailModel(proposal: TradeProposal, viewerID: UUID?) -> DisputeDetailModel {
        let respondentID = proposal.partnerID(for: reporterID)
            ?? viewerID.flatMap { proposal.partnerID(for: $0) }
            ?? proposal.receiverID
        let viewerRole: DisputeDetailViewerRole?
        if viewerID == reporterID {
            viewerRole = .reporter
        } else if viewerID == respondentID {
            viewerRole = .respondent
        } else {
            viewerRole = nil
        }

        let reporterName = viewerRole == .reporter ? "あなた" : "相手"
        let respondentName = viewerRole == .respondent ? "あなた" : "相手"
        let safeStatus = status.interactionSafeFallback

        return DisputeDetailModel(
            id: id,
            proposalID: proposalID,
            reporterID: reporterID,
            respondentID: respondentID,
            viewerRole: viewerRole,
            ticketNo: ticketNo,
            status: safeStatus,
            category: category,
            reporterName: reporterName,
            respondentName: respondentName,
            factMemo: factMemo,
            submittedAt: submittedAt,
            messages: [
                DisputeDetailMessageModel(
                    id: sourceMessageID,
                    senderID: nil,
                    senderRole: .operator,
                    senderName: "運営",
                    body: body,
                    createdAt: submittedAt
                )
            ]
        )
    }

    private static func isDisputeAction(_ action: String) -> Bool {
        action.hasPrefix("dispute_") || action == "dispute"
    }

    private static func status(from meta: [String: String], action: String?) -> DisputeDetailStatus {
        if let rawStatus = meta.firstNonBlank(["dispute_status", "status"]) {
            return DisputeDetailStatus(rawStatus: rawStatus)
        }

        switch action {
        case "dispute_closed":
            return .resolved
        case "dispute_responded":
            return .replyReceived
        case "dispute_withdrawn":
            return .withdrawn
        case "dispute_received", "dispute_created", "dispute":
            return .submitted
        default:
            return .submitted
        }
    }
}

struct TradeDayOfBannerPresentation: Equatable, Sendable {
    var myArrivalText: String
    var partnerArrivalText: String
    var myOutfitText: String
    var partnerOutfitText: String
    var promptText: String

    init?(proposal: TradeProposal, messages: [TradeMessage], viewerID: UUID?) {
        guard [.agreed, .completed].contains(proposal.status) else {
            return nil
        }

        let myArrival = viewerID.flatMap { Self.latestArrivalStatus(in: messages, senderID: $0) }
        let partnerArrival = Self.latestPartnerArrivalStatus(in: messages, viewerID: viewerID)
        let hasMyOutfit = viewerID.map { Self.hasOutfitPhoto(in: messages, senderID: $0) } ?? false
        let hasPartnerOutfit = Self.hasPartnerOutfitPhoto(in: messages, viewerID: viewerID)

        self.myArrivalText = Self.arrivalText(myArrival, fallback: "未共有")
        self.partnerArrivalText = Self.arrivalText(partnerArrival, fallback: "未共有")
        self.myOutfitText = hasMyOutfit ? "共有済み" : "未共有"
        self.partnerOutfitText = hasPartnerOutfit ? "共有済み" : "未共有"
        if myArrival == .arrived {
            self.promptText = "必要に応じて現在地や服装写真を更新できます。"
        } else if hasMyOutfit {
            self.promptText = "到着したらステータスを共有すると合流しやすくなります。"
        } else {
            self.promptText = "現在地、到着、服装写真を当日の判断材料として残せます。"
        }
    }

    private static func latestArrivalStatus(in messages: [TradeMessage], senderID: UUID) -> TradeArrivalStatus? {
        messages
            .filter { $0.senderID == senderID && $0.messageType == .arrivalStatus }
            .sorted { $0.createdAt < $1.createdAt }
            .last
            .flatMap { $0.meta["status"].flatMap(TradeArrivalStatus.init(rawValue:)) }
    }

    private static func latestPartnerArrivalStatus(in messages: [TradeMessage], viewerID: UUID?) -> TradeArrivalStatus? {
        messages
            .filter { message in
                message.messageType == .arrivalStatus && viewerID.map { message.senderID != $0 } != false
            }
            .sorted { $0.createdAt < $1.createdAt }
            .last
            .flatMap { $0.meta["status"].flatMap(TradeArrivalStatus.init(rawValue:)) }
    }

    private static func hasOutfitPhoto(in messages: [TradeMessage], senderID: UUID) -> Bool {
        messages.contains { $0.senderID == senderID && $0.messageType == .outfitPhoto }
    }

    private static func hasPartnerOutfitPhoto(in messages: [TradeMessage], viewerID: UUID?) -> Bool {
        messages.contains { message in
            message.messageType == .outfitPhoto && viewerID.map { message.senderID != $0 } != false
        }
    }

    private static func arrivalText(_ status: TradeArrivalStatus?, fallback: String) -> String {
        switch status {
        case .enroute:
            "移動中"
        case .arrived:
            "到着済み"
        case .left:
            "離れました"
        case .none:
            fallback
        }
    }
}

private struct TradeDisputeDetailRoute: Identifiable, Equatable, Hashable {
    var summary: TradeDisputeSummary
    var model: DisputeDetailModel

    var id: UUID { summary.id }

    static func == (lhs: TradeDisputeDetailRoute, rhs: TradeDisputeDetailRoute) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

private extension DisputeDetailStatus {
    var interactionSafeFallback: DisputeDetailStatus {
        switch self {
        case .filed, .submitted, .replyWindow:
            .arbitration
        default:
            self
        }
    }
}

private extension Dictionary where Key == String, Value == String {
    func firstNonBlank(_ keys: [String]) -> String? {
        for key in keys {
            if let value = self[key]?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty {
                return value
            }
        }
        return nil
    }

    func uuidValue(for keys: [String]) -> UUID? {
        firstNonBlank(keys).flatMap(UUID.init(uuidString:))
    }
}

private extension String {
    var firstDisputeTicketNumber: String? {
        let pattern = #"#?(DPT-[A-Z0-9-]+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }
        let range = NSRange(startIndex..<endIndex, in: self)
        guard let match = regex.firstMatch(in: self, range: range),
              let ticketRange = Range(match.range(at: 1), in: self)
        else {
            return nil
        }
        return String(self[ticketRange])
    }
}

private struct TradeStageBar: View {
    @Binding var selectedStage: TradeStage
    var pendingCount: Int
    var inProgressCount: Int
    var completedCount: Int

    var body: some View {
        HStack(spacing: 8) {
            stageButton(.pending, count: pendingCount)
            stageButton(.inProgress, count: inProgressCount)
            stageButton(.completed, count: completedCount)
        }
        .padding(7)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.72), lineWidth: 1))
        .shadow(color: MegrumTheme.ink.opacity(0.12), radius: 18, y: 10)
    }

    private func stageButton(_ stage: TradeStage, count: Int) -> some View {
        Button {
            selectedStage = stage
        } label: {
            HStack(spacing: 7) {
                Text(stage.title)
                Text("\(count)")
                    .foregroundStyle(selectedStage == stage ? MegrumTheme.lavender : MegrumTheme.sky)
            }
            .font(.system(size: 16, weight: .heavy, design: .rounded))
            .foregroundStyle(selectedStage == stage ? MegrumTheme.ink : MegrumTheme.muted)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(selectedStage == stage ? AnyShapeStyle(.white.opacity(0.9)) : AnyShapeStyle(.clear), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(stage.title) \(count)件")
        .accessibilityHint("やりとり一覧を\(stage.title)に切り替えます")
    }
}

private struct EmptyTradeStage: View {
    var stage: TradeStage

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(MegrumTheme.lavender)

            Text(stage.emptyTitle)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Text(stage.emptyMessage)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 18)
        .padding(.vertical, 30)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.62), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(stage.emptyTitle)。\(stage.emptyMessage)")
    }
}

private struct TradeDetailScreen: View {
    @ObservedObject var appState: MegrumAppState
    var proposal: TradeProposal
    @Environment(\.dismiss) private var dismiss
    @State private var draftMessage = ""
    @State private var selectedEvidencePhotoItem: PhotosPickerItem?
    @State private var selectedOutfitPhotoItem: PhotosPickerItem?
    @State private var isShowingEvidenceCamera = false
    @State private var isShowingOutfitCamera = false
    @State private var isShowingEvaluationSheet = false
    @State private var isShowingDisputeSheet = false
    @State private var isShowingRejectConfirmation = false
    @State private var isShowingCounterProposalSheet = false
    @State private var isShowingScheduleSheet = false
    @State private var unavailableChatAction: TradeUnavailableChatAction?
    @State private var assistanceRequestKind: TradeAssistanceRequestKind?
    @State private var selectedRemoteImage: RemoteImageSelection?
    @State private var isWaitingToShareLocation = false
    @State private var disputeDetailRoute: TradeDisputeDetailRoute?
    @State private var didSubmitEvaluation = false
    @StateObject private var locationState = MegrumLocationState()

    private var messages: [TradeMessage] {
        appState.messages(for: proposal.id)
    }

    private var currentProposal: TradeProposal {
        appState.proposals.first { $0.id == proposal.id } ?? proposal
    }

    private var goodsByID: [UUID: GoodsItem] {
        var lookup: [UUID: GoodsItem] = [:]
        let localWishGoods = appState.wishes.map {
            GoodsItem(
                id: $0.id,
                ownerID: $0.ownerID,
                kind: .wish,
                status: .active,
                groupID: $0.groupID,
                memberID: $0.memberID,
                goodsTypeID: $0.goodsTypeID,
                title: $0.title,
                imageURL: $0.imageURL,
                tags: $0.tags,
                quantity: $0.quantity
            )
        }
        let allKnownGoods = appState.inventory
            + appState.homeMatchedItems
            + appState.homePossibleItems
            + localWishGoods
            + appState.publicTradeGoodsByUserID.values.flatMap { $0 }
        for item in allKnownGoods {
            lookup[item.id] = item
        }
        return lookup
    }

    private var latestDisputeSummary: TradeDisputeSummary? {
        messages
            .compactMap(TradeDisputeSummary.init(message:))
            .max { $0.submittedAt < $1.submittedAt }
    }

    private var chatInputAvailability: TradeChatInputAvailability {
        TradeChatInputAvailability(proposal: currentProposal)
    }

    private var evaluationPromptState: TradeEvaluationPromptState {
        TradeEvaluationPromptState(
            proposal: currentProposal,
            viewerID: appState.viewer?.id,
            messages: messages,
            localSubmission: didSubmitEvaluation
        )
    }

    var body: some View {
        bodyBeforeDialogs
        .confirmationDialog(
            "この打診を断りますか？",
            isPresented: $isShowingRejectConfirmation,
            titleVisibility: .visible
        ) {
            Button("断る", role: .destructive) {
                Task {
                    await appState.rejectProposal(proposalID: currentProposal.id)
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("断った後は、この打診では取引を進められません。")
        }
#if os(iOS)
        .fullScreenCover(item: $selectedRemoteImage) { selection in
            FullScreenRemoteImageView(url: selection.url)
        }
#else
        .sheet(item: $selectedRemoteImage) { selection in
            FullScreenRemoteImageView(url: selection.url)
        }
#endif
#if os(iOS)
        .sheet(isPresented: $isShowingEvidenceCamera) {
            NativeCameraCaptureView { imageData in
                Task {
                    await addEvidence(data: imageData, imageContentType: "image/jpeg")
                }
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $isShowingOutfitCamera) {
            NativeCameraCaptureView { imageData in
                Task {
                    await addChatPhoto(
                        data: imageData,
                        messageType: .outfitPhoto,
                        imageContentType: "image/jpeg"
                    )
                }
            }
            .ignoresSafeArea()
        }
#endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .primaryAction) {
                if let latestDisputeSummary {
                    Button {
                        openDisputeDetail(latestDisputeSummary)
                    } label: {
                        Label("申告詳細", systemImage: "exclamationmark.bubble")
                    }
                } else {
                    Button {
                        isShowingDisputeSheet = true
                    } label: {
                        Label("通報", systemImage: "exclamationmark.bubble")
                    }
                    .disabled(appState.filingDisputeProposalID == currentProposal.id)
                }
            }
        }
    }

    private var bodyBeforeDialogs: some View {
        AnyView(scrollContent)
        .scrollDismissesKeyboard(.interactively)
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            if appState.viewer.map({ currentProposal.isParticipant($0.id) }) == true,
               chatInputAvailability.canSendMessages {
                TradeMessageInput(
                    text: $draftMessage,
                    selectedOutfitPhotoItem: $selectedOutfitPhotoItem,
                    isSending: appState.sendingMessageProposalID == proposal.id,
                    showsCounterProposal: currentProposal.canCreateCounterProposal(from: appState.viewer?.id),
                    onOpenSchedule: {
                        isShowingScheduleSheet = true
                    },
                    onSendArrivalStatus: { action in
                        sendArrivalQuickAction(action)
                    },
                    onOpenLocationPlaceholder: {
                        shareCurrentLocation()
                    },
                    canUseCamera: canUseCamera,
                    onOpenOutfitCamera: {
                        isShowingOutfitCamera = true
                    },
                    onCounterProposal: {
                        isShowingCounterProposalSheet = true
                    },
                    onRequestLate: {
                        assistanceRequestKind = .late
                    },
                    onRequestCancel: {
                        assistanceRequestKind = .cancel
                    },
                    onReport: {
                        isShowingDisputeSheet = true
                    }
                ) {
                    Task {
                        let sent = await appState.sendMessage(proposalID: proposal.id, body: draftMessage)
                        if sent {
                            draftMessage = ""
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.regularMaterial)
            }
        }
        .navigationTitle("取引詳細")
        .megrumInlineNavigationTitle()
        .task {
            await appState.loadMessages(proposalID: proposal.id)
        }
        .onChange(of: selectedEvidencePhotoItem) { _, item in
            guard let item else {
                return
            }
            Task {
                await addEvidence(from: item)
            }
        }
        .onChange(of: selectedOutfitPhotoItem) { _, item in
            guard let item else {
                return
            }
            Task {
                await addChatPhoto(from: item, messageType: .outfitPhoto)
            }
        }
        .sheet(isPresented: $isShowingEvaluationSheet) {
            NavigationStack {
                TradeEvaluationSheet(
                    isSubmitting: appState.submittingEvaluationProposalID == currentProposal.id
                ) { stars, comment in
                    let sent = await appState.submitTradeEvaluation(
                        proposalID: currentProposal.id,
                        stars: stars,
                        comment: comment
                    )
                    if sent {
                        didSubmitEvaluation = true
                        await appState.loadMessages(proposalID: currentProposal.id)
                        isShowingEvaluationSheet = false
                    }
                }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingDisputeSheet) {
            NavigationStack {
                TradeDisputeSheet(
                    isSubmitting: appState.filingDisputeProposalID == currentProposal.id
                ) { category, factMemo in
                    let sent = await appState.fileTradeDispute(
                        proposalID: currentProposal.id,
                        category: category,
                        factMemo: factMemo
                    )
                    if sent {
                        isShowingDisputeSheet = false
                    }
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingCounterProposalSheet) {
            NavigationStack {
                CounterProposalSheet(
                    appState: appState,
                    proposal: currentProposal
                )
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingScheduleSheet) {
            NavigationStack {
                TradeScheduleSheet(appState: appState, proposal: currentProposal)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $unavailableChatAction) { action in
            NavigationStack {
                TradeUnavailableChatActionSheet(action: action)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $assistanceRequestKind) { kind in
            NavigationStack {
                TradeAssistanceRequestSheet(
                    kind: kind,
                    isSubmitting: appState.sendingMessageProposalID == currentProposal.id
                ) { intent in
                    let sent: Bool
                    switch intent.action {
                    case .lateNotice:
                        sent = await appState.sendLateNoticeMessage(
                            proposalID: currentProposal.id,
                            lateMinutes: intent.lateMinutes ?? TradeLateDelayBucket.ten.rawValue,
                            reason: intent.reason,
                            note: intent.note
                        )
                    case .cancelRequested:
                        sent = await appState.sendCancelRequestMessage(
                            proposalID: currentProposal.id,
                            reason: intent.reason,
                            note: intent.note
                        )
                    }
                    if sent {
                        assistanceRequestKind = nil
                    }
                }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .navigationDestination(item: $disputeDetailRoute) { route in
            DisputeDetailScreen(model: route.model)
        }
        .onChange(of: locationState.coordinate) { _, coordinate in
            guard isWaitingToShareLocation, let coordinate else {
                return
            }
            isWaitingToShareLocation = false
            sendLocationMessage(coordinate)
        }
        .onChange(of: locationState.locationErrorMessage) { _, errorMessage in
            guard isWaitingToShareLocation, errorMessage != nil else {
                return
            }
            isWaitingToShareLocation = false
            unavailableChatAction = .location
        }
    }

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ScreenTitle(title: "取引詳細", subtitle: currentProposal.exchangeMethod.displayName)
                TradeCard(proposal: currentProposal, goodsByID: goodsByID) {}
                detailSummarySection
                disputeBannerSection
                proposalResponseSection
                evidenceSection
                dayOfBannerSection
                messagesSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 112)
        }
    }

    private var detailSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            detailRow(title: "ステータス", value: statusText)
            detailRow(title: "交換条件タグ", value: currentProposal.conditionTags.isEmpty ? "未設定" : currentProposal.conditionTags.joined(separator: " / "))
            detailRow(title: "私が出す", value: "\(currentProposal.senderGoodsIDs.count)件")
            detailRow(title: "受け取る", value: "\(currentProposal.receiverGoodsIDs.count)件")
        }
        .padding(18)
        .background(.white.opacity(0.84), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    @ViewBuilder
    private var disputeBannerSection: some View {
        if let latestDisputeSummary {
            TradeDisputeBanner(summary: latestDisputeSummary) {
                openDisputeDetail(latestDisputeSummary)
            }
        }
    }

    @ViewBuilder
    private var proposalResponseSection: some View {
        if currentProposal.isProposalResponsePending {
            TradeProposalResponsePanel(
                proposal: currentProposal,
                viewerID: appState.viewer?.id,
                isResponding: appState.respondingProposalID == currentProposal.id,
                onAgree: { acceptedExchangeMethod in
                    Task {
                        await appState.agreeProposal(
                            proposalID: currentProposal.id,
                            acceptedExchangeMethod: acceptedExchangeMethod
                        )
                    }
                },
                onReject: {
                    isShowingRejectConfirmation = true
                },
                onCounterProposal: {
                    isShowingCounterProposalSheet = true
                }
            )
        }
    }

    @ViewBuilder
    private var evidenceSection: some View {
        if currentProposal.status == .agreed || currentProposal.status == .completed {
            TradeEvidencePanel(
                proposal: currentProposal,
                viewerID: appState.viewer?.id,
                selectedPhotoItem: $selectedEvidencePhotoItem,
                evaluationState: evaluationPromptState,
                isAddingEvidence: appState.addingEvidenceProposalID == currentProposal.id,
                isApproving: appState.approvingEvidenceProposalID == currentProposal.id,
                canUseCamera: canUseCamera,
                onOpenCamera: {
                    isShowingEvidenceCamera = true
                },
                onOpenImage: { url in
                    selectedRemoteImage = RemoteImageSelection(url: url)
                },
                onApprove: {
                    Task {
                        await appState.approveTradeEvidence(proposalID: currentProposal.id)
                    }
                },
                onRate: {
                    isShowingEvaluationSheet = true
                }
            )
        }
    }

    @ViewBuilder
    private var dayOfBannerSection: some View {
        if let dayOfPresentation = TradeDayOfBannerPresentation(
            proposal: currentProposal,
            messages: messages,
            viewerID: appState.viewer?.id
        ) {
            TradeDayOfBanner(
                presentation: dayOfPresentation,
                selectedOutfitPhotoItem: $selectedOutfitPhotoItem,
                isSending: appState.sendingMessageProposalID == proposal.id,
                canUseCamera: canUseCamera,
                onOpenOutfitCamera: {
                    isShowingOutfitCamera = true
                },
                onMarkArrived: {
                    sendArrivalQuickAction(.arrived)
                },
                onShareLocation: {
                    shareCurrentLocation()
                }
            )
        }
    }

    private var messagesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("メッセージ")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                if appState.loadingMessagesProposalID == proposal.id {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            ForEach(messages) { message in
                TradeMessageBubble(
                    message: message,
                    isMine: message.senderID == appState.viewer?.id,
                    cancelApprovalPrompt: TradeCancelApprovalPrompt(
                        message: message,
                        proposal: currentProposal,
                        viewerID: appState.viewer?.id,
                        messages: messages
                    ),
                    isApprovingCancel: appState.respondingProposalID == currentProposal.id,
                    onOpenImage: { url in
                        selectedRemoteImage = RemoteImageSelection(url: url)
                    },
                    onOpenDispute: { summary in
                        openDisputeDetail(summary)
                    },
                    onApproveCancel: {
                        Task {
                            await appState.approveTradeCancel(proposalID: currentProposal.id)
                        }
                    }
                )
            }
        }
    }

    private func openDisputeDetail(_ summary: TradeDisputeSummary) {
        disputeDetailRoute = TradeDisputeDetailRoute(
            summary: summary,
            model: summary.detailModel(proposal: currentProposal, viewerID: appState.viewer?.id)
        )
    }

    private func addEvidence(from item: PhotosPickerItem) async {
        defer {
            selectedEvidencePhotoItem = nil
        }
        guard let data = try? await item.loadTransferable(type: Data.self) else {
            return
        }
        await addEvidence(data: data, imageContentType: inferredEvidenceImageContentType(from: data))
    }

    private func addEvidence(data: Data, imageContentType: String) async {
        _ = await appState.addTradeEvidence(
            proposalID: currentProposal.id,
            imageData: data,
            imageContentType: imageContentType
        )
    }

    private func addChatPhoto(from item: PhotosPickerItem, messageType: TradeMessageType) async {
        defer {
            selectedOutfitPhotoItem = nil
        }
        guard let data = try? await item.loadTransferable(type: Data.self) else {
            unavailableChatAction = .outfitPhoto
            return
        }
        await addChatPhoto(
            data: data,
            messageType: messageType,
            imageContentType: inferredEvidenceImageContentType(from: data)
        )
    }

    private func addChatPhoto(data: Data, messageType: TradeMessageType, imageContentType: String) async {
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
            unavailableChatAction = .outfitPhoto
        }
    }

    private func sendArrivalQuickAction(_ action: TradeArrivalQuickAction) {
        let intent = TradeArrivalStatusSendIntent(action: action)
        Task {
            _ = await appState.sendArrivalStatusMessage(
                proposalID: currentProposal.id,
                status: intent.status,
                body: intent.body
            )
        }
    }

    private func shareCurrentLocation() {
        if let coordinate = locationState.coordinate {
            sendLocationMessage(coordinate)
            return
        }

        isWaitingToShareLocation = true
        locationState.requestCurrentLocation()
    }

    private func sendLocationMessage(_ coordinate: MegrumLocationCoordinate) {
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

    private var canUseCamera: Bool {
#if os(iOS)
        UIImagePickerController.isSourceTypeAvailable(.camera)
#else
        false
#endif
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
        }
    }

    private var statusText: String {
        switch currentProposal.status {
        case .draft:
            "下書き"
        case .sent:
            "打診中"
        case .negotiating:
            "調整中"
        case .agreementOneSide:
            "合意待ち"
        case .agreed:
            "進行中"
        case .rejected:
            "拒否済"
        case .expired:
            "期限切れ"
        case .cancelled:
            "キャンセル済"
        case .completed:
            evaluationPromptState.hasSubmittedEvaluation ? "評価済み" : "完了"
        }
    }
}

private struct TradeProposalResponsePanel: View {
    var proposal: TradeProposal
    var viewerID: UUID?
    var isResponding: Bool
    var onAgree: (ExchangeMethod?) -> Void
    var onReject: () -> Void
    var onCounterProposal: () -> Void
    @State private var selectedExchangeMethod: ExchangeMethod = .hand

    private var canAgree: Bool {
        guard let viewerID, proposal.isParticipant(viewerID) else {
            return false
        }
        return !proposal.agreementBy(viewerID)
    }

    private var isWaitingForPartner: Bool {
        guard let viewerID, proposal.isParticipant(viewerID) else {
            return true
        }
        return proposal.agreementBy(viewerID) && !proposal.partnerAgreement(for: viewerID)
    }

    private var needsExchangeMethodChoice: Bool {
        proposal.exchangeMethod == .both
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("打診への返答")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            if canAgree {
                if needsExchangeMethodChoice {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("交換手段を選ぶ")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                        Picker("交換手段", selection: $selectedExchangeMethod) {
                            Text(ExchangeMethod.hand.displayName).tag(ExchangeMethod.hand)
                            Text(ExchangeMethod.mail.displayName).tag(ExchangeMethod.mail)
                        }
                        .pickerStyle(.segmented)
                    }
                }

                Button {
                    onAgree(needsExchangeMethodChoice ? selectedExchangeMethod : nil)
                } label: {
                    Group {
                        if isResponding {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Label("この内容で承諾", systemImage: "checkmark.circle.fill")
                        }
                    }
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(MegrumTheme.lavender, in: Capsule())
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .disabled(isResponding)

                Button(action: onCounterProposal) {
                    Label("条件を変えて再打診", systemImage: "arrow.triangle.2.circlepath")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                }
                .buttonStyle(.borderedProminent)
                .tint(MegrumTheme.sky)
                .disabled(isResponding)

                Button(role: .destructive, action: onReject) {
                    Label("断る", systemImage: "xmark.circle")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                }
                .buttonStyle(.bordered)
                .disabled(isResponding)
            } else {
                HStack(spacing: 10) {
                    Image(systemName: isWaitingForPartner ? "clock" : "checkmark.circle.fill")
                    Text(isWaitingForPartner ? "相手の合意を待っています" : "返答済みです")
                }
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(.white.opacity(0.72), in: Capsule())
            }
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(.white.opacity(0.72), lineWidth: 1)
        }
    }
}

private struct TradeDisputeBanner: View {
    var summary: TradeDisputeSummary
    var onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.bubble.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(MegrumTheme.pink, in: RoundedRectangle(cornerRadius: 13, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(summary.bannerTitle)
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    Text(summary.bannerBody)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(MegrumTheme.muted)
                    .padding(.top, 10)
            }
            .padding(15)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(MegrumTheme.pink.opacity(0.42), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(summary.bannerTitle)。\(summary.bannerBody)。詳細を見る")
    }
}

private struct TradeDayOfBanner: View {
    var presentation: TradeDayOfBannerPresentation
    @Binding var selectedOutfitPhotoItem: PhotosPickerItem?
    var isSending: Bool
    var canUseCamera: Bool
    var onOpenOutfitCamera: () -> Void
    var onMarkArrived: () -> Void
    var onShareLocation: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("当日の合流サポート", systemImage: "figure.wave")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Text(presentation.promptText)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)

            HStack(spacing: 8) {
                statusChip(title: "あなた", value: presentation.myArrivalText)
                statusChip(title: "相手", value: presentation.partnerArrivalText)
            }

            HStack(spacing: 8) {
                statusChip(title: "服装写真", value: presentation.myOutfitText)
                statusChip(title: "相手の服装", value: presentation.partnerOutfitText)
            }

            HStack(spacing: 8) {
                Button(action: onMarkArrived) {
                    Label("到着", systemImage: "checkmark.circle")
                }
                .disabled(isSending)

                Button(action: onShareLocation) {
                    Label("現在地", systemImage: "location")
                }
                .disabled(isSending)

                Menu {
#if os(iOS)
                    Button(action: onOpenOutfitCamera) {
                        Label("カメラで撮る", systemImage: "camera.fill")
                    }
                    .disabled(!canUseCamera || isSending)
#endif

                    PhotosPicker(selection: $selectedOutfitPhotoItem, matching: .images) {
                        Label("写真から選ぶ", systemImage: "photo.on.rectangle")
                    }
                    .disabled(isSending)
                } label: {
                    Label("服装", systemImage: "person.crop.rectangle")
                }
                .disabled(isSending)
            }
            .font(.system(size: 13, weight: .heavy, design: .rounded))
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.7), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }

    private func statusChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
            Text(value)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct CounterProposalSheet: View {
    @ObservedObject var appState: MegrumAppState
    var proposal: TradeProposal
    @Environment(\.dismiss) private var dismiss
    @State private var exchangeMethod: ExchangeMethod
    @State private var selectedConditionTags: Set<String>
    @State private var message: String

    private let conditionTagOptions = ["即日発送", "同日発送", "終演後OK", "グッズ販売中OK"]

    init(appState: MegrumAppState, proposal: TradeProposal) {
        self.appState = appState
        self.proposal = proposal
        _exchangeMethod = State(initialValue: proposal.exchangeMethod)
        _selectedConditionTags = State(initialValue: Set(proposal.conditionTags))
        _message = State(initialValue: "")
    }

    private var viewerID: UUID? {
        appState.viewer?.id
    }

    private var isSubmitting: Bool {
        appState.isCreatingProposal
    }

    private var offeredCount: Int {
        guard let viewerID else {
            return 0
        }
        return proposal.goodsOffered(by: viewerID)?.count ?? 0
    }

    private var requestedCount: Int {
        guard let viewerID else {
            return 0
        }
        return proposal.goodsRequested(by: viewerID)?.count ?? 0
    }

    private var availableConditionTags: [String] {
        var seen = Set<String>()
        return (conditionTagOptions + proposal.conditionTags).filter { tag in
            seen.insert(tag).inserted
        }
    }

    private var orderedConditionTags: [String] {
        availableConditionTags.filter { selectedConditionTags.contains($0) }
    }

    private var canSubmit: Bool {
        guard let viewerID else {
            return false
        }
        return proposal.counterProposalInput(
            from: viewerID,
            exchangeMethod: exchangeMethod,
            conditionTags: orderedConditionTags,
            message: message
        ) != nil
    }

    var body: some View {
        Form {
            Section {
                LabeledContent("私が出す", value: "\(offeredCount)件")
                LabeledContent("受け取る", value: "\(requestedCount)件")
            } header: {
                Text("元の内容をコピー")
            } footer: {
                Text("提示物は元の打診から引き継ぎます。条件だけ変更して相手に返せます。")
            }

            Section("交換手段") {
                Picker("交換手段", selection: $exchangeMethod) {
                    ForEach(ExchangeMethod.allCases) { method in
                        Text(method.displayName).tag(method)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("交換条件タグ") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 128), spacing: 8)], spacing: 8) {
                    ForEach(availableConditionTags, id: \.self) { tag in
                        Button {
                            toggleConditionTag(tag)
                        } label: {
                            HStack(spacing: 6) {
                                Text(tag)
                                if selectedConditionTags.contains(tag) {
                                    Image(systemName: "checkmark")
                                }
                            }
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .foregroundStyle(selectedConditionTags.contains(tag) ? .white : MegrumTheme.ink)
                            .background(
                                selectedConditionTags.contains(tag) ? MegrumTheme.lavender : .white.opacity(0.72),
                                in: Capsule()
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("メッセージ") {
                TextEditor(text: $message)
                    .frame(minHeight: 96)
                    .overlay(alignment: .topLeading) {
                        if message.isEmpty {
                            Text("変更したい条件を相手に伝える")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(MegrumTheme.muted.opacity(0.68))
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
                        }
                    }
            }

            Section {
                Button {
                    Task {
                        await createCounterProposal()
                    }
                } label: {
                    Group {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text("この条件で再打診")
                        }
                    }
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                }
                .disabled(!canSubmit || isSubmitting)
            }
        }
        .scrollContentBackground(.hidden)
        .background(MegrumTheme.canvas)
        .navigationTitle("条件を変えて再打診")
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
    }

    private func toggleConditionTag(_ tag: String) {
        if selectedConditionTags.contains(tag) {
            selectedConditionTags.remove(tag)
        } else {
            selectedConditionTags.insert(tag)
        }
    }

    private func createCounterProposal() async {
        guard let viewerID else {
            return
        }
        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let input = proposal.counterProposalInput(
            from: viewerID,
            exchangeMethod: exchangeMethod,
            conditionTags: orderedConditionTags,
            message: trimmedMessage.isEmpty ? nil : trimmedMessage
        ) else {
            return
        }

        let created = await appState.createProposal(input)
        if created {
            dismiss()
        }
    }
}

private struct TradeEvidencePanel: View {
    var proposal: TradeProposal
    var viewerID: UUID?
    @Binding var selectedPhotoItem: PhotosPickerItem?
    var evaluationState: TradeEvaluationPromptState
    var isAddingEvidence: Bool
    var isApproving: Bool
    var canUseCamera: Bool
    var onOpenCamera: () -> Void
    var onOpenImage: (URL) -> Void
    var onApprove: () -> Void
    var onRate: () -> Void

    private var myApproved: Bool {
        guard let viewerID else {
            return false
        }
        return proposal.approvedBy(viewerID)
    }

    private var partnerApproved: Bool {
        guard let viewerID else {
            return false
        }
        return proposal.partnerApproved(for: viewerID)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("取引証跡")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)

                Spacer()

                if proposal.status == .completed {
                    Text("完了")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(MegrumTheme.ok, in: Capsule())
                }
            }

            if let evidencePhotoURL = proposal.evidencePhotoURL {
                Button {
                    onOpenImage(evidencePhotoURL)
                } label: {
                    AsyncImage(url: evidencePhotoURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            MegrumTheme.sky.opacity(0.18)
                                .overlay {
                                    Image(systemName: "photo")
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundStyle(MegrumTheme.muted)
                                }
                        case .empty:
                            MegrumTheme.sky.opacity(0.12)
                                .overlay {
                                    ProgressView()
                                }
                        @unknown default:
                            Color.clear
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("証跡写真を拡大表示")
                .frame(height: 172)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(.white.opacity(0.7), lineWidth: 1)
                }
            }

            HStack(spacing: 8) {
                approvalChip(title: "あなた", isApproved: myApproved)
                approvalChip(title: "相手", isApproved: partnerApproved)
            }

            if proposal.status == .completed {
                if evaluationState.hasSubmittedEvaluation {
                    Label("評価送信済み", systemImage: "star.fill")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ok)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(.white.opacity(0.72), in: Capsule())
                        .accessibilityLabel("評価送信済み")
                } else {
                    Button(action: onRate) {
                        Label("評価を送信", systemImage: "star.fill")
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(MegrumTheme.lavender, in: Capsule())
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
            } else if proposal.evidencePhotoURL == nil {
                Button(action: onOpenCamera) {
                    Label(isAddingEvidence ? "追加中" : "交換後にグッズを撮影", systemImage: "camera.fill")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(MegrumTheme.lavender, in: Capsule())
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .disabled(isAddingEvidence || !canUseCamera)

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label("写真から選ぶ", systemImage: "photo.on.rectangle")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(.white.opacity(0.76), in: Capsule())
                        .foregroundStyle(MegrumTheme.ink)
                }
                .buttonStyle(.plain)
                .disabled(isAddingEvidence)
            } else if !myApproved {
                Button(action: onApprove) {
                    Group {
                        if isApproving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Label("証跡を承認", systemImage: "checkmark.seal.fill")
                        }
                    }
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(MegrumTheme.lavender, in: Capsule())
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .disabled(isApproving)
            } else {
                Text("相手の承認を待っています")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(.white.opacity(0.68), in: Capsule())
            }
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(.white.opacity(0.72), lineWidth: 1)
        }
    }

    private func approvalChip(title: String, isApproved: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: isApproved ? "checkmark.circle.fill" : "clock")
            Text(isApproved ? "\(title) 承認済み" : "\(title) 未承認")
        }
        .font(.system(size: 12, weight: .heavy, design: .rounded))
        .foregroundStyle(isApproved ? MegrumTheme.ok : MegrumTheme.muted)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.white.opacity(0.72), in: Capsule())
    }
}

private struct TradeDisputeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var category: TradeDisputeCategory = .wrong
    @State private var factMemo = ""
    var isSubmitting: Bool
    var onSubmit: (TradeDisputeCategory, String) async -> Void

    private var trimmedFactMemo: String {
        factMemo.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        Form {
            Section {
                Picker("理由", selection: $category) {
                    ForEach(TradeDisputeCategory.allCases) { category in
                        Text(category.displayName).tag(category)
                    }
                }
            } header: {
                Text("申告理由")
            }

            Section {
                TextEditor(text: $factMemo)
                    .frame(minHeight: 140)
                    .overlay(alignment: .topLeading) {
                        if factMemo.isEmpty {
                            Text("何が起きたかを具体的に入力してください")
                                .foregroundStyle(MegrumTheme.muted)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
                        }
                    }
            } header: {
                Text("内容")
            } footer: {
                Text("写真や証跡は取引チャット上の共有内容と合わせて運営が確認します。")
            }
        }
        .navigationTitle("通報")
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    Task {
                        await onSubmit(category, trimmedFactMemo)
                    }
                } label: {
                    if isSubmitting {
                        ProgressView()
                    } else {
                        Text("送信")
                    }
                }
                .disabled(isSubmitting || trimmedFactMemo.isEmpty)
            }
        }
    }
}

private struct TradeEvaluationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var stars = 5
    @State private var comment = ""
    var isSubmitting: Bool
    var onSubmit: (Int, String?) async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("評価を送信")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)

                Spacer()

                Button("閉じる") {
                    dismiss()
                }
                .font(.system(size: 14, weight: .heavy, design: .rounded))
            }

            HStack(spacing: 10) {
                ForEach(1...5, id: \.self) { value in
                    Button {
                        stars = value
                    } label: {
                        Image(systemName: value <= stars ? "star.fill" : "star")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(MegrumTheme.lavender)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)

            TextField("コメント（任意）", text: $comment, axis: .vertical)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .lineLimit(3...5)
                .padding(14)
                .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            Button {
                Task {
                    await onSubmit(stars, comment.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty)
                }
            } label: {
                Group {
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("送信")
                    }
                }
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(MegrumTheme.lavender, in: Capsule())
                .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .disabled(isSubmitting)

            Spacer(minLength: 0)
        }
        .padding(22)
        .background(MegrumTheme.canvas.ignoresSafeArea())
    }
}

struct TradeSystemMessagePresentation: Equatable, Sendable {
    var title: String
    var systemImage: String
    var body: String
    var detail: String?
    var accessibilityLabel: String {
        [title, body, detail].compactMap(\.self).joined(separator: "。")
    }

    init(message: TradeMessage) {
        let fallbackBody = message.body?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "取引が更新されました"
        if let disputeSummary = TradeDisputeSummary(message: message) {
            title = "申告受付"
            systemImage = "exclamationmark.bubble"
            body = disputeSummary.body
            detail = disputeSummary.bannerBody
            return
        }

        switch message.meta["action"] {
        case .some(TradeAssistanceSystemIntent.Action.lateNotice.rawValue):
            title = "遅刻連絡"
            systemImage = "clock.badge.exclamationmark"
            body = Self.operationalBody(message: message, fallbackBody: fallbackBody)
            detail = message.meta["late_minutes"].map { "見込み：\($0)分" }
        case .some(TradeAssistanceSystemIntent.Action.cancelRequested.rawValue):
            title = "キャンセル申請"
            systemImage = "xmark.circle"
            body = Self.operationalBody(message: message, fallbackBody: fallbackBody)
            detail = nil
        case .some("cancel_approved"):
            title = "キャンセル合意"
            systemImage = "checkmark.circle"
            body = Self.operationalBody(message: message, fallbackBody: fallbackBody)
            detail = nil
        default:
            title = "取引更新"
            systemImage = "info.circle.fill"
            body = fallbackBody
            detail = nil
        }
    }

    private static func operationalBody(message: TradeMessage, fallbackBody: String) -> String {
        var lines: [String] = []
        if let reason = message.meta["reason"]?.trimmingCharacters(in: .whitespacesAndNewlines), !reason.isEmpty {
            lines.append("理由：\(reason)")
        }
        if let note = message.meta["note"]?.trimmingCharacters(in: .whitespacesAndNewlines), !note.isEmpty {
            lines.append("補足：\(note)")
        }
        return lines.isEmpty ? fallbackBody : lines.joined(separator: "\n")
    }
}

struct TradeCancelApprovalPrompt: Equatable, Sendable {
    var canApprove: Bool

    init(
        message: TradeMessage,
        proposal: TradeProposal,
        viewerID: UUID?,
        messages: [TradeMessage]
    ) {
        guard
            let viewerID,
            proposal.status == .agreed,
            proposal.isParticipant(viewerID),
            message.messageType == .system,
            message.meta["action"] == TradeAssistanceSystemIntent.Action.cancelRequested.rawValue
        else {
            canApprove = false
            return
        }

        let viewerKey = viewerID.uuidString.lowercased()
        let requesterKey = message.meta["requested_by"]?.lowercased()
            ?? message.senderID.uuidString.lowercased()
        let alreadyApproved = messages.contains { $0.meta["action"] == "cancel_approved" }
        canApprove = requesterKey != viewerKey && !alreadyApproved
    }
}

struct TradeOperationalMessagePresentation: Equatable, Sendable {
    var title: String
    var systemImage: String
    var body: String
    var detail: String?

    init(message: TradeMessage) {
        switch message.messageType {
        case .location:
            title = message.locationLabel?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "現在地共有"
            systemImage = "location.fill"
            body = Self.locationBody(message: message)
            detail = "位置情報"
        case .arrivalStatus:
            title = "到着ステータス"
            systemImage = "checkmark.circle.fill"
            body = message.body?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "到着状況を共有しました"
            detail = message.meta["status"].flatMap(Self.arrivalDetail(for:))
        default:
            title = "取引メッセージ"
            systemImage = "info.circle.fill"
            body = message.body?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "取引が更新されました"
            detail = nil
        }
    }

    private static func locationBody(message: TradeMessage) -> String {
        if let body = message.body?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty {
            return body
        }
        if let latitude = message.locationLatitude, let longitude = message.locationLongitude {
            let latText = latitude.formatted(.number.precision(.fractionLength(5)))
            let lngText = longitude.formatted(.number.precision(.fractionLength(5)))
            return "緯度 \(latText) / 経度 \(lngText)"
        }
        return "現在地を共有しました"
    }

    private static func arrivalDetail(for rawStatus: String) -> String? {
        switch TradeArrivalStatus(rawValue: rawStatus) {
        case .enroute:
            "移動中"
        case .arrived:
            "到着済み"
        case .left:
            "離れました"
        case .none:
            nil
        }
    }
}

private struct TradeMessageBubble: View {
    var message: TradeMessage
    var isMine: Bool
    var cancelApprovalPrompt: TradeCancelApprovalPrompt?
    var isApprovingCancel: Bool = false
    var onOpenImage: (URL) -> Void
    var onOpenDispute: (TradeDisputeSummary) -> Void = { _ in }
    var onApproveCancel: () -> Void = {}

    private var bodyText: String? {
        message.body?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }

    var body: some View {
        if message.messageType == .system {
            systemMessage
        } else {
            userMessage
        }
    }

    private var userMessage: some View {
        VStack(alignment: isMine ? .trailing : .leading, spacing: 4) {
            if let photoURL = message.photoURL {
                photoMessage(photoURL)
            }

            switch message.messageType {
            case .location:
                let presentation = TradeOperationalMessagePresentation(message: message)
                richTextBubble(
                    title: presentation.title,
                    systemImage: presentation.systemImage,
                    body: presentation.body,
                    detail: presentation.detail
                )
            case .arrivalStatus:
                let presentation = TradeOperationalMessagePresentation(message: message)
                richTextBubble(
                    title: presentation.title,
                    systemImage: presentation.systemImage,
                    body: presentation.body,
                    detail: presentation.detail
                )
            case .text, .photo, .outfitPhoto:
                if let bodyText {
                    textBubble(bodyText)
                }
            case .system:
                EmptyView()
            }

            Text(message.createdAt.formatted(date: .omitted, time: .shortened))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: isMine ? .trailing : .leading)
    }

    @ViewBuilder
    private var systemMessage: some View {
        let presentation = TradeSystemMessagePresentation(message: message)
        if let disputeSummary = TradeDisputeSummary(message: message) {
            Button {
                onOpenDispute(disputeSummary)
            } label: {
                systemMessageContent(presentation: presentation, showsDisclosure: true)
            }
            .buttonStyle(.plain)
        } else {
            VStack(spacing: 8) {
                systemMessageContent(presentation: presentation, showsDisclosure: false)
                if cancelApprovalPrompt?.canApprove == true {
                    Button(action: onApproveCancel) {
                        HStack(spacing: 8) {
                            if isApprovingCancel {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            Text("キャンセルに同意する")
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(MegrumTheme.lavender, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(isApprovingCancel)
                    .accessibilityLabel("キャンセル申請に同意する")
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private func systemMessageContent(presentation: TradeSystemMessagePresentation, showsDisclosure: Bool) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: presentation.systemImage)
                .font(.system(size: 13, weight: .bold))
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 3) {
                Text(presentation.title)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                Text(presentation.body)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .fixedSize(horizontal: false, vertical: true)
                if let detail = presentation.detail {
                    Text(detail)
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                }
            }
            if showsDisclosure {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .heavy))
                    .padding(.top, 2)
            }
        }
        .foregroundStyle(MegrumTheme.muted)
        .padding(.horizontal, 13)
        .padding(.vertical, 9)
        .frame(maxWidth: 320, alignment: .leading)
        .background(.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .frame(maxWidth: .infinity, alignment: .center)
        .accessibilityLabel(presentation.accessibilityLabel)
    }

    private func photoMessage(_ photoURL: URL) -> some View {
        Button {
            onOpenImage(photoURL)
        } label: {
            AsyncImage(url: photoURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    MegrumTheme.sky.opacity(0.18)
                        .overlay {
                            Image(systemName: "photo")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(MegrumTheme.muted)
                        }
                case .empty:
                    MegrumTheme.sky.opacity(0.12)
                        .overlay {
                            ProgressView()
                        }
                @unknown default:
                    Color.clear
                }
            }
            .frame(width: 210, height: message.messageType == .outfitPhoto ? 280 : 250)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(alignment: .topLeading) {
                if let label = photoLabel {
                    Label(label, systemImage: "photo.fill")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.46), in: Capsule())
                        .padding(9)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(photoLabel ?? "取引チャットの写真")を拡大表示")
    }

    private func textBubble(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(isMine ? .white : MegrumTheme.ink)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: 300, alignment: isMine ? .trailing : .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                isMine ? AnyShapeStyle(MegrumTheme.lavender) : AnyShapeStyle(.white.opacity(0.9)),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
    }

    private func richTextBubble(title: String, systemImage: String, body: String, detail: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(isMine ? .white.opacity(0.86) : MegrumTheme.lavender)
            Text(body)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .fixedSize(horizontal: false, vertical: true)
            if let detail {
                Text(detail)
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(isMine ? .white.opacity(0.78) : MegrumTheme.muted)
            }
        }
        .foregroundStyle(isMine ? .white : MegrumTheme.ink)
        .frame(maxWidth: 300, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            isMine ? AnyShapeStyle(MegrumTheme.lavender) : AnyShapeStyle(.white.opacity(0.9)),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
    }

    private var photoLabel: String? {
        switch message.messageType {
        case .photo:
            "写真"
        case .outfitPhoto:
            "服装写真"
        default:
            nil
        }
    }
}

private struct TradeUnavailableChatActionSheet: View {
    var action: TradeUnavailableChatAction
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ContentUnavailableView {
            Label(action.title, systemImage: action.systemImage)
        } description: {
            Text(action.description)
        } actions: {
            Button("閉じる") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(MegrumTheme.lavender)
        }
        .navigationTitle(action.title)
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
    }
}

private struct TradeAssistanceRequestSheet: View {
    var kind: TradeAssistanceRequestKind
    var isSubmitting: Bool
    var onSubmit: (TradeAssistanceSystemIntent) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft: TradeAssistanceRequestDraft

    init(
        kind: TradeAssistanceRequestKind,
        isSubmitting: Bool,
        onSubmit: @escaping (TradeAssistanceSystemIntent) async -> Void
    ) {
        self.kind = kind
        self.isSubmitting = isSubmitting
        self.onSubmit = onSubmit
        self._draft = State(initialValue: TradeAssistanceRequestDraft(kind: kind))
    }

    var body: some View {
        Form {
            Section {
                Label(kind.title, systemImage: kind.systemImage)
                    .font(.headline)
                    .foregroundStyle(MegrumTheme.ink)

                if kind == .late {
                    Picker("遅れる見込み", selection: $draft.delayBucket) {
                        ForEach(TradeLateDelayBucket.allCases) { bucket in
                            Text(bucket.title)
                                .tag(bucket)
                                .accessibilityLabel(bucket.accessibilityLabel)
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityLabel("遅れる見込み")
                }
            } footer: {
                Text(kind.acknowledgementText)
            }

            Section("理由") {
                TextEditor(text: $draft.reason)
                    .frame(minHeight: 132)
                    .overlay(alignment: .topLeading) {
                        if draft.reason.isEmpty {
                            Text(kind.reasonPlaceholder)
                                .foregroundStyle(MegrumTheme.muted)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
                        }
                    }
                    .accessibilityLabel(kind.reasonAccessibilityLabel)
            }

            Section {
                TextEditor(text: $draft.note)
                    .frame(minHeight: 96)
                    .overlay(alignment: .topLeading) {
                        if draft.note.isEmpty {
                            Text(kind.notePlaceholder)
                                .foregroundStyle(MegrumTheme.muted)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
                        }
                    }
                    .accessibilityLabel(kind.noteAccessibilityLabel)
            } header: {
                Text("補足")
            } footer: {
                Text("補足は任意です。送信後は取引チャットにシステムメッセージとして残ります。")
            }

            Section {
                Toggle(kind.acknowledgementText, isOn: $draft.acknowledgesImpact)
                    .accessibilityLabel(kind.acknowledgementAccessibilityLabel)
            }

            if let intent = draft.systemIntent {
                Section("取引チャットへの反映文") {
                    Text(intent.messageBody)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(MegrumTheme.ink)
                        .accessibilityLabel("\(kind.title)の送信内容")
                }
            }
        }
        .navigationTitle(kind.title)
        .megrumInlineNavigationTitle()
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    Task {
                        guard let intent = draft.systemIntent else {
                            return
                        }
                        await onSubmit(intent)
                    }
                } label: {
                    if isSubmitting {
                        ProgressView()
                    } else {
                        Text("送信")
                    }
                }
                .disabled(!draft.isSubmittable || isSubmitting)
            }
        }
    }
}

private struct TradeMessageInput: View {
    @Binding var text: String
    @Binding var selectedOutfitPhotoItem: PhotosPickerItem?
    var isSending: Bool
    var showsCounterProposal: Bool
    var onOpenSchedule: () -> Void
    var onSendArrivalStatus: (TradeArrivalQuickAction) -> Void
    var onOpenLocationPlaceholder: () -> Void
    var canUseCamera: Bool
    var onOpenOutfitCamera: () -> Void
    var onCounterProposal: () -> Void
    var onRequestLate: () -> Void
    var onRequestCancel: () -> Void
    var onReport: () -> Void
    var onSend: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Menu {
                Button(action: onOpenSchedule) {
                    Label("スケジュール", systemImage: "calendar")
                }

                Menu {
                    ForEach(TradeArrivalQuickAction.allCases) { action in
                        Button {
                            onSendArrivalStatus(action)
                        } label: {
                            Label(action.title, systemImage: action.systemImage)
                        }
                        .disabled(isSending)
                    }
                } label: {
                    Label("到着ステータス", systemImage: "checkmark.circle")
                }

                Button(action: onOpenLocationPlaceholder) {
                    Label("現在地を共有", systemImage: "location.fill")
                }

#if os(iOS)
                Button(action: onOpenOutfitCamera) {
                    Label("服装写真を撮る", systemImage: "camera.fill")
                }
                .disabled(!canUseCamera || isSending)
#endif

                PhotosPicker(selection: $selectedOutfitPhotoItem, matching: .images) {
                    Label("服装写真を選ぶ", systemImage: "photo.on.rectangle")
                }
                .disabled(isSending)

                if showsCounterProposal {
                    Button(action: onCounterProposal) {
                        Label("再打診", systemImage: "arrow.triangle.2.circlepath")
                    }
                }

                Button(action: onRequestLate) {
                    Label(TradeAssistanceRequestKind.late.title, systemImage: TradeAssistanceRequestKind.late.systemImage)
                }
                .accessibilityLabel(TradeAssistanceRequestKind.late.menuAccessibilityLabel)

                Button(action: onRequestCancel) {
                    Label(TradeAssistanceRequestKind.cancel.title, systemImage: TradeAssistanceRequestKind.cancel.systemImage)
                }
                .accessibilityLabel(TradeAssistanceRequestKind.cancel.menuAccessibilityLabel)

                Button(role: .destructive, action: onReport) {
                    Label("通報", systemImage: "exclamationmark.bubble")
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundStyle(MegrumTheme.lavender)
                    .frame(width: 42, height: 42)
                    .background(.white.opacity(0.82), in: Circle())
            }
            .accessibilityLabel("メッセージ操作")

            TextField("メッセージ", text: $text, axis: .vertical)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .lineLimit(1...4)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            Button(action: onSend) {
                Group {
                    if isSending {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 17, weight: .heavy))
                    }
                }
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(MegrumTheme.lavender, in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
            .opacity(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
        }
    }
}

private enum TradeScheduleCalendarMode: String, CaseIterable, Identifiable {
    case fiveDays
    case month

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fiveDays:
            "週"
        case .month:
            "月"
        }
    }
}

private struct TradeScheduleSheet: View {
    @ObservedObject var appState: MegrumAppState
    var proposal: TradeProposal
    @Environment(\.dismiss) private var dismiss
    @State private var mode: TradeScheduleCalendarMode = .fiveDays
    @State private var anchorDate = Date()
    @State private var isShowingScheduleEditor = false

    private let calendar = Calendar.current
    private let weekdayLabels = ["日", "月", "火", "水", "木", "金", "土"]

    private var visibleInterval: DateInterval {
        switch mode {
        case .fiveDays:
            let start = calendar.startOfDay(for: anchorDate)
            let end = calendar.date(byAdding: .day, value: 5, to: start) ?? start.addingTimeInterval(86_400 * 5)
            return DateInterval(start: start, end: end)
        case .month:
            return calendar.dateInterval(of: .month, for: anchorDate)
                ?? DateInterval(start: calendar.startOfDay(for: anchorDate), duration: 86_400 * 31)
        }
    }

    private var reloadKey: String {
        "\(mode.rawValue)-\(Int(visibleInterval.start.timeIntervalSince1970))"
    }

    private var schedules: [PersonalSchedule] {
        appState.schedules(for: proposal.id)
    }

    private var viewerID: UUID? {
        appState.viewer?.id
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Picker("表示", selection: $mode) {
                    ForEach(TradeScheduleCalendarMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                ScheduleLegend()

                if appState.loadingSchedulesProposalID == proposal.id {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("スケジュールを読み込んでいます")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }

                switch mode {
                case .fiveDays:
                    fiveDayView
                case .month:
                    monthView
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 32)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .navigationTitle("スケジュール")
        .megrumInlineNavigationTitle()
        .task(id: reloadKey) {
            await appState.loadSchedules(for: proposal, startAt: visibleInterval.start, endAt: visibleInterval.end)
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    isShowingScheduleEditor = true
                } label: {
                    Label("更新", systemImage: "plus")
                }
                .accessibilityLabel("自分のスケジュールを追加")
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    moveAnchor(by: mode == .month ? 1 : 5)
                } label: {
                    Image(systemName: "chevron.right")
                }
                .accessibilityLabel(mode == .month ? "次の月" : "次の週")
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    moveAnchor(by: mode == .month ? -1 : -5)
                } label: {
                    Image(systemName: "chevron.left")
                }
                .accessibilityLabel(mode == .month ? "前の月" : "前の週")
            }
        }
        .sheet(isPresented: $isShowingScheduleEditor) {
            NavigationStack {
                ScheduleEditorSheet(
                    appState: appState,
                    proposal: proposal,
                    defaultDate: anchorDate
                )
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var fiveDayView: some View {
        VStack(spacing: 12) {
            ForEach(fiveVisibleDays, id: \.self) { day in
                ScheduleDayCard(
                    day: day,
                    schedules: schedules(on: day),
                    viewerID: viewerID
                )
            }
        }
    }

    private var monthView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(monthTitle)
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Spacer()
                Button {
                    moveAnchor(by: -1)
                } label: {
                    Image(systemName: "chevron.left.circle.fill")
                }
                .buttonStyle(.plain)
                .foregroundStyle(MegrumTheme.lavender)

                Button {
                    moveAnchor(by: 1)
                } label: {
                    Image(systemName: "chevron.right.circle.fill")
                }
                .buttonStyle(.plain)
                .foregroundStyle(MegrumTheme.lavender)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 8) {
                ForEach(weekdayLabels, id: \.self) { label in
                    Text(label)
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .frame(maxWidth: .infinity)
                }

                ForEach(Array(monthGridDays.enumerated()), id: \.offset) { _, day in
                    if let day {
                        ScheduleMonthCell(
                            day: day,
                            schedules: schedules(on: day),
                            isToday: calendar.isDateInToday(day),
                            viewerID: viewerID
                        )
                    } else {
                        Color.clear
                            .frame(height: 76)
                    }
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(.white.opacity(0.7), lineWidth: 1)
        }
    }

    private var fiveVisibleDays: [Date] {
        let start = calendar.startOfDay(for: anchorDate)
        return (0..<5).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    private var monthGridDays: [Date?] {
        guard let month = calendar.dateInterval(of: .month, for: anchorDate),
              let dayRange = calendar.range(of: .day, in: .month, for: anchorDate)
        else {
            return []
        }
        let leadingBlanks = (calendar.component(.weekday, from: month.start) + 6) % 7
        var days: [Date?] = Array(repeating: nil, count: leadingBlanks)
        days.append(contentsOf: dayRange.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: month.start)
        })
        while days.count % 7 != 0 {
            days.append(nil)
        }
        return days
    }

    private var monthTitle: String {
        anchorDate.formatted(.dateTime.year().month(.wide))
    }

    private func schedules(on day: Date) -> [PersonalSchedule] {
        let start = calendar.startOfDay(for: day)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86_400)
        return schedules.filter { $0.overlaps(start: start, end: end) }
    }

    private func moveAnchor(by value: Int) {
        let component: Calendar.Component = mode == .month ? .month : .day
        anchorDate = calendar.date(byAdding: component, value: value, to: anchorDate) ?? anchorDate
    }
}

private struct ScheduleEditorSheet: View {
    @ObservedObject var appState: MegrumAppState
    var proposal: TradeProposal
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var placeName: String
    @State private var startAt: Date
    @State private var endAt: Date
    @State private var allDay: Bool
    @State private var note: String

    init(appState: MegrumAppState, proposal: TradeProposal, defaultDate: Date) {
        self.appState = appState
        self.proposal = proposal
        let start = Self.defaultStartDate(defaultDate)
        self._title = State(initialValue: "")
        self._placeName = State(initialValue: "")
        self._startAt = State(initialValue: start)
        self._endAt = State(initialValue: start.addingTimeInterval(3_600))
        self._allDay = State(initialValue: false)
        self._note = State(initialValue: "")
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        !trimmedTitle.isEmpty && startAt < endAt && !appState.isCreatingSchedule
    }

    var body: some View {
        Form {
            Section {
                TextField("予定名", text: $title)

                TextField("場所", text: $placeName)
            }

            Section {
                Toggle("終日", isOn: $allDay)

                if allDay {
                    DatePicker("開始", selection: $startAt, displayedComponents: [.date])
                    DatePicker("終了", selection: $endAt, displayedComponents: [.date])
                } else {
                    DatePicker("開始", selection: $startAt, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("終了", selection: $endAt, displayedComponents: [.date, .hourAndMinute])
                }
            } header: {
                Text("日時")
            }

            Section {
                TextEditor(text: $note)
                    .frame(minHeight: 96)
            } header: {
                Text("メモ")
            } footer: {
                Text("保存した予定は、取引相手がスケジュール共有を許可している時だけ重ねて表示されます。")
            }
        }
        .navigationTitle("スケジュールを更新")
        .megrumInlineNavigationTitle()
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: startAt) { _, newValue in
            if endAt <= newValue {
                endAt = newValue.addingTimeInterval(allDay ? 86_400 : 3_600)
            }
        }
        .onChange(of: allDay) { _, isAllDay in
            if isAllDay {
                let day = Calendar.current.startOfDay(for: startAt)
                startAt = day
                endAt = Calendar.current.date(byAdding: .day, value: 1, to: day) ?? day.addingTimeInterval(86_400)
            } else if endAt <= startAt {
                endAt = startAt.addingTimeInterval(3_600)
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button {
                    Task {
                        await save()
                    }
                } label: {
                    if appState.isCreatingSchedule {
                        ProgressView()
                    } else {
                        Text("保存")
                    }
                }
                .disabled(!canSave)
            }
        }
    }

    private func save() async {
        let input = PersonalScheduleCreateInput(
            title: title,
            placeName: placeName,
            startAt: startAt,
            endAt: endAt,
            allDay: allDay,
            note: note
        )
        if await appState.createSchedule(input, for: proposal) {
            dismiss()
        }
    }

    private static func defaultStartDate(_ date: Date) -> Date {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let now = Date()
            let minute = calendar.component(.minute, from: now)
            let minutesToAdd = minute < 30 ? 30 - minute : 60 - minute
            let next = calendar.date(byAdding: .minute, value: minutesToAdd, to: now) ?? now.addingTimeInterval(1_800)
            return calendar.dateInterval(of: .minute, for: next)?.start ?? next
        }
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = 12
        components.minute = 0
        components.second = 0
        return calendar.date(from: components) ?? calendar.startOfDay(for: date)
    }
}

private struct ScheduleLegend: View {
    var body: some View {
        HStack(spacing: 10) {
            legendItem(title: "あなた", color: MegrumTheme.lavender)
            legendItem(title: "相手", color: MegrumTheme.sky)
            Spacer()
        }
        .font(.system(size: 13, weight: .heavy, design: .rounded))
    }

    private func legendItem(title: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 9, height: 9)
            Text(title)
                .foregroundStyle(MegrumTheme.muted)
        }
    }
}

private struct ScheduleDayCard: View {
    var day: Date
    var schedules: [PersonalSchedule]
    var viewerID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(day.formatted(.dateTime.month(.abbreviated).day()))
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    Text(day.formatted(.dateTime.weekday(.wide)))
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }
                Spacer()
                if Calendar.current.isDateInToday(day) {
                    Text("今日")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(MegrumTheme.lavender, in: Capsule())
                }
            }

            if schedules.isEmpty {
                Text("予定なし")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                ForEach(schedules) { schedule in
                    ScheduleRowView(schedule: schedule, isMine: schedule.userID == viewerID)
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.7), lineWidth: 1)
        }
    }
}

private struct ScheduleRowView: View {
    var schedule: PersonalSchedule
    var isMine: Bool

    private var color: Color {
        isMine ? MegrumTheme.lavender : MegrumTheme.sky
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(color)
                .frame(width: 5)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(schedule.title)
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    Text(isMine ? "あなた" : "相手")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(color)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(color.opacity(0.13), in: Capsule())
                }

                Text(timeRangeText)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)

                if let placeName = schedule.placeName {
                    Label(placeName, systemImage: "mappin.and.ellipse")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var timeRangeText: String {
        if schedule.allDay {
            return "終日"
        }
        let start = schedule.startAt.formatted(.dateTime.hour().minute())
        let end = schedule.endAt.formatted(.dateTime.hour().minute())
        return "\(start) - \(end)"
    }
}

private struct ScheduleMonthCell: View {
    var day: Date
    var schedules: [PersonalSchedule]
    var isToday: Bool
    var viewerID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(day.formatted(.dateTime.day()))
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(isToday ? .white : MegrumTheme.ink)
                .frame(width: 26, height: 26)
                .background(isToday ? MegrumTheme.lavender : Color.clear, in: Circle())

            ForEach(schedules.prefix(3)) { schedule in
                HStack(spacing: 3) {
                    Circle()
                        .fill(schedule.userID == viewerID ? MegrumTheme.lavender : MegrumTheme.sky)
                        .frame(width: 5, height: 5)
                    Text(schedule.title)
                        .lineLimit(1)
                }
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 76, alignment: .topLeading)
        .padding(6)
        .background(.white.opacity(0.62), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }
}

private struct RemoteImageSelection: Identifiable, Equatable {
    var url: URL
    var id: String { url.absoluteString }
}

private struct FullScreenRemoteImageView: View {
    var url: URL
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(zoomGesture.simultaneously(with: dragGesture))
                        .onTapGesture(count: 2) {
                            resetZoom()
                        }
                case .failure:
                    VStack(spacing: 12) {
                        Image(systemName: "photo")
                            .font(.system(size: 34, weight: .bold))
                        Text("画像を読み込めませんでした")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white.opacity(0.86))
                case .empty:
                    ProgressView()
                        .tint(.white)
                @unknown default:
                    EmptyView()
                }
            }
            .padding(.horizontal, 16)

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(.white.opacity(0.18), in: Circle())
            }
            .buttonStyle(.plain)
            .padding(.top, 18)
            .padding(.trailing, 18)
            .accessibilityLabel("閉じる")
        }
    }

    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = min(max(lastScale * value, 1), 4)
            }
            .onEnded { _ in
                lastScale = scale
                if scale <= 1.02 {
                    resetZoom()
                }
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard scale > 1 else {
                    return
                }
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    private func resetZoom() {
        scale = 1
        lastScale = 1
        offset = .zero
        lastOffset = .zero
    }
}

private struct TradePreviewColumn: View {
    var title: String
    var symbol: String
    var items: [GoodsItem] = []
    var right = false

    var body: some View {
        VStack(alignment: right ? .trailing : .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 9.5, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)

            if items.isEmpty {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(MegrumTheme.sky.opacity(0.18))
                    .frame(width: 32, height: 42)
                    .overlay {
                        Image(systemName: symbol)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(MegrumTheme.lavender)
                    }
            } else {
                HStack(spacing: 5) {
                    ForEach(previewItems) { item in
                        TradePreviewThumbnail(item: item)
                    }
                }
                .frame(maxWidth: .infinity, alignment: right ? .trailing : .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: right ? .trailing : .leading)
    }

    private var previewItems: [GoodsItem] {
        Array(items.prefix(3))
    }
}

private struct TradePairPreview: View {
    var receiverItems: [GoodsItem]
    var senderItems: [GoodsItem]

    var body: some View {
        HStack(spacing: 8) {
            TradePreviewColumn(
                title: "受け取る",
                symbol: "arrow.down.left",
                items: receiverItems
            )
            TradeArrowStack()
            TradePreviewColumn(
                title: "私が出す",
                symbol: "arrow.up.right",
                items: senderItems,
                right: true
            )
        }
    }
}

private struct TradeArrowStack: View {
    var body: some View {
        VStack(spacing: -3) {
            Text("→")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
            Text("←")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.sky)
        }
        .frame(width: 22)
    }
}

private struct TradePreviewThumbnail: View {
    var item: GoodsItem

    var body: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(TradePreviewThumbnailStyle.hue(for: item))
            .frame(width: 32, height: 42)
            .overlay {
                if let imageURL = item.imageURL {
                    AsyncImage(url: imageURL, transaction: Transaction(animation: .easeInOut(duration: 0.18))) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .controlSize(.small)
                                .tint(MegrumTheme.lavender)
                        case let .success(image):
                            GeometryReader { proxy in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: proxy.size.width, height: proxy.size.height)
                                    .clipped()
                            }
                        case .failure:
                            fallbackIcon
                        @unknown default:
                            fallbackIcon
                        }
                    }
                } else {
                    fallbackIcon
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(.white.opacity(0.78), lineWidth: 1)
            }
            .accessibilityLabel(item.title)
    }

    private var fallbackIcon: some View {
        Text(TradePreviewThumbnailStyle.glyph(for: item))
            .font(.system(size: 16, weight: .black, design: .rounded))
            .foregroundStyle(.white)
    }
}

enum TradePreviewThumbnailStyle {
    static func glyph(for item: GoodsItem) -> String {
        if item.title.contains("スア") {
            return "S"
        }
        if item.title.contains("ニンニン") {
            return "N"
        }
        if item.title.contains("ジョンウ") {
            return "J"
        }
        if item.title.contains("カリナ") {
            return "K"
        }
        let title = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return title.first.map { String($0).uppercased() } ?? "?"
    }

    static func hue(for item: GoodsItem) -> Color {
        switch abs(item.id.hashValue) % 3 {
        case 0:
            return MegrumTheme.lavender.opacity(0.62)
        case 1:
            return MegrumTheme.sky.opacity(0.72)
        default:
            return MegrumTheme.pink.opacity(0.62)
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

private func inferredEvidenceImageContentType(from data: Data) -> String {
    let bytes = [UInt8](data.prefix(12))
    if bytes.count >= 8,
       bytes[0] == 0x89,
       bytes[1] == 0x50,
       bytes[2] == 0x4E,
       bytes[3] == 0x47 {
        return "image/png"
    }
    if bytes.count >= 12,
       bytes[0] == 0x52,
       bytes[1] == 0x49,
       bytes[2] == 0x46,
       bytes[3] == 0x46,
       bytes[8] == 0x57,
       bytes[9] == 0x45,
       bytes[10] == 0x42,
       bytes[11] == 0x50 {
        return "image/webp"
    }
    return "image/jpeg"
}
