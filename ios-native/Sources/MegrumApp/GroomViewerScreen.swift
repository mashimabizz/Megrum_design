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

private struct GroomViewerScreen: View {
    var grooms: [GroomPost]
    var initialGroom: GroomPost
    @ObservedObject var appState: MegrumAppState
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int
    @State private var dragOffset: CGSize = .zero
    @State private var replyDraft = ""

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
        appState.viewer?.id != currentGroom.authorID
    }

    private var isSendingReply: Bool {
        appState.sendingGroomReplyPostID == currentGroom.id
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
                HStack(spacing: 6) {
                    ForEach(grooms.indices, id: \.self) { index in
                        Capsule()
                            .fill(index <= currentIndex ? .white : .white.opacity(0.28))
                            .frame(height: 3)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 14)

                HStack {
                    Spacer()
                    Button {
                        dismiss()
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

                HStack(spacing: 10) {
                    if canReplyToCurrentGroom {
                        TextField("返信を送る", text: $replyDraft)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .tint(.white)
                            .submitLabel(.send)
                            .padding(.horizontal, 14)
                            .frame(height: 46)
                            .background(.white.opacity(0.16), in: Capsule())
                            .overlay(Capsule().stroke(.white.opacity(0.22), lineWidth: 1))
                            .onSubmit {
                                submitGroomReply()
                            }

                        Button {
                            submitGroomReply()
                        } label: {
                            Group {
                                if isSendingReply {
                                    ProgressView()
                                        .controlSize(.small)
                                        .tint(.white)
                                } else {
                                    Image(systemName: "arrow.up")
                                        .font(.system(size: 18, weight: .heavy))
                                }
                            }
                            .foregroundStyle(.white)
                            .frame(width: 46, height: 46)
                            .background(MegrumTheme.lavender, in: Circle())
                        }
                        .buttonStyle(.plain)
                        .disabled(replyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSendingReply)
                        .opacity(replyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.52 : 1)
                    } else {
                        Spacer()
                    }

                    Button {
                        Task {
                            await appState.setGroomLiked(currentGroom.id, isLiked: !isCurrentGroomLiked)
                        }
                    } label: {
                        Image(systemName: isCurrentGroomLiked ? "heart.fill" : "heart")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundStyle(isCurrentGroomLiked ? MegrumTheme.pink : .white)
                            .frame(width: 54, height: 54)
                            .background(.black.opacity(0.28), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isCurrentGroomLiked ? "いいねを取り消す" : "いいね")
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 24)
            }
        }
        .task(id: currentGroom.id) {
            await appState.markGroomViewed(currentGroom.id)
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
