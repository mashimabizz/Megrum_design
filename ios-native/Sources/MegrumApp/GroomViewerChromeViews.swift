import Foundation
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

struct GroomViewerTopBar: View {
    var authorName: String
    var authorAvatarID: String?
    var authorAvatarURL: URL?
    var canModerate: Bool
    var onReport: () -> Void
    var onBlock: () -> Void
    let action: () -> Void

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                MeguriProfileAvatarView(
                    avatarID: authorAvatarID,
                    avatarURL: authorAvatarURL,
                    fallback: authorName,
                    size: 34
                )

                Text(authorName)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .padding(.horizontal, 10)
            .frame(height: 44)
            .frame(maxWidth: 176, alignment: .leading)
            .background(.black.opacity(0.28), in: Capsule())

            if canModerate {
                Menu {
                    Button(role: .destructive, action: onReport) {
                        Label("通報する", systemImage: "exclamationmark.bubble")
                    }
                    Button(role: .destructive, action: onBlock) {
                        Label("ブロックする", systemImage: "person.crop.circle.badge.xmark")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(.black.opacity(0.28), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("グルームのメニュー")
            } else {
                Color.clear
                    .frame(width: 44, height: 44)
            }

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
    let canLike: Bool
    let isSendingReply: Bool
    let isLiked: Bool
    let likeCount: Int
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

            if canLike {
                GroomViewerLikeButton(
                    isLiked: isLiked,
                    likeCount: likeCount,
                    action: onToggleLike
                )
            }
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
    let likeCount: Int
    let action: () -> Void
    @State private var burstToken = UUID()
    @State private var isBursting = false

    var body: some View {
        Button(action: action) {
            ZStack {
                if isBursting {
                    GroomLikeBurst(token: burstToken)
                        .allowsHitTesting(false)
                }

                VStack(spacing: 2) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundStyle(isLiked ? MegrumTheme.pink : .white)
                        .scaleEffect(isBursting ? 1.16 : 1)

                    if likeCount > 0 {
                        Text("\(likeCount)")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(isLiked ? MegrumTheme.pink : .white.opacity(0.86))
                    }
                }
                .frame(width: 54, height: 54)
                .background(.black.opacity(0.28), in: Circle())
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isLiked ? "いいねを取り消す" : "いいね")
        .onChange(of: isLiked) { _, next in
            guard next else { return }
            burstToken = UUID()
            withAnimation(.spring(response: 0.24, dampingFraction: 0.52)) {
                isBursting = true
            }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(620))
                withAnimation(.easeOut(duration: 0.16)) {
                    isBursting = false
                }
            }
        }
    }
}

private struct GroomLikeBurst: View {
    var token: UUID

    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { index in
                Image(systemName: index.isMultiple(of: 2) ? "heart.fill" : "sparkle")
                    .font(.system(size: index.isMultiple(of: 2) ? 12 : 10, weight: .heavy))
                    .foregroundStyle(index.isMultiple(of: 2) ? MegrumTheme.pink : .white)
                    .offset(burstOffset(index))
                    .opacity(0.92)
                    .animation(
                        .easeOut(duration: 0.58).delay(Double(index) * 0.025),
                        value: token
                    )
            }
        }
        .frame(width: 86, height: 86)
        .transition(.scale.combined(with: .opacity))
    }

    private func burstOffset(_ index: Int) -> CGSize {
        let offsets: [CGSize] = [
            CGSize(width: -26, height: -24),
            CGSize(width: 0, height: -34),
            CGSize(width: 28, height: -22),
            CGSize(width: -30, height: 8),
            CGSize(width: 28, height: 10),
            CGSize(width: 2, height: 30)
        ]
        return offsets[index % offsets.count]
    }
}
