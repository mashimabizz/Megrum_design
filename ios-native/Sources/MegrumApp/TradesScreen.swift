import MegrumCore
import MegrumDesign
import SwiftUI

struct TradesScreen: View {
    @ObservedObject var appState: MegrumAppState

    @State private var selectedStage: TradeStage = .pending
    @State private var selectedProposal: TradeProposal?

    private var proposals: [TradeProposal] {
        appState.proposals
    }

    private var visibleProposals: [TradeProposal] {
        proposals.filter { selectedStage.contains($0.status) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ScreenTitle(title: "やりとり", subtitle: selectedStage.subtitle)

                if visibleProposals.isEmpty {
                    EmptyTradeStage(stage: selectedStage)
                } else {
                    ForEach(visibleProposals) { proposal in
                        TradeCard(proposal: proposal) {
                            selectedProposal = proposal
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 132)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .megrumHiddenNavigationBar()
        .safeAreaInset(edge: .bottom) {
            TradeStageBar(
                selectedStage: $selectedStage,
                pendingCount: proposals.filter { TradeStage.pending.contains($0.status) }.count,
                inProgressCount: proposals.filter { TradeStage.inProgress.contains($0.status) }.count
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
        }
        .gesture(
            DragGesture(minimumDistance: 32)
                .onEnded { value in
                    if value.translation.width < -44 {
                        selectedStage = .inProgress
                    } else if value.translation.width > 44 {
                        selectedStage = .pending
                    }
                }
        )
        .sheet(item: $selectedProposal) { proposal in
            NavigationStack {
                TradeDetailScreen(appState: appState, proposal: proposal)
            }
        }
    }
}

private struct TradeCard: View {
    var proposal: TradeProposal
    var onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(statusText)
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(MegrumTheme.sky.opacity(0.28), in: Capsule())

                    Spacer()

                    Text(proposal.exchangeMethod.displayName)
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                }

                HStack {
                    TradePreviewColumn(title: "受け取る", symbol: "arrow.down.left")
                    Spacer()
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(MegrumTheme.lavender)
                    Spacer()
                    TradePreviewColumn(title: "私が出す", symbol: "arrow.up.right")
                }

                if !proposal.conditionTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(proposal.conditionTags, id: \.self) { tag in
                                Text(tag)
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(MegrumTheme.ink)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(.white.opacity(0.72), in: Capsule())
                            }
                        }
                    }
                }
            }
            .padding(18)
            .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(.black.opacity(0.05), lineWidth: 1))
            .shadow(color: MegrumTheme.ink.opacity(0.06), radius: 16, y: 8)
        }
        .buttonStyle(.plain)
    }

    private var statusText: String {
        switch proposal.status {
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
        }
    }
}

private enum TradeStage: String, CaseIterable, Identifiable {
    case pending
    case inProgress

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pending:
            "打診中"
        case .inProgress:
            "進行中"
        }
    }

    var subtitle: String {
        switch self {
        case .pending:
            "送信済み・調整中の打診"
        case .inProgress:
            "成立後の取引"
        }
    }

    func contains(_ status: ProposalStatus) -> Bool {
        switch self {
        case .pending:
            [.draft, .sent, .negotiating, .agreementOneSide].contains(status)
        case .inProgress:
            status == .agreed
        }
    }
}

private struct TradeStageBar: View {
    @Binding var selectedStage: TradeStage
    var pendingCount: Int
    var inProgressCount: Int

    var body: some View {
        HStack(spacing: 8) {
            stageButton(.pending, count: pendingCount)
            stageButton(.inProgress, count: inProgressCount)
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
    }
}

private struct EmptyTradeStage: View {
    var stage: TradeStage

    var body: some View {
        Text(stage == .pending ? "打診中の取引はありません" : "進行中の取引はありません")
            .font(.system(size: 15, weight: .heavy, design: .rounded))
            .foregroundStyle(MegrumTheme.muted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 34)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(.white.opacity(0.62), lineWidth: 1)
            }
    }
}

private struct TradeDetailScreen: View {
    @ObservedObject var appState: MegrumAppState
    var proposal: TradeProposal
    @Environment(\.dismiss) private var dismiss
    @State private var draftMessage = ""

    private var messages: [TradeMessage] {
        appState.messages(for: proposal.id)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ScreenTitle(title: "取引詳細", subtitle: proposal.exchangeMethod.displayName)
                    TradeCard(proposal: proposal) {}

                    VStack(alignment: .leading, spacing: 12) {
                        detailRow(title: "ステータス", value: statusText)
                        detailRow(title: "交換条件タグ", value: proposal.conditionTags.isEmpty ? "未設定" : proposal.conditionTags.joined(separator: " / "))
                        detailRow(title: "私が出す", value: "\(proposal.senderGoodsIDs.count)件")
                        detailRow(title: "受け取る", value: "\(proposal.receiverGoodsIDs.count)件")
                    }
                    .padding(18)
                    .background(.white.opacity(0.84), in: RoundedRectangle(cornerRadius: 24, style: .continuous))

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
                                isMine: message.senderID == appState.viewer?.id
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 22)
            }

            TradeMessageInput(
                text: $draftMessage,
                isSending: appState.sendingMessageProposalID == proposal.id
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
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .navigationTitle("取引詳細")
        .megrumInlineNavigationTitle()
        .task {
            await appState.loadMessages(proposalID: proposal.id)
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
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
        switch proposal.status {
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
        }
    }
}

private struct TradeMessageBubble: View {
    var message: TradeMessage
    var isMine: Bool

    var body: some View {
        VStack(alignment: isMine ? .trailing : .leading, spacing: 4) {
            Text(message.body ?? "")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(isMine ? .white : MegrumTheme.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isMine ? AnyShapeStyle(MegrumTheme.lavender) : AnyShapeStyle(.white.opacity(0.9)), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            Text(message.createdAt.formatted(date: .omitted, time: .shortened))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: isMine ? .trailing : .leading)
    }
}

private struct TradeMessageInput: View {
    @Binding var text: String
    var isSending: Bool
    var onSend: () -> Void

    var body: some View {
        HStack(spacing: 10) {
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

private struct TradePreviewColumn: View {
    var title: String
    var symbol: String

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(MegrumTheme.sky.opacity(0.18))
                .frame(width: 74, height: 74)
                .overlay {
                    Image(systemName: symbol)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(MegrumTheme.lavender)
                }
        }
    }
}
