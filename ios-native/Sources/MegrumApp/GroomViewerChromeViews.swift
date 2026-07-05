import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct GroomViewerPageIndicator: View {
    let totalCount: Int
    let currentIndex: Int
    let currentProgress: Double

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalCount, id: \.self) { index in
                GroomViewerPageIndicatorSegment(fillRatio: fillRatio(for: index))
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
    }

    private func fillRatio(for index: Int) -> Double {
        if index < currentIndex {
            return 1
        }
        if index == currentIndex {
            return min(max(currentProgress, 0), 1)
        }
        return 0
    }
}

private struct GroomViewerPageIndicatorSegment: View {
    var fillRatio: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white.opacity(0.28))

                Capsule()
                    .fill(.white)
                    .frame(width: proxy.size.width * CGFloat(fillRatio))
            }
        }
        .frame(height: 3)
    }
}

struct GroomViewerTopBar: View {
    var authorName: String
    var postTimeText: String
    var authorAvatarID: String?
    var authorAvatarURL: URL?
    var canModerate: Bool
    var onReport: () -> Void
    var onBlock: () -> Void
    var onOpenProfile: () -> Void
    let action: () -> Void

    var body: some View {
        HStack {
            Button(action: onOpenProfile) {
                HStack(spacing: 8) {
                    MeguriProfileAvatarView(
                        avatarID: authorAvatarID,
                        avatarURL: authorAvatarURL,
                        fallback: authorName,
                        size: 34
                    )

                    HStack(spacing: 6) {
                        Text(authorName)
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)

                        Text(postTimeText)
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white.opacity(0.78))
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 10)
                .frame(height: 44)
                .frame(maxWidth: 214, alignment: .leading)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(authorName)のプロフィールを開く")

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
            }
            .buttonStyle(.plain)
            .accessibilityLabel("閉じる")
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
    }
}

enum GroomPostRelativeTimeFormatter {
    static func relativeText(from date: Date, now: Date = Date()) -> String {
        let elapsedSeconds = max(0, Int(now.timeIntervalSince(date)))
        if elapsedSeconds < 60 {
            return "たった今"
        }
        let minutes = elapsedSeconds / 60
        if minutes < 60 {
            return "\(minutes)分前"
        }
        let hours = minutes / 60
        if hours < 24 {
            return "\(hours)時間前"
        }
        let days = hours / 24
        if days < 7 {
            return "\(days)日前"
        }
        return date.formatted(.dateTime.month().day())
    }
}

struct GroomViewerBottomControls: View {
    let canReply: Bool
    let canLike: Bool
    let isSendingReply: Bool
    let isLiked: Bool
    let likeCount: Int
    let commentCount: Int
    let onToggleLike: () -> Void
    let onOpenComments: () -> Void
    let onOpenLikes: () -> Void

    var body: some View {
        HStack {
            Spacer()
            GroomViewerEngagementColumn(
                canLike: canLike,
                isLiked: isLiked,
                likeCount: likeCount,
                commentCount: commentCount,
                onToggleLike: onToggleLike,
                onOpenComments: onOpenComments,
                onOpenLikes: onOpenLikes
            )
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 24)
    }
}

struct GroomViewerOwnerBottomControls: View {
    let likeCount: Int
    let commentCount: Int
    let isDeleting: Bool
    let onOpenComments: () -> Void
    let onOpenLikes: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            GroomViewerEngagementColumn(
                canLike: false,
                isLiked: false,
                likeCount: likeCount,
                commentCount: commentCount,
                onToggleLike: {},
                onOpenComments: onOpenComments,
                onOpenLikes: onOpenLikes
            )
            .accessibilityLabel("いいねとコメントを見る")

            Menu {
                Button(role: .destructive, action: onDelete) {
                    Label("削除する", systemImage: "trash")
                }
            } label: {
                Group {
                    if isDeleting {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    } else {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 18, weight: .heavy))
                    }
                }
                .foregroundStyle(.white)
                .frame(width: 54, height: 54)
                .background(.black.opacity(0.28), in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(isDeleting)
            .accessibilityLabel("グルームの操作")
        }
    }
}

struct GroomViewerEngagementColumn: View {
    let canLike: Bool
    let isLiked: Bool
    let likeCount: Int
    let commentCount: Int
    let onToggleLike: () -> Void
    let onOpenComments: () -> Void
    let onOpenLikes: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            GroomViewerLikeButton(
                isLiked: isLiked,
                isEnabled: canLike,
                action: onToggleLike,
                onLongPress: onOpenLikes
            )
            Text("\(likeCount)")
                .font(.system(size: 13, weight: .black, design: .rounded))

            Button(action: onOpenComments) {
                Image(systemName: "bubble.left.fill")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(.black.opacity(0.28), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("コメントを開く")

            Text("\(commentCount)")
                .font(.system(size: 13, weight: .black, design: .rounded))
        }
        .foregroundStyle(.white)
        .accessibilityLabel("いいね\(likeCount)件、コメント\(commentCount)件")
    }
}

private struct GroomViewerReplyComposer: View {
    @Binding var replyDraft: String
    let isSendingReply: Bool
    var isFocused: FocusState<Bool>.Binding
    let onSubmitReply: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            TextField("返信を送る", text: $replyDraft)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .tint(.white)
                .submitLabel(.send)
                .focused(isFocused)
                .padding(.horizontal, 14)
                .frame(height: 46)
                .background(.white.opacity(0.16), in: Capsule())
                .overlay(Capsule().stroke(.white.opacity(0.22), lineWidth: 1))
                .onSubmit(onSubmitReply)

            if isFocused.wrappedValue {
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
                .transition(.opacity.combined(with: .scale(scale: 0.85)))
            }
        }
    }
}

private struct GroomViewerLikeButton: View {
    let isLiked: Bool
    let isEnabled: Bool
    let action: () -> Void
    let onLongPress: () -> Void
    @State private var presentationState = GroomViewerLikeButtonPresentationState()

    var body: some View {
        Button {
            guard isEnabled else {
                return
            }
            action()
        } label: {
            ZStack {
                if presentationState.isBursting {
                    GroomLikeBurst(token: presentationState.burstToken)
                        .allowsHitTesting(false)
                }

                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundStyle(isLiked ? MegrumTheme.pink : .white)
                    .scaleEffect(presentationState.likeIconScale)
                    .frame(width: 54, height: 54)
                    .background(.black.opacity(0.28), in: Circle())
            }
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.82)
        .accessibilityLabel(isLiked ? "いいねを取り消す" : "いいね")
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.45)
                .onEnded { _ in
                    MegrumHaptics.longPress()
                    onLongPress()
                }
        )
        .onChange(of: isLiked) { _, next in
            guard next else { return }
            withAnimation(.spring(response: 0.24, dampingFraction: 0.52)) {
                presentationState.startBurst()
            }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(620))
                withAnimation(.easeOut(duration: 0.16)) {
                    presentationState.finishBurst()
                }
            }
        }
    }
}

struct GroomViewerCommentsSheet: View {
    var groom: GroomPost
    @ObservedObject var appState: MegrumAppState
    var canReply: Bool
    var isSendingReply: Bool
    @Binding var replyDraft: String
    var onSubmitReply: () -> Void
    var onOpenProfile: (UUID) -> Void
    @Environment(\.dismiss) private var dismiss

    private var replies: [GroomReply] {
        appState.groomReplies(for: groom.id).sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(replies) { reply in
                        GroomArchiveUserReactionRow(
                            userID: reply.senderID,
                            identity: identity(userID: reply.senderID),
                            subtitle: reply.createdAt.formatted(date: .abbreviated, time: .shortened),
                            commentBody: reply.body,
                            onOpenProfile: profileAction(userID: reply.senderID),
                            onMessage: nil
                        )
                    }

                    if replies.isEmpty {
                        ContentUnavailableView(
                            "まだコメントはありません",
                            systemImage: "bubble.left",
                            description: Text("最初のコメントを送れます。")
                        )
                        .foregroundStyle(MegrumTheme.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                    }
                }
                .padding(18)
            }
            .background(MegrumTheme.canvas)
            .navigationTitle("コメント")
            .megrumInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if canReply {
                    GroomViewerSheetReplyComposer(
                        replyDraft: $replyDraft,
                        isSendingReply: isSendingReply,
                        onSubmitReply: onSubmitReply
                    )
                }
            }
        }
    }

    private func profileAction(userID: UUID) -> (() -> Void)? {
        guard userID != appState.viewer?.id else {
            return nil
        }
        return {
            dismiss()
            onOpenProfile(userID)
        }
    }

    private func identity(userID: UUID) -> MeguriProfileIdentity {
        let profile = appState.publicProfilesByUserID[userID]?.profile
        return appState.meguriIdentity(
            for: userID,
            fallbackName: profile?.displayName,
            fallbackHandle: profile?.handle,
            fallbackAvatarURL: profile?.avatarURL
        )
    }
}

struct GroomViewerLikesSheet: View {
    var groom: GroomPost
    @ObservedObject var appState: MegrumAppState
    var onOpenProfile: (UUID) -> Void
    @Environment(\.dismiss) private var dismiss

    private var likes: [GroomReaction] {
        appState.groomReactions(for: groom.id).sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(likes) { reaction in
                        GroomArchiveUserReactionRow(
                            userID: reaction.userID,
                            identity: identity(userID: reaction.userID),
                            subtitle: reaction.createdAt.formatted(date: .abbreviated, time: .shortened),
                            commentBody: nil,
                            onOpenProfile: profileAction(userID: reaction.userID),
                            onMessage: nil
                        )
                    }

                    if likes.isEmpty {
                        ContentUnavailableView(
                            "まだいいねはありません",
                            systemImage: "heart",
                            description: Text("いいねした人がここに表示されます。")
                        )
                        .foregroundStyle(MegrumTheme.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                    }
                }
                .padding(18)
            }
            .background(MegrumTheme.canvas)
            .navigationTitle("いいね")
            .megrumInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }

    private func profileAction(userID: UUID) -> (() -> Void)? {
        guard userID != appState.viewer?.id else {
            return nil
        }
        return {
            dismiss()
            onOpenProfile(userID)
        }
    }

    private func identity(userID: UUID) -> MeguriProfileIdentity {
        let profile = appState.publicProfilesByUserID[userID]?.profile
        return appState.meguriIdentity(
            for: userID,
            fallbackName: profile?.displayName,
            fallbackHandle: profile?.handle,
            fallbackAvatarURL: profile?.avatarURL
        )
    }
}

private struct GroomViewerSheetReplyComposer: View {
    @Binding var replyDraft: String
    let isSendingReply: Bool
    let onSubmitReply: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            TextField("コメントを追加", text: $replyDraft)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .submitLabel(.send)
                .padding(.horizontal, 14)
                .frame(height: 46)
                .background(.white, in: Capsule())
                .overlay(Capsule().stroke(MegrumTheme.lavender.opacity(0.16), lineWidth: 1))
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
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
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
