import MegrumCore
import MegrumDesign
import SwiftUI

struct GroomArchiveStoryScreen: View {
    var grooms: [GroomPost]
    var initialGroom: GroomPost
    @ObservedObject var appState: MegrumAppState
    var onDismiss: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var presentationState: GroomArchiveStoryPresentationState
    @State private var isShowingDeleteConfirmation = false
    @State private var isShowingComments = false
    @State private var isShowingLikes = false
    @State private var replyDraft = ""

    init(
        grooms: [GroomPost],
        initialGroom: GroomPost,
        appState: MegrumAppState,
        onDismiss: (() -> Void)? = nil
    ) {
        let sortedGrooms = GroomArchiveOrdering.sorted(grooms.isEmpty ? [initialGroom] : grooms)
        self.grooms = sortedGrooms
        self.initialGroom = initialGroom
        self.appState = appState
        self.onDismiss = onDismiss
        _presentationState = State(
            initialValue: GroomArchiveStoryPresentationState(
                initialIndex: sortedGrooms.firstIndex(where: { $0.id == initialGroom.id }) ?? 0
            )
        )
    }

    private var currentGroom: GroomPost {
        grooms[max(0, min(presentationState.currentIndex, grooms.count - 1))]
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea(.container, edges: .top)

            AsyncImage(url: currentGroom.imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .id(currentGroom.id)
                case .failure:
                    GroomImageFailureView(message: "画像を読み込めませんでした", foregroundColor: .white)
                default:
                    ProgressView()
                        .tint(.white)
                        .controlSize(.large)
                }
            }
            .padding(.horizontal, 8)
            .offset(y: presentationState.imageYOffset)
            .scaleEffect(presentationState.imageScale)

            HStack(spacing: 0) {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { move(by: -1) }

                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { move(by: 1) }
            }

            Color.black
                .frame(height: GroomViewerChromeLayout.topObstructionHeight(safeAreaTop: 0))
                .frame(maxHeight: .infinity, alignment: .top)
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                HStack(spacing: 6) {
                    ForEach(grooms.indices, id: \.self) { index in
                        Capsule()
                            .fill(index <= presentationState.currentIndex ? .white : .white.opacity(0.28))
                            .frame(height: 3)
                    }
                }
                .padding(.horizontal, 14)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(currentGroom.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.black.opacity(0.28), in: Capsule())

                    Spacer()

                    Button {
                        dismissStory()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(.black.opacity(0.28), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("閉じる")
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)

                Spacer()

                HStack {
                    Spacer()
                    GroomViewerOwnerBottomControls(
                        likeCount: appState.groomReactions(for: currentGroom.id).count,
                        commentCount: appState.groomReplies(for: currentGroom.id).count,
                        isDeleting: appState.deletingGroomPostID == currentGroom.id,
                        onOpenComments: { isShowingComments = true },
                        onOpenLikes: { isShowingLikes = true },
                        onDelete: { isShowingDeleteConfirmation = true }
                    )
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
            }
            .padding(.top, GroomViewerChromeLayout.topPadding(safeAreaTop: 0))
        }
        .gesture(
            DragGesture(minimumDistance: 12)
                .onChanged { value in
                    presentationState.updateDrag(value.translation)
                }
                .onEnded { value in
                    if presentationState.shouldDismiss(for: value.translation) {
                        dismissStory()
                    }
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                        presentationState.resetDrag()
                    }
                }
        )
        .sheet(isPresented: $isShowingComments) {
            GroomViewerCommentsSheet(
                groom: currentGroom,
                appState: appState,
                canReply: false,
                isSendingReply: false,
                replyDraft: $replyDraft,
                onSubmitReply: {},
                onOpenProfile: { _ in }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingLikes) {
            GroomViewerLikesSheet(
                groom: currentGroom,
                appState: appState,
                onOpenProfile: { _ in }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .confirmationDialog("このグルームを削除しますか？", isPresented: $isShowingDeleteConfirmation, titleVisibility: .visible) {
            Button("削除する", role: .destructive) {
                deleteCurrentGroom()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("削除すると、めぐりホームとグルームアーカイブから表示されなくなります。")
        }
    }

    private func move(by delta: Int) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        var outcome = GroomArchiveStoryMoveOutcome.unchanged
        withTransaction(transaction) {
            outcome = presentationState.move(by: delta, itemCount: grooms.count)
        }
        if outcome == .dismiss {
            dismissStory()
        }
    }

    private func dismissStory() {
        if let onDismiss {
            onDismiss()
        } else {
            dismiss()
        }
    }

    private func deleteCurrentGroom() {
        let target = currentGroom
        Task {
            let deleted = await appState.deleteOwnGroom(target)
            if deleted {
                dismissStory()
            }
        }
    }
}
