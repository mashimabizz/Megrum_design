import Foundation
import MegrumCore
import MegrumDesign
import PhotosUI
import SwiftUI

struct CounterProposalSheet: View {
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

struct TradeEvidencePanel: View {
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

struct TradeDisputeSheet: View {
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

struct TradeEvaluationSheet: View {
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
        .navigationTitle("評価")
        .megrumInlineNavigationTitle()
    }
}

struct RemoteImageSelection: Identifiable, Equatable {
    var url: URL
    var id: String { url.absoluteString }
}

struct FullScreenRemoteImageView: View {
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

func inferredEvidenceImageContentType(from data: Data) -> String {
    inferredPhotoMessageContentType(from: data)
}
