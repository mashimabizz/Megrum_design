import MegrumCore
import MegrumDesign
import SwiftUI

struct GroomArchiveInsightPill: View {
    var likeCount: Int
    var commentCount: Int
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Capsule()
                    .fill(.white.opacity(0.72))
                    .frame(width: 42, height: 4)

                Label("\(likeCount)", systemImage: "heart.fill")
                Label("\(commentCount)", systemImage: "bubble.left.fill")
            }
            .font(.system(size: 14, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .frame(height: 54)
            .frame(maxWidth: .infinity)
            .background(.black.opacity(0.34), in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.18), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("いいねとコメントを見る")
    }
}

struct GroomArchiveInsightsSheet: View {
    var groom: GroomPost
    @ObservedObject var appState: MegrumAppState
    @State private var messageState = GroomArchiveReactionMessageDraftState()
    @State private var profileRoute: MeguriUserProfileRoute?

    private var likes: [GroomReaction] {
        appState.groomReactions(for: groom.id).sorted { $0.createdAt > $1.createdAt }
    }

    private var replies: [GroomReply] {
        appState.groomReplies(for: groom.id).sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack(spacing: 12) {
                    GroomThumbnailCircle(url: groom.imageURL, size: 54)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("反応")
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink)
                        Text(groom.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                    }
                }

                GroomArchiveReactionSection(
                    title: "いいね",
                    systemImage: "heart.fill",
                    emptyText: "まだいいねはありません",
                    isEmpty: likes.isEmpty
                ) {
                    ForEach(likes) { reaction in
                        GroomArchiveUserReactionRow(
                            userID: reaction.userID,
                            identity: reactionIdentity(userID: reaction.userID),
                            subtitle: reaction.createdAt.formatted(date: .abbreviated, time: .shortened),
                            commentBody: nil,
                            onOpenProfile: profileAction(userID: reaction.userID),
                            onMessage: messageAction(
                                userID: reaction.userID,
                                suggestedBody: "いいねありがとうございます",
                                sourceGroomReplyID: nil
                            )
                        )
                    }
                }

                GroomArchiveReactionSection(
                    title: "コメント",
                    systemImage: "bubble.left.fill",
                    emptyText: "まだコメントはありません",
                    isEmpty: replies.isEmpty
                ) {
                    ForEach(replies) { reply in
                        GroomArchiveUserReactionRow(
                            userID: reply.senderID,
                            identity: reactionIdentity(userID: reply.senderID),
                            subtitle: reply.createdAt.formatted(date: .abbreviated, time: .shortened),
                            commentBody: reply.body,
                            onOpenProfile: profileAction(userID: reply.senderID),
                            onMessage: messageAction(
                                userID: reply.senderID,
                                suggestedBody: "コメントありがとうございます",
                                sourceGroomReplyID: reply.id
                            )
                        )
                    }
                }
            }
            .padding(22)
        }
        .background(MegrumTheme.canvas)
        .sheet(item: $profileRoute) { route in
            NavigationStack {
                MeguriUserProfileRouteScreen(
                    appState: appState,
                    userID: route.userID,
                    onClose: { profileRoute = nil },
                    onOpenMessage: { userID in
                        profileRoute = nil
                        messageAction(
                            userID: userID,
                            suggestedBody: "",
                            sourceGroomReplyID: nil
                        )?()
                    }
                )
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $messageState.target, onDismiss: { messageState.dismiss() }) { target in
            GroomArchiveReactionMessageSheet(
                target: target,
                isSending: appState.sendingMeguriMessageRecipientID == target.userID,
                draft: $messageState.draft,
                onCancel: { messageState.dismiss() },
                onSend: sendReactionMessage
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .alert("\(SubscriptionCatalog.currentPremiumDisplayName)でやり取りできます", isPresented: $messageState.isShowingMegrumPlusPrompt) {
            Button("詳しく見る") {
                messageState.showMegrumPlus()
            }
            Button("あとで", role: .cancel) {}
        } message: {
            Text("\(SubscriptionCatalog.currentPremiumDisplayName)に入ると、めぐり内で届いたメッセージの本文表示と返信ができるようになります。")
        }
        .sheet(isPresented: $messageState.isShowingMegrumPlus) {
            NavigationStack {
                SubscriptionSettingsScreen(appState: appState)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    private func messageAction(
        userID: UUID,
        suggestedBody: String,
        sourceGroomReplyID: UUID?
    ) -> (() -> Void)? {
        guard userID != appState.viewer?.id else {
            return nil
        }
        let profile = appState.publicProfilesByUserID[userID]?.profile
        let displayName = profile?.displayName.nilIfBlank
            ?? profile?.handle.nilIfBlank
            ?? "ユーザー"
        return {
            guard appState.subscriptionState.hasMeguriMessageAccess else {
                messageState.showMegrumPlusPrompt()
                return
            }
            messageState.compose(
                to: GroomArchiveReactionMessageTarget(
                    userID: userID,
                    displayName: displayName,
                    sourceGroom: groom,
                    sourceGroomReplyID: sourceGroomReplyID,
                    suggestedBody: suggestedBody
                )
            )
        }
    }

    private func profileAction(userID: UUID) -> (() -> Void)? {
        guard userID != appState.viewer?.id else {
            return nil
        }
        return {
            profileRoute = MeguriUserProfileRoute(userID: userID)
        }
    }

    private func reactionIdentity(userID: UUID) -> MeguriProfileIdentity {
        let profile = appState.publicProfilesByUserID[userID]?.profile
        return appState.meguriIdentity(
            for: userID,
            fallbackName: profile?.displayName,
            fallbackHandle: profile?.handle,
            fallbackAvatarURL: profile?.avatarURL
        )
    }

    private func sendReactionMessage() {
        guard let target = messageState.target else {
            return
        }
        guard appState.subscriptionState.hasMeguriMessageAccess else {
            messageState.showMegrumPlusPrompt()
            return
        }
        Task {
            let sent = await appState.sendMeguriMessage(
                recipientID: target.userID,
                body: messageState.trimmedDraft,
                sourceGroomReplyID: target.sourceGroomReplyID,
                sourceGroomPostID: target.sourceGroom.id,
                sourceGroomOwnerID: target.sourceGroom.authorID,
                sourceGroomImageURL: target.sourceGroom.imageURL
            )
            messageState.clearAfterSend(sent)
        }
    }
}
