import MegrumCore
import MegrumDesign
import SwiftUI

enum DisputeDetailStatus: String, CaseIterable, Identifiable, Equatable, Sendable {
    case filed
    case submitted
    case replyWindow = "reply_window"
    case replyReceived = "reply_received"
    case arbitration
    case resolved
    case withdrawn

    var id: String { rawValue }

    init(rawStatus: String) {
        self = DisputeDetailStatus(rawValue: rawStatus) ?? .submitted
    }

    var displayName: String {
        switch self {
        case .filed:
            "申告作成中"
        case .submitted:
            "申告送信済"
        case .replyWindow:
            "反論受付中"
        case .replyReceived:
            "反論受領"
        case .arbitration:
            "仲裁中"
        case .resolved:
            "仲裁決定済"
        case .withdrawn:
            "取り下げ済"
        }
    }

    var systemImage: String {
        switch self {
        case .filed:
            "square.and.pencil"
        case .submitted:
            "tray.and.arrow.up.fill"
        case .replyWindow:
            "bubble.left.and.bubble.right.fill"
        case .replyReceived:
            "text.bubble.fill"
        case .arbitration:
            "person.2.badge.gearshape.fill"
        case .resolved:
            "checkmark.seal.fill"
        case .withdrawn:
            "arrow.uturn.backward.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .resolved:
            MegrumTheme.ok
        case .withdrawn:
            MegrumTheme.muted
        case .arbitration:
            MegrumTheme.sky
        default:
            MegrumTheme.lavender
        }
    }

    var allowsReply: Bool {
        self == .submitted || self == .replyWindow
    }

    var allowsWithdrawal: Bool {
        switch self {
        case .filed, .submitted, .replyWindow:
            true
        case .replyReceived, .arbitration, .resolved, .withdrawn:
            false
        }
    }
}

enum DisputeTimelineEventState: Equatable, Sendable {
    case completed
    case current
    case pending
}

struct DisputeTimelineEvent: Identifiable, Equatable, Sendable {
    var id: String
    var status: DisputeDetailStatus
    var title: String
    var detail: String
    var date: Date?
    var state: DisputeTimelineEventState

    init(
        status: DisputeDetailStatus,
        detail: String,
        date: Date? = nil,
        state: DisputeTimelineEventState
    ) {
        self.id = status.rawValue
        self.status = status
        self.title = status.displayName
        self.detail = detail
        self.date = date
        self.state = state
    }
}

enum DisputeDetailTimelineBuilder {
    static func build(
        status: DisputeDetailStatus,
        submittedAt: Date,
        replyDeadlineAt: Date? = nil,
        resolvedAt: Date? = nil
    ) -> [DisputeTimelineEvent] {
        let order = orderedStatuses(for: status)
        let currentIndex = order.firstIndex(of: status) ?? 0

        return order.enumerated().map { index, item in
            DisputeTimelineEvent(
                status: item,
                detail: detail(for: item, replyDeadlineAt: replyDeadlineAt),
                date: date(for: item, submittedAt: submittedAt, resolvedAt: resolvedAt),
                state: eventState(index: index, currentIndex: currentIndex)
            )
        }
    }

    private static func orderedStatuses(for status: DisputeDetailStatus) -> [DisputeDetailStatus] {
        switch status {
        case .filed:
            [.filed, .submitted, .replyWindow, .arbitration, .resolved]
        case .replyReceived:
            [.submitted, .replyWindow, .replyReceived, .arbitration, .resolved]
        case .withdrawn:
            [.submitted, .withdrawn]
        default:
            [.submitted, .replyWindow, .arbitration, .resolved]
        }
    }

    private static func eventState(index: Int, currentIndex: Int) -> DisputeTimelineEventState {
        if index < currentIndex {
            return .completed
        }
        if index == currentIndex {
            return .current
        }
        return .pending
    }

    private static func date(for status: DisputeDetailStatus, submittedAt: Date, resolvedAt: Date?) -> Date? {
        switch status {
        case .submitted:
            submittedAt
        case .resolved:
            resolvedAt
        default:
            nil
        }
    }

    private static func detail(for status: DisputeDetailStatus, replyDeadlineAt: Date?) -> String {
        switch status {
        case .filed:
            return "内容を確認してから申告を送ります。"
        case .submitted:
            return "受付番号が発行され、取引相手に通知されます。"
        case .replyWindow:
            if let replyDeadlineAt {
                return "相手は \(replyDeadlineAt.formatted(date: .abbreviated, time: .shortened)) まで反論できます。"
            }
            return "相手の反論を待っています。"
        case .replyReceived:
            return "相手の反論が届き、運営確認に進みます。"
        case .arbitration:
            return "運営が取引チャット、証跡、申告内容を確認しています。"
        case .resolved:
            return "仲裁結果が反映され、取引の凍結が解除されます。"
        case .withdrawn:
            return "申告は取り下げられました。"
        }
    }
}

struct DisputeDetailModel: Identifiable, Equatable, Sendable {
    var id: UUID
    var proposalID: UUID
    var ticketNo: String
    var status: DisputeDetailStatus
    var category: TradeDisputeCategory?
    var reporterName: String
    var respondentName: String
    var factMemo: String?
    var submittedAt: Date
    var replyDeadlineAt: Date?
    var resolvedAt: Date?
    var resolutionSummary: String?
    var timeline: [DisputeTimelineEvent]

    init(
        id: UUID,
        proposalID: UUID,
        ticketNo: String,
        status: DisputeDetailStatus,
        category: TradeDisputeCategory? = nil,
        reporterName: String = "あなた",
        respondentName: String = "相手",
        factMemo: String? = nil,
        submittedAt: Date,
        replyDeadlineAt: Date? = nil,
        resolvedAt: Date? = nil,
        resolutionSummary: String? = nil,
        timeline: [DisputeTimelineEvent]? = nil
    ) {
        self.id = id
        self.proposalID = proposalID
        self.ticketNo = ticketNo
        self.status = status
        self.category = category
        self.reporterName = reporterName
        self.respondentName = respondentName
        self.factMemo = factMemo
        self.submittedAt = submittedAt
        self.replyDeadlineAt = replyDeadlineAt
        self.resolvedAt = resolvedAt
        self.resolutionSummary = resolutionSummary
        self.timeline = timeline ?? DisputeDetailTimelineBuilder.build(
            status: status,
            submittedAt: submittedAt,
            replyDeadlineAt: replyDeadlineAt,
            resolvedAt: resolvedAt
        )
    }

    init(ticket: TradeDisputeTicket, category: TradeDisputeCategory? = nil, reporterName: String = "あなた", respondentName: String = "相手", factMemo: String? = nil, replyDeadlineAt: Date? = nil) {
        self.init(
            id: ticket.id,
            proposalID: ticket.proposalID,
            ticketNo: ticket.ticketNo,
            status: DisputeDetailStatus(rawStatus: ticket.status),
            category: category,
            reporterName: reporterName,
            respondentName: respondentName,
            factMemo: factMemo,
            submittedAt: ticket.submittedAt,
            replyDeadlineAt: replyDeadlineAt
        )
    }

    var canSubmitReply: Bool {
        status.allowsReply
    }

    var canWithdraw: Bool {
        status.allowsWithdrawal
    }

    func replyCountdownText(now: Date = .now) -> String {
        guard let replyDeadlineAt else {
            return "反論期限は未設定です"
        }
        let remainingSeconds = Int(replyDeadlineAt.timeIntervalSince(now))
        guard remainingSeconds > 0 else {
            return "反論期限を過ぎています"
        }
        let hours = remainingSeconds / 3_600
        if hours >= 1 {
            return "反論期限まで残り\(hours)時間"
        }
        let minutes = max(1, remainingSeconds / 60)
        return "反論期限まで残り\(minutes)分"
    }
}

struct DisputeReplyDraft: Equatable, Sendable {
    var body: String = ""
    var includesEvidenceNote = true

    var normalizedBody: String {
        body.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isSubmittable: Bool {
        !normalizedBody.isEmpty
    }
}

enum TradeRequestKind: String, CaseIterable, Identifiable, Sendable {
    case cancellation
    case late

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cancellation:
            "キャンセル申請"
        case .late:
            "遅刻申請"
        }
    }

    var shortTitle: String {
        switch self {
        case .cancellation:
            "キャンセル"
        case .late:
            "遅刻"
        }
    }

    var systemImage: String {
        switch self {
        case .cancellation:
            "xmark.circle.fill"
        case .late:
            "clock.badge.exclamationmark.fill"
        }
    }

    var reasonPlaceholder: String {
        switch self {
        case .cancellation:
            "キャンセルが必要な理由"
        case .late:
            "遅れる理由と到着見込み"
        }
    }

    var acknowledgementText: String {
        switch self {
        case .cancellation:
            "キャンセル後の取引継続可否は相手と運営の確認が必要です。"
        case .late:
            "30分を超える遅刻では、相手にキャンセル権が発生する可能性があります。"
        }
    }
}

struct TradeRequestDraft: Equatable, Sendable {
    var kind: TradeRequestKind
    var reason: String = ""
    var estimatedDelayMinutes = 10
    var acknowledgesImpact = false

    var normalizedReason: String {
        reason.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isSubmittable: Bool {
        guard !normalizedReason.isEmpty, acknowledgesImpact else {
            return false
        }

        switch kind {
        case .cancellation:
            return true
        case .late:
            return (5...180).contains(estimatedDelayMinutes)
        }
    }

    var systemMessageBody: String? {
        guard isSubmittable else {
            return nil
        }

        switch kind {
        case .cancellation:
            return "キャンセル申請: \(normalizedReason)"
        case .late:
            return "遅刻申請: \(estimatedDelayMinutes)分ほど遅れます。\(normalizedReason)"
        }
    }
}

struct DisputeDetailScreen: View {
    var model: DisputeDetailModel
    var onSubmitReply: (DisputeReplyDraft) async -> Bool
    var onSubmitTradeRequest: (TradeRequestDraft) async -> Bool
    var onWithdraw: () async -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var replyDraft: DisputeReplyDraft
    @State private var isSubmittingReply = false
    @State private var presentedRequestKind: TradeRequestKind?
    @State private var isShowingWithdrawConfirmation = false

    init(
        model: DisputeDetailModel,
        initialReplyDraft: DisputeReplyDraft = DisputeReplyDraft(),
        onSubmitReply: @escaping (DisputeReplyDraft) async -> Bool = { _ in false },
        onSubmitTradeRequest: @escaping (TradeRequestDraft) async -> Bool = { _ in false },
        onWithdraw: @escaping () async -> Bool = { false }
    ) {
        self.model = model
        self.onSubmitReply = onSubmitReply
        self.onSubmitTradeRequest = onSubmitTradeRequest
        self.onWithdraw = onWithdraw
        self._replyDraft = State(initialValue: initialReplyDraft)
    }

    var body: some View {
        List {
            Section {
                DisputeStatusHeader(model: model)
            }
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            .listRowBackground(Color.clear)

            Section("タイムライン") {
                DisputeTimelineView(entries: model.timeline)
                    .padding(.vertical, 4)
            }

            Section("申告内容") {
                LabeledContent("受付番号", value: model.ticketNo)
                LabeledContent("カテゴリ", value: model.category?.displayName ?? "未設定")
                LabeledContent("申告者", value: model.reporterName)
                LabeledContent("相手", value: model.respondentName)

                if let factMemo = model.factMemo?.trimmingCharacters(in: .whitespacesAndNewlines), !factMemo.isEmpty {
                    Text(factMemo)
                        .font(.body)
                        .foregroundStyle(MegrumTheme.ink)
                        .padding(.vertical, 4)
                }
            }

            if let resolutionSummary = model.resolutionSummary {
                Section("仲裁結果") {
                    Text(resolutionSummary)
                        .foregroundStyle(MegrumTheme.ink)
                }
            }

            if model.canSubmitReply {
                Section {
                    DisputeReplyComposer(
                        draft: $replyDraft,
                        isSubmitting: isSubmittingReply,
                        onSubmit: submitReply
                    )
                } header: {
                    Text("反論")
                } footer: {
                    Text(model.replyCountdownText())
                }
            }

            Section {
                Button {
                    presentedRequestKind = .late
                } label: {
                    Label(TradeRequestKind.late.title, systemImage: TradeRequestKind.late.systemImage)
                }

                Button(role: .destructive) {
                    presentedRequestKind = .cancellation
                } label: {
                    Label(TradeRequestKind.cancellation.title, systemImage: TradeRequestKind.cancellation.systemImage)
                }
            } header: {
                Text("当日リクエスト")
            } footer: {
                Text("遅刻やキャンセルは取引チャット側へ反映するための独立した申請として扱います。")
            }
        }
        .scrollContentBackground(.hidden)
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .disputeDetailListStyle()
        .navigationTitle("異議詳細")
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }

            if model.canWithdraw {
                ToolbarItem(placement: .primaryAction) {
                    Button(role: .destructive) {
                        isShowingWithdrawConfirmation = true
                    } label: {
                        Label("取り下げ", systemImage: "arrow.uturn.backward")
                    }
                }
            }
        }
        .sheet(item: $presentedRequestKind) { kind in
            NavigationStack {
                TradeRequestSheet(kind: kind, onSubmit: onSubmitTradeRequest)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .confirmationDialog(
            "申告を取り下げますか？",
            isPresented: $isShowingWithdrawConfirmation,
            titleVisibility: .visible
        ) {
            Button("取り下げる", role: .destructive) {
                Task {
                    if await onWithdraw() {
                        dismiss()
                    }
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("取り下げ後は、この申告への反論や仲裁確認を進められません。")
        }
    }

    private func submitReply() {
        guard replyDraft.isSubmittable, !isSubmittingReply else {
            return
        }

        Task {
            isSubmittingReply = true
            let sent = await onSubmitReply(replyDraft)
            isSubmittingReply = false
            if sent {
                replyDraft = DisputeReplyDraft()
            }
        }
    }
}

private extension View {
    @ViewBuilder
    func disputeDetailListStyle() -> some View {
        #if os(iOS)
        self.listStyle(.insetGrouped)
        #else
        self
        #endif
    }
}

private struct DisputeStatusHeader: View {
    var model: DisputeDetailModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: model.status.systemImage)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(model.status.tint, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(model.status.displayName)
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                    Text(model.ticketNo)
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                statusChip(title: "受付", value: model.submittedAt.formatted(date: .abbreviated, time: .shortened))
                if model.canSubmitReply {
                    statusChip(title: "反論", value: model.replyCountdownText())
                }
            }
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(.white.opacity(0.72), lineWidth: 1)
        }
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
                .minimumScaleFactor(0.78)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct DisputeTimelineView: View {
    var entries: [DisputeTimelineEvent]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                HStack(alignment: .top, spacing: 12) {
                    VStack(spacing: 0) {
                        marker(for: entry)
                        if index < entries.count - 1 {
                            Rectangle()
                                .fill(lineColor(after: entry))
                                .frame(width: 2)
                                .frame(minHeight: 28)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.title)
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink)
                        Text(entry.detail)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                        if let date = entry.date {
                            Text(date.formatted(date: .abbreviated, time: .shortened))
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(MegrumTheme.muted.opacity(0.76))
                        }
                    }
                    .padding(.bottom, index < entries.count - 1 ? 16 : 0)
                }
            }
        }
    }

    private func marker(for entry: DisputeTimelineEvent) -> some View {
        Image(systemName: markerSymbol(for: entry.state))
            .font(.system(size: 12, weight: .heavy))
            .foregroundStyle(markerForeground(for: entry))
            .frame(width: 24, height: 24)
            .background(markerBackground(for: entry), in: Circle())
    }

    private func markerSymbol(for state: DisputeTimelineEventState) -> String {
        switch state {
        case .completed:
            "checkmark"
        case .current:
            "circle.fill"
        case .pending:
            "circle"
        }
    }

    private func markerForeground(for entry: DisputeTimelineEvent) -> Color {
        switch entry.state {
        case .completed, .current:
            .white
        case .pending:
            MegrumTheme.muted
        }
    }

    private func markerBackground(for entry: DisputeTimelineEvent) -> Color {
        switch entry.state {
        case .completed:
            MegrumTheme.ok
        case .current:
            entry.status.tint
        case .pending:
            MegrumTheme.muted.opacity(0.14)
        }
    }

    private func lineColor(after entry: DisputeTimelineEvent) -> Color {
        entry.state == .pending ? MegrumTheme.muted.opacity(0.18) : MegrumTheme.lavender.opacity(0.38)
    }
}

private struct DisputeReplyComposer: View {
    @Binding var draft: DisputeReplyDraft
    var isSubmitting: Bool
    var onSubmit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextEditor(text: $draft.body)
                .frame(minHeight: 124)
                .overlay(alignment: .topLeading) {
                    if draft.body.isEmpty {
                        Text("事実関係、到着時刻、チャットで確認できる内容を書いてください")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted.opacity(0.68))
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .allowsHitTesting(false)
                    }
                }

            Toggle("証跡やチャット内容も確認してほしい", isOn: $draft.includesEvidenceNote)

            Button(action: onSubmit) {
                Group {
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Label("反論を送信", systemImage: "paperplane.fill")
                    }
                }
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(MegrumTheme.lavender, in: Capsule())
                .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .disabled(!draft.isSubmittable || isSubmitting)
            .opacity(draft.isSubmittable ? 1 : 0.45)
        }
        .padding(.vertical, 6)
    }
}

private struct TradeRequestSheet: View {
    var kind: TradeRequestKind
    var onSubmit: (TradeRequestDraft) async -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var draft: TradeRequestDraft
    @State private var isSubmitting = false

    init(kind: TradeRequestKind, onSubmit: @escaping (TradeRequestDraft) async -> Bool) {
        self.kind = kind
        self.onSubmit = onSubmit
        self._draft = State(initialValue: TradeRequestDraft(kind: kind))
    }

    var body: some View {
        Form {
            Section {
                Label(kind.title, systemImage: kind.systemImage)
                    .font(.headline)
                    .foregroundStyle(MegrumTheme.ink)

                if kind == .late {
                    Stepper(value: $draft.estimatedDelayMinutes, in: 5...180, step: 5) {
                        LabeledContent("遅れる見込み", value: "\(draft.estimatedDelayMinutes)分")
                    }
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
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(MegrumTheme.muted.opacity(0.68))
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
                        }
                    }
            }

            Section {
                Toggle(kind.acknowledgementText, isOn: $draft.acknowledgesImpact)
            }

            if let message = draft.systemMessageBody {
                Section("取引チャットへの反映文") {
                    Text(message)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(MegrumTheme.ink)
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
                    submit()
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

    private func submit() {
        guard draft.isSubmittable, !isSubmitting else {
            return
        }

        Task {
            isSubmitting = true
            let sent = await onSubmit(draft)
            isSubmitting = false
            if sent {
                dismiss()
            }
        }
    }
}
