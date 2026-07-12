import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

/// iter1226.449/450：他人のグルーム最下部のメッセージ入力（インスタのストーリー返信風）。
/// - 未入力：丸みのある入力欄プレースホルダ「メッセージを送信…」。タップでフォーカス。
/// - 1文字でも入力：右端に送信ボタンが出る。
private let groomMessagePlaceholder = "メッセージを送信…"

/// カプセルの見た目（入力欄・静的ピルで共有）。
private struct GroomMessageComposerCapsule: ViewModifier {
    var trailingTight: Bool
    func body(content: Content) -> some View {
        content
            .padding(.leading, 18)
            .padding(.trailing, trailingTight ? 6 : 18)
            .padding(.vertical, 11)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.12))
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.white.opacity(0.65), lineWidth: 1.2)
                    )
            )
    }
}

struct GroomViewerMessageComposer: View {
    /// プレミアム（メッセージ送信権）を持っているか。false ならタップで入力させず案内を出す。
    var canSend: Bool
    @Binding var text: String
    @Binding var isFocused: Bool
    var isSending: Bool
    var onSend: () -> Void
    /// 非プレミアムで入力欄をタップした時（プレミアム案内を出す）。
    var onBlockedTap: () -> Void

    private var trimmed: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        HStack(spacing: 10) {
            if canSend {
                #if canImport(UIKit)
                GroomMessageDarkTextField(
                    text: $text,
                    isFocused: $isFocused,
                    placeholder: groomMessagePlaceholder,
                    onSend: onSend
                )
                .frame(minHeight: 24)
                #else
                TextField(groomMessagePlaceholder, text: $text)
                    .foregroundStyle(.white)
                #endif
            } else {
                Button(action: onBlockedTap) {
                    HStack {
                        Text(groomMessagePlaceholder)
                            .foregroundStyle(.white.opacity(0.72))
                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            if canSend, !trimmed.isEmpty {
                Button(action: onSend) {
                    if isSending {
                        ProgressView()
                            .tint(.white)
                            .frame(width: 30, height: 30)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(MegrumTheme.sky, in: Circle())
                    }
                }
                .buttonStyle(.plain)
                .disabled(isSending)
                .transition(.scale.combined(with: .opacity))
                .accessibilityLabel("送信")
            }
        }
        .modifier(GroomMessageComposerCapsule(trailingTight: canSend && !trimmed.isEmpty))
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: trimmed.isEmpty)
    }
}

#if canImport(UIKit)
/// iter1226.451：暗いキーボード＋白文字の入力欄。SwiftUI TextField では keyboardAppearance を
/// 制御できないため UITextField を薄くラップする。isFocused の双方向で first responder を制御。
struct GroomMessageDarkTextField: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    var placeholder: String
    var onSend: () -> Void

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.delegate = context.coordinator
        field.keyboardAppearance = .dark
        field.textColor = .white
        field.tintColor = .white
        field.autocapitalizationType = .sentences
        field.returnKeyType = .send
        field.backgroundColor = .clear
        field.font = .systemFont(ofSize: 15)
        field.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.72)]
        )
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        // iter1226.454：縦は intrinsic（1行）で固定。これをしないと SwiftUI が縦いっぱいまで
        // 引き伸ばし、カプセルが画面全体の楕円になってプレースホルダが中央左にズレていた。
        field.setContentHuggingPriority(.required, for: .vertical)
        field.setContentCompressionResistancePriority(.required, for: .vertical)
        field.addTarget(context.coordinator, action: #selector(Coordinator.editingChanged(_:)), for: .editingChanged)
        return field
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextField, context: Context) -> CGSize? {
        // 幅は提案どおり、高さは1行ぶんに固定（縦への引き伸ばしを防ぐ）。
        let width = proposal.width ?? uiView.intrinsicContentSize.width
        return CGSize(width: width, height: uiView.intrinsicContentSize.height)
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        DispatchQueue.main.async {
            if isFocused, !uiView.isFirstResponder {
                uiView.becomeFirstResponder()
            } else if !isFocused, uiView.isFirstResponder {
                uiView.resignFirstResponder()
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: GroomMessageDarkTextField
        init(_ parent: GroomMessageDarkTextField) { self.parent = parent }

        @objc func editingChanged(_ field: UITextField) {
            parent.text = field.text ?? ""
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            if !parent.isFocused { parent.isFocused = true }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            if parent.isFocused { parent.isFocused = false }
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            parent.onSend()
            return false
        }
    }
}
#endif

/// iter1226.451：グルームのメッセージ送信はプレミアム必須。非会員がタップ/送信した時の案内。
struct GroomMessageLockedPremiumSheet: View {
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.circle.fill")
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(MegrumTheme.lavender)
                .padding(.top, 26)

            Text("グルームでコメントを送るには\n\(SubscriptionCatalog.currentPremiumDisplayName)の入会が必要です")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text("めぐり内のメッセージのやり取りは\n\(SubscriptionCatalog.currentPremiumDisplayName)で利用できます。")
                .font(.system(size: 13.5, weight: .medium, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button("閉じる") {
                onClose()
            }
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(MegrumTheme.muted)
            .padding(.top, 4)
            .padding(.bottom, 12)
        }
        .padding(.horizontal, 24)
        .presentationDetents([.height(300)])
        .presentationDragIndicator(.visible)
    }
}

/// iter1226.451：メッセージ送信完了トースト（中央・グレー背景・白文字）。
struct GroomMessageSentToast: View {
    var body: some View {
        Text("メッセージが送信されました")
            .font(.system(size: 14.5, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 13)
            .background(
                Capsule(style: .continuous)
                    .fill(Color(white: 0.18).opacity(0.94))
            )
            .shadow(color: .black.opacity(0.25), radius: 12, y: 4)
    }
}

/// iter1226.450：立方体回転中の面に貼り付ける静的な入力欄（操作不可・見た目のみ）。
struct GroomViewerMessageComposerStatic: View {
    var body: some View {
        HStack {
            Text(groomMessagePlaceholder)
                .foregroundStyle(.white.opacity(0.72))
            Spacer(minLength: 0)
        }
        .modifier(GroomMessageComposerCapsule(trailingTight: false))
        .allowsHitTesting(false)
    }
}

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

            // iter1226.440：通報/ブロックの三点リーダーは右下（コメント位置の下）へ移動した。
            Color.clear
                .frame(width: 44, height: 44)

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

/// いいね・コメントの未選択時アイコン色（少し透明なグレー）。
enum GroomViewerEngagementStyle {
    static let idleIconColor = Color(white: 0.94).opacity(0.72)
}

struct GroomViewerBottomControls: View {
    let canLike: Bool
    let isLiked: Bool
    let likeCount: Int
    let onToggleLike: () -> Void
    let onOpenLikes: () -> Void
    let onReport: () -> Void
    let onBlock: () -> Void

    var body: some View {
        HStack {
            Spacer()
            // iter1226.440：他人のグルームはコメントアイコンを出さず、
            // 三点リーダー（通報/ブロック）を自分のグルームと同じ位置（右下の列）に置く。
            VStack(alignment: .trailing, spacing: 8) {
                GroomViewerEngagementColumn(
                    canLike: canLike,
                    isLiked: isLiked,
                    likeCount: likeCount,
                    commentCount: 0,
                    onToggleLike: onToggleLike,
                    onOpenComments: {},
                    onOpenLikes: onOpenLikes,
                    showsComments: false
                )

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
                        .frame(width: 54, height: 54)
                        .background(.black.opacity(0.28), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("グルームのメニュー")
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 24)
    }
}

struct GroomViewerOwnerBottomControls: View {
    let isLiked: Bool
    let likeCount: Int
    let commentCount: Int
    let isDeleting: Bool
    let onToggleLike: () -> Void
    let onOpenComments: () -> Void
    let onOpenLikes: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            // 自分のグルームにもいいねできる（RLSも合わせて解放済み）。
            GroomViewerEngagementColumn(
                canLike: true,
                isLiked: isLiked,
                likeCount: likeCount,
                commentCount: commentCount,
                onToggleLike: onToggleLike,
                onOpenComments: onOpenComments,
                onOpenLikes: onOpenLikes
            )

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

    var showsComments = true

    var body: some View {
        VStack(spacing: 14) {
            // iter1226.472：いいねアイコン＋数を1つのタップ判定に統合（数字を押しても反応）。
            GroomViewerLikeButton(
                isLiked: isLiked,
                isEnabled: canLike,
                likeCount: likeCount,
                action: onToggleLike,
                onLongPress: onOpenLikes
            )

            if showsComments {
                VStack(spacing: 3) {
                    Button(action: onOpenComments) {
                        Image(systemName: "bubble.left.fill")
                            .font(.system(size: 26, weight: .heavy))
                            .foregroundStyle(GroomViewerEngagementStyle.idleIconColor)
                            .shadow(color: .black.opacity(0.35), radius: 6, y: 1)
                            .frame(width: 44, height: 40)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("コメントを開く")

                    Text("\(commentCount)")
                        .font(.system(size: 12.5, weight: .black, design: .rounded))
                        .shadow(color: .black.opacity(0.4), radius: 4, y: 1)
                }
            }
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
    let likeCount: Int
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
            // iter1226.472：アイコン＋いいね数をひとまとまりのタップ判定にする。
            // アイコン・数字のサイズは据え置き。間の余白まで contentShape で拾えるようにして、
            // いいね数の部分を押しても「いいね」判定になるようにする。
            VStack(spacing: 3) {
                // 未押下時も枠線と同じ色で中まで塗る（塗り付きハート）。
                Image(systemName: "heart.fill")
                    .font(.system(size: 30, weight: .heavy))
                    .foregroundStyle(isLiked ? Color.red : GroomViewerEngagementStyle.idleIconColor)
                    .shadow(color: .black.opacity(0.35), radius: 6, y: 1)
                    .scaleEffect(presentationState.likeIconScale)
                    .frame(width: 48, height: 44)

                Text("\(likeCount)")
                    .font(.system(size: 12.5, weight: .black, design: .rounded))
                    .shadow(color: .black.opacity(0.4), radius: 4, y: 1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.82)
        .accessibilityLabel(isLiked ? "いいねを取り消す" : "いいね")
        .accessibilityValue("\(likeCount)")
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.45)
                .onEnded { _ in
                    MegrumHaptics.longPress()
                    onLongPress()
                }
        )
        .onChange(of: isLiked) { _, next in
            guard next else { return }
            // 周囲の演出は出さず、ハート自体の弾みだけにする。
            withAnimation(.spring(response: 0.24, dampingFraction: 0.52)) {
                presentationState.startBurst()
            }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(320))
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
        let allReplies = appState.groomReplies(for: groom.id).sorted { $0.createdAt > $1.createdAt }
        // コメントは投稿者本人には全件、他のユーザーには自分が送ったものだけ表示する。
        guard let viewerID = appState.viewer?.id, viewerID != groom.authorID else {
            return allReplies
        }
        return allReplies.filter { $0.senderID == viewerID }
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
            .task(id: replies.map(\.senderID)) {
                await loadMissingSenderProfiles()
            }
        }
    }

    /// コメント送信者のプロフィールが未読み込みだと名前・アイコンが出ないため補充する。
    private func loadMissingSenderProfiles() async {
        let missing = Set(replies.map(\.senderID)).filter { userID in
            userID != appState.viewer?.id && appState.publicProfilesByUserID[userID] == nil
        }
        for userID in missing {
            await appState.loadPublicUserProfile(userID: userID, reportsFailure: false)
        }
    }

    private func profileAction(userID: UUID) -> (() -> Void)? {
        {
            dismiss()
            onOpenProfile(userID)
        }
    }

    private func identity(userID: UUID) -> MeguriProfileIdentity {
        // 自分のコメントは viewer のプロフィールで表示する
        //（publicProfilesByUserID に自分は入らないため）。
        if let viewer = appState.viewer, viewer.id == userID {
            return appState.meguriIdentity(
                for: userID,
                fallbackName: viewer.displayName,
                fallbackHandle: viewer.handle,
                fallbackAvatarURL: viewer.avatarURL
            )
        }
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
        {
            dismiss()
            onOpenProfile(userID)
        }
    }

    private func identity(userID: UUID) -> MeguriProfileIdentity {
        if let viewer = appState.viewer, viewer.id == userID {
            return appState.meguriIdentity(
                for: userID,
                fallbackName: viewer.displayName,
                fallbackHandle: viewer.handle,
                fallbackAvatarURL: viewer.avatarURL
            )
        }
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


