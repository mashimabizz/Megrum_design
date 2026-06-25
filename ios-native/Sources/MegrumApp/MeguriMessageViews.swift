import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct MeguriMessagePeerRoute: Identifiable, Hashable {
    var peerID: UUID

    var id: UUID { peerID }
}

@MainActor
struct MeguriMessagesScreen: View {
    @ObservedObject var appState: MegrumAppState
    var peerID: UUID
    @State private var draft = ""

    private var messages: [MeguriMessage] {
        appState.meguriMessages(with: peerID)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                MeguriMessageList(
                    messages: messages,
                    viewerID: appState.viewer?.id,
                    isLoading: appState.isLoadingMeguriMessages
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

    private var peerTitle: String {
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
