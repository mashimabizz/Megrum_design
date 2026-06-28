import MegrumCore
import MegrumDesign
import SwiftUI

struct GroomViewerPresentationModifier: ViewModifier {
    @Binding var selectedGroom: GroomPost?
    var grooms: [GroomPost]
    @ObservedObject var appState: MegrumAppState

    func body(content: Content) -> some View {
        #if os(iOS)
        content.fullScreenCover(item: $selectedGroom) { groom in
            GroomViewerScreen(grooms: grooms, initialGroom: groom, appState: appState)
        }
        #else
        content.sheet(item: $selectedGroom) { groom in
            GroomViewerScreen(grooms: grooms, initialGroom: groom, appState: appState)
        }
        #endif
    }
}

struct GroomViewerScreen: View {
    var grooms: [GroomPost]
    var initialGroom: GroomPost
    @ObservedObject var appState: MegrumAppState
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int
    @State private var dragOffset: CGSize = .zero
    @State private var replyDraft = ""
    @State private var isShowingReportConfirmation = false
    @State private var isShowingBlockConfirmation = false

    init(grooms: [GroomPost], initialGroom: GroomPost, appState: MegrumAppState) {
        let fallbackGrooms = grooms.isEmpty ? [initialGroom] : grooms
        self.grooms = fallbackGrooms
        self.initialGroom = initialGroom
        self.appState = appState
        _currentIndex = State(initialValue: fallbackGrooms.firstIndex(where: { $0.id == initialGroom.id }) ?? 0)
    }

    private var currentGroom: GroomPost {
        grooms[max(0, min(currentIndex, grooms.count - 1))]
    }

    private var isCurrentGroomLiked: Bool {
        appState.isGroomLiked(currentGroom.id)
    }

    private var canReplyToCurrentGroom: Bool {
        guard let viewerID = appState.viewer?.id else {
            return false
        }
        return viewerID != currentGroom.authorID
    }

    private var isSendingReply: Bool {
        appState.sendingGroomReplyPostID == currentGroom.id
    }

    private var authorMeguriProfile: MeguriProfile? {
        appState.meguriProfile(for: currentGroom.authorID)
    }

    private var authorPublicProfile: UserProfile? {
        appState.publicProfilesByUserID[currentGroom.authorID]?.profile
    }

    private var authorName: String {
        authorMeguriProfile?.displayName.nilIfBlank
            ?? authorPublicProfile?.displayName.nilIfBlank
            ?? (currentGroom.authorID == appState.viewer?.id ? appState.viewer?.displayName : nil)
            ?? "めぐりユーザー"
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            AsyncImage(url: currentGroom.imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .id(currentGroom.id)
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                case .failure:
                    GroomImageFailureView(message: "画像を読み込めませんでした", foregroundColor: .white)
                default:
                    ProgressView()
                        .tint(.white)
                        .controlSize(.large)
                }
            }
            .padding(.horizontal, 8)
            .offset(y: dragOffset.height * 0.28)
            .scaleEffect(max(0.92, 1 - abs(dragOffset.height) / 900))

            HStack(spacing: 0) {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        move(by: -1)
                    }

                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        move(by: 1)
                    }
            }

            VStack(spacing: 0) {
                GroomViewerPageIndicator(
                    totalCount: grooms.count,
                    currentIndex: currentIndex
                )

                GroomViewerTopBar(
                    authorName: authorName,
                    authorAvatarID: authorMeguriProfile?.avatarID,
                    authorAvatarURL: authorMeguriProfile == nil ? authorPublicProfile?.avatarURL : nil,
                    canModerate: canReplyToCurrentGroom,
                    onReport: { isShowingReportConfirmation = true },
                    onBlock: { isShowingBlockConfirmation = true }
                ) {
                    dismiss()
                }

                Spacer()

                if let remainingTimeText = currentGroom.remainingTimeText {
                    Text(remainingTimeText)
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .frame(height: 28)
                        .background(.black.opacity(0.28), in: Capsule())
                        .padding(.bottom, 10)
                }

                GroomViewerBottomControls(
                    canReply: canReplyToCurrentGroom,
                    canLike: canReplyToCurrentGroom,
                    isSendingReply: isSendingReply,
                    isLiked: isCurrentGroomLiked,
                    likeCount: appState.groomLikeCount(currentGroom.id, fallback: currentGroom.likeCount),
                    onSubmitReply: submitGroomReply,
                    onToggleLike: toggleCurrentGroomLike,
                    replyDraft: $replyDraft
                )
            }
        }
        .task(id: currentGroom.id) {
            await appState.markGroomViewed(currentGroom.id)
            await appState.loadMeguriProfiles(userIDs: [currentGroom.authorID], reportsFailure: false)
            if currentGroom.authorID != appState.viewer?.id,
               appState.publicProfilesByUserID[currentGroom.authorID] == nil {
                await appState.loadPublicUserProfile(userID: currentGroom.authorID, reportsFailure: false)
            }
        }
        .confirmationDialog("このグルームを通報しますか？", isPresented: $isShowingReportConfirmation, titleVisibility: .visible) {
            Button("通報する", role: .destructive) {
                Task {
                    _ = await appState.reportGroom(currentGroom)
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("運営が内容を確認します。")
        }
        .confirmationDialog("この投稿者をブロックしますか？", isPresented: $isShowingBlockConfirmation, titleVisibility: .visible) {
            Button("ブロックする", role: .destructive) {
                Task {
                    let blocked = await appState.blockGroomAuthor(currentGroom)
                    if blocked {
                        dismiss()
                    }
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("グルームとチャットルームで相手の投稿が表示されにくくなります。グッズ交換のブロックとは別です。")
        }
        .gesture(
            DragGesture(minimumDistance: 12)
                .onChanged { value in
                    if value.translation.height > 0 {
                        dragOffset = value.translation
                    }
                }
                .onEnded { value in
                    if value.translation.height > 100 {
                        dismiss()
                    } else {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                            dragOffset = .zero
                        }
                    }
                }
        )
    }

    private func move(by delta: Int) {
        let nextIndex = currentIndex + delta
        guard grooms.indices.contains(nextIndex) else {
            if delta > 0 {
                dismiss()
            }
            return
        }
        withAnimation(.smooth(duration: 0.18)) {
            currentIndex = nextIndex
        }
    }

    private func toggleCurrentGroomLike() {
        Task {
            await appState.setGroomLiked(currentGroom.id, isLiked: !isCurrentGroomLiked)
        }
    }

    private func submitGroomReply() {
        let body = replyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty, !isSendingReply else {
            return
        }
        Task {
            let sent = await appState.sendGroomReply(
                postID: currentGroom.id,
                recipientID: currentGroom.authorID,
                body: body,
                groomImageURL: currentGroom.imageURL
            )
            if sent {
                replyDraft = ""
            }
        }
    }
}

private extension GroomPost {
    var remainingTimeText: String? {
        guard let expiresAt else {
            return nil
        }
        let remaining = expiresAt.timeIntervalSince(Date())
        guard remaining > 0 else {
            return "終了"
        }
        if remaining < 3_600 {
            return "残り\(max(1, Int(ceil(remaining / 60))))分"
        }
        return "残り\(max(1, Int(ceil(remaining / 3_600))))時間"
    }
}
