import MegrumCore
import MegrumDesign
import PhotosUI
import SwiftUI
#if os(iOS)
import UIKit
#endif

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
        case .cancelled:
            "キャンセル済"
        case .completed:
            "完了"
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
            [.agreed, .completed].contains(status)
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
    @State private var selectedEvidencePhotoItem: PhotosPickerItem?
    @State private var isShowingEvidenceCamera = false
    @State private var isShowingEvaluationSheet = false

    private var messages: [TradeMessage] {
        appState.messages(for: proposal.id)
    }

    private var currentProposal: TradeProposal {
        appState.proposals.first { $0.id == proposal.id } ?? proposal
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ScreenTitle(title: "取引詳細", subtitle: currentProposal.exchangeMethod.displayName)
                    TradeCard(proposal: currentProposal) {}

                    VStack(alignment: .leading, spacing: 12) {
                        detailRow(title: "ステータス", value: statusText)
                        detailRow(title: "交換条件タグ", value: currentProposal.conditionTags.isEmpty ? "未設定" : currentProposal.conditionTags.joined(separator: " / "))
                        detailRow(title: "私が出す", value: "\(currentProposal.senderGoodsIDs.count)件")
                        detailRow(title: "受け取る", value: "\(currentProposal.receiverGoodsIDs.count)件")
                    }
                    .padding(18)
                    .background(.white.opacity(0.84), in: RoundedRectangle(cornerRadius: 24, style: .continuous))

                    if currentProposal.status == .agreed || currentProposal.status == .completed {
                        TradeEvidencePanel(
                            proposal: currentProposal,
                            viewerID: appState.viewer?.id,
                            selectedPhotoItem: $selectedEvidencePhotoItem,
                            isAddingEvidence: appState.addingEvidenceProposalID == currentProposal.id,
                            isApproving: appState.approvingEvidenceProposalID == currentProposal.id,
                            canUseCamera: canUseCamera,
                            onOpenCamera: {
                                isShowingEvidenceCamera = true
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
        .onChange(of: selectedEvidencePhotoItem) { _, item in
            guard let item else {
                return
            }
            Task {
                await addEvidence(from: item)
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
                        isShowingEvaluationSheet = false
                    }
                }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
#if os(iOS)
        .sheet(isPresented: $isShowingEvidenceCamera) {
            NativeCameraCaptureView { imageData in
                Task {
                    await addEvidence(data: imageData, imageContentType: "image/jpeg")
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
        }
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
            "完了"
        }
    }
}

private struct TradeEvidencePanel: View {
    var proposal: TradeProposal
    var viewerID: UUID?
    @Binding var selectedPhotoItem: PhotosPickerItem?
    var isAddingEvidence: Bool
    var isApproving: Bool
    var canUseCamera: Bool
    var onOpenCamera: () -> Void
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
                Button(action: onRate) {
                    Label("評価を送信", systemImage: "star.fill")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(MegrumTheme.lavender, in: Capsule())
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
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
