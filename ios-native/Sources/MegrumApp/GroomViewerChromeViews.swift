import MegrumDesign
import SwiftUI

struct GroomViewerPageIndicator: View {
    let totalCount: Int
    let currentIndex: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalCount, id: \.self) { index in
                Capsule()
                    .fill(index <= currentIndex ? .white : .white.opacity(0.28))
                    .frame(height: 3)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
    }
}

struct GroomViewerCloseButton: View {
    let action: () -> Void

    var body: some View {
        HStack {
            Spacer()
            Button(action: action) {
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
    }
}

struct GroomViewerBottomControls: View {
    let canReply: Bool
    let isSendingReply: Bool
    let isLiked: Bool
    let onSubmitReply: () -> Void
    let onToggleLike: () -> Void
    @Binding var replyDraft: String

    var body: some View {
        HStack(spacing: 10) {
            if canReply {
                GroomViewerReplyComposer(
                    replyDraft: $replyDraft,
                    isSendingReply: isSendingReply,
                    onSubmitReply: onSubmitReply
                )
            } else {
                Spacer()
            }

            GroomViewerLikeButton(
                isLiked: isLiked,
                action: onToggleLike
            )
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 24)
    }
}

private struct GroomViewerReplyComposer: View {
    @Binding var replyDraft: String
    let isSendingReply: Bool
    let onSubmitReply: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            TextField("返信を送る", text: $replyDraft)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .tint(.white)
                .submitLabel(.send)
                .padding(.horizontal, 14)
                .frame(height: 46)
                .background(.white.opacity(0.16), in: Capsule())
                .overlay(Capsule().stroke(.white.opacity(0.22), lineWidth: 1))
                .onSubmit(onSubmitReply)

            Button(action: onSubmitReply) {
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
            .disabled(replyDraft.isBlank || isSendingReply)
            .opacity(replyDraft.isBlank ? 0.52 : 1)
        }
    }
}

private struct GroomViewerLikeButton: View {
    let isLiked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isLiked ? "heart.fill" : "heart")
                .font(.system(size: 24, weight: .heavy))
                .foregroundStyle(isLiked ? MegrumTheme.pink : .white)
                .frame(width: 54, height: 54)
                .background(.black.opacity(0.28), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isLiked ? "いいねを取り消す" : "いいね")
    }
}
