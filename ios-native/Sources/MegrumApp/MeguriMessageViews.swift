import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct MeguriMessagePeerRoute: Identifiable, Hashable {
    var peerID: UUID

    var id: UUID { peerID }
}

@MainActor
struct MeguriMessageInboxScreen: View {
    @ObservedObject var appState: MegrumAppState
    @Environment(\.dismiss) private var dismiss

    private var threads: [MeguriMessageThread] {
        appState.meguriMessageThreads
    }

    var body: some View {
        List {
            if appState.isLoadingMeguriMessages, threads.isEmpty {
                MeguriMessageInboxLoadingRow()
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            } else if threads.isEmpty {
                MeguriMessageInboxEmptyState()
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(threads) { thread in
                    NavigationLink {
                        MeguriMessagesScreen(appState: appState, peerID: thread.peerID)
                    } label: {
                        MeguriMessageThreadRow(thread: thread)
                    }
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 14))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .navigationTitle("メッセージ")
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
        .refreshable {
            await appState.loadMeguriMessages()
        }
        .task {
            await appState.loadMeguriMessages()
        }
    }
}

private struct MeguriMessageThreadRow: View {
    var thread: MeguriMessageThread

    var body: some View {
        HStack(spacing: 12) {
            MeguriProfileAvatarView(
                avatarID: thread.avatarID,
                avatarURL: thread.avatarURL,
                fallback: thread.displayName,
                size: 52
            )
                .overlay(alignment: .bottomTrailing) {
                    if thread.unreadCount > 0 {
                        Circle()
                            .fill(MegrumTheme.pink)
                            .frame(width: 13, height: 13)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    }
                }

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(thread.displayName)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)
                        .lineLimit(1)

                    if let handle = thread.handle?.nilIfBlank {
                        Text("@\(handle)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 6)

                    Text(thread.lastMessage.createdAt.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }

                HStack(spacing: 8) {
                    if thread.lastMessage.locked {
                        MeguriLockedMessagePreview()
                    } else {
                        Text(thread.lastMessagePreview)
                            .font(.system(size: 13, weight: thread.unreadCount > 0 ? .black : .semibold, design: .rounded))
                            .foregroundStyle(thread.unreadCount > 0 ? MegrumTheme.ink : MegrumTheme.muted)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 6)

                    if thread.unreadCount > 0 {
                        Text("\(thread.unreadCount)")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(minWidth: 22, minHeight: 22)
                            .padding(.horizontal, thread.unreadCount > 9 ? 5 : 0)
                            .background(MegrumTheme.pink, in: Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        let unreadText = thread.unreadCount > 0 ? "、未読\(thread.unreadCount)件" : ""
        if thread.lastMessage.locked {
            return "\(thread.displayName)、プレミアムで表示できるメッセージ\(unreadText)"
        }
        return "\(thread.displayName)、\(thread.lastMessagePreview)\(unreadText)"
    }
}

private struct MeguriMessageInboxLoadingRow: View {
    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
                .controlSize(.small)
            Text("メッセージを読み込んでいます")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MegrumTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 20)
    }
}

private struct MeguriMessageInboxEmptyState: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "message.fill")
                .font(.system(size: 24, weight: .black))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(width: 50, height: 50)
                .background(MegrumTheme.lavender.opacity(0.12), in: Circle())

            Text("まだメッセージはありません")
                .font(.headline.weight(.bold))
                .foregroundStyle(MegrumTheme.ink)
            Text("グルームへの返信や、めぐりで届いた会話がここに表示されます。")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MegrumTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 26)
    }
}

@MainActor
struct MeguriMessagesScreen: View {
    @ObservedObject var appState: MegrumAppState
    var peerID: UUID
    @State private var draft = ""
    @State private var isShowingMegrumPlus = false

    private var messages: [MeguriMessage] {
        appState.meguriMessages(with: peerID)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                MeguriMessageList(
                    messages: messages,
                    viewerID: appState.viewer?.id,
                    isLoading: appState.isLoadingMeguriMessages,
                    onOpenPremium: openMegrumPlus
                )
                .onChange(of: messages.count) { _, _ in
                    guard let lastID = messages.last?.id else {
                        return
                    }
                    withAnimation(.snappy(duration: 0.24)) {
                        proxy.scrollTo(lastID, anchor: .bottom)
                    }
                }
            }

            MeguriMessageInput(
                text: $draft,
                isSending: appState.sendingMeguriMessageRecipientID == peerID
            ) { sendMessage() }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .navigationTitle(peerTitle)
        .megrumInlineNavigationTitle()
        .sheet(isPresented: $isShowingMegrumPlus) {
            NavigationStack {
                SubscriptionSettingsScreen(appState: appState)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .task {
            await appState.loadMeguriMessages()
            await appState.markMeguriMessagesRead(peerID: peerID)
        }
    }

    private func sendMessage() {
        Task {
            let sent = await appState.sendMeguriMessage(recipientID: peerID, body: draft)
            if sent {
                draft = ""
            }
        }
    }

    private func openMegrumPlus() {
        isShowingMegrumPlus = true
    }

    private var peerTitle: String {
        if let name = appState.meguriProfile(for: peerID)?.displayName.nilIfBlank {
            return name
        }
        for message in messages {
            if message.senderID == peerID {
                return displayName(name: message.senderDisplayName, handle: message.senderHandle)
            }
            if message.recipientID == peerID {
                return displayName(name: message.recipientDisplayName, handle: message.recipientHandle)
            }
        }
        return "めぐりメッセージ"
    }

    private func displayName(name: String?, handle: String?) -> String {
        if let name, !name.isEmpty {
            return name
        }
        if let handle, !handle.isEmpty {
            return "@\(handle)"
        }
        return "めぐりメッセージ"
    }
}
