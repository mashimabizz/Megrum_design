import MegrumCore
import MegrumDesign
import SwiftUI

struct MeguriScreen: View {
    @ObservedObject var appState: MegrumAppState
    @State private var selectedThread: BoardThread?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                ScreenTitle(title: "グルーム", subtitle: "近くの投稿と掲示板")

                VStack(alignment: .leading, spacing: 14) {
                    SectionHeader(title: "グルーム", actionTitle: "地図で見る")
                    GroomStrip(grooms: appState.grooms)
                }

                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        SectionHeader(title: "掲示板", actionTitle: "地図で見る")
                        if appState.isLoadingMeguri {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }

                    ForEach(appState.threads) { thread in
                        Button {
                            selectedThread = thread
                        } label: {
                            BoardThreadCard(thread: thread)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 112)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .megrumHiddenNavigationBar()
        .refreshable {
            await appState.loadMeguriFeed()
        }
        .sheet(item: $selectedThread) { thread in
            NavigationStack {
                BoardThreadDetailScreen(appState: appState, thread: thread)
            }
        }
        .safeAreaInset(edge: .bottom, alignment: .trailing) {
            Button {
            } label: {
                Label("スレッドを立てる", systemImage: "plus")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .padding(.horizontal, 18)
                    .frame(height: 54)
                    .background(MegrumTheme.lavender, in: Capsule())
                    .foregroundStyle(.white)
                    .shadow(color: MegrumTheme.lavender.opacity(0.32), radius: 16, y: 8)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 20)
            .padding(.bottom, 10)
        }
    }
}

private struct BoardThreadDetailScreen: View {
    @ObservedObject var appState: MegrumAppState
    var thread: BoardThread
    @Environment(\.dismiss) private var dismiss
    @State private var draftReply = ""

    private var replies: [BoardReply] {
        appState.boardReplies(for: thread.id)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    BoardThreadCard(thread: thread)

                    HStack {
                        Text("返信")
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink)

                        if appState.loadingBoardRepliesThreadID == thread.id {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }

                    ForEach(replies) { reply in
                        BoardReplyBubble(
                            reply: reply,
                            isMine: reply.authorID == appState.viewer?.id
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 22)
            }

            BoardReplyInput(
                text: $draftReply,
                isSending: appState.sendingBoardReplyThreadID == thread.id
            ) {
                Task {
                    let sent = await appState.sendBoardReply(threadID: thread.id, body: draftReply, scope: thread.audience)
                    if sent {
                        draftReply = ""
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .navigationTitle("掲示板")
        .megrumInlineNavigationTitle()
        .task {
            await appState.loadBoardReplies(threadID: thread.id, scope: thread.audience)
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
    }
}

private struct BoardReplyBubble: View {
    var reply: BoardReply
    var isMine: Bool

    var body: some View {
        VStack(alignment: isMine ? .trailing : .leading, spacing: 4) {
            Text(reply.status == .deleted ? "削除済みです" : reply.body)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(isMine ? .white : MegrumTheme.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    isMine ? AnyShapeStyle(MegrumTheme.lavender) : AnyShapeStyle(.white.opacity(0.9)),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )

            Text(reply.createdAt.formatted(date: .omitted, time: .shortened))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: isMine ? .trailing : .leading)
    }
}

private struct BoardReplyInput: View {
    @Binding var text: String
    var isSending: Bool
    var onSend: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            TextField("返信を入力", text: $text, axis: .vertical)
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

private struct SectionHeader: View {
    var title: String
    var actionTitle: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 25, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Spacer()

            Button(actionTitle) {
            }
            .font(.system(size: 14, weight: .heavy, design: .rounded))
            .foregroundStyle(MegrumTheme.lavender)
        }
    }
}

private struct GroomStrip: View {
    var grooms: [GroomPost]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(grooms) { groom in
                    VStack(spacing: 8) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [MegrumTheme.sky, MegrumTheme.pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 72, height: 72)
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(.white)
                            }

                        Text("1km圏内")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                    }
                    .id(groom.id)
                }
            }
            .padding(.vertical, 2)
        }
    }
}

private struct BoardThreadCard: View {
    var thread: BoardThread

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(scopeText)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(MegrumTheme.lavender.opacity(0.12), in: Capsule())

                Spacer()
            }

            Text(thread.title)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Text(thread.body)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .lineLimit(2)
        }
        .padding(16)
        .background(.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: MegrumTheme.ink.opacity(0.06), radius: 14, y: 7)
    }

    private var scopeText: String {
        switch thread.audience {
        case .nearby3km:
            "3km圏内"
        case .samePrefecture:
            thread.prefecture ?? "都道府県"
        case .sameSpot:
            "スポット"
        case .global:
            "全体"
        }
    }
}
