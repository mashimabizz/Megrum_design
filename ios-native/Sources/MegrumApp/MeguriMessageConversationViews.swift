import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct MeguriMessageList: View {
    var messages: [MeguriMessage]
    var viewerID: UUID?
    var isLoading: Bool
    var onOpenPremium: () -> Void = {}

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if isLoading {
                    MeguriMessageLoadingRow()
                } else if messages.isEmpty {
                    MeguriMessageEmptyState()
                } else {
                    ForEach(messages) { message in
                        MeguriMessageBubble(
                            message: message,
                            isMine: message.senderID == viewerID,
                            onOpenPremium: onOpenPremium
                        )
                        .id(message.id)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 18)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

private struct MeguriMessageLoadingRow: View {
    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
                .controlSize(.small)
            Text("読み込んでいます")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MegrumTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 12)
    }
}

private struct MeguriMessageEmptyState: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("まだメッセージはありません")
                .font(.headline.weight(.bold))
                .foregroundStyle(MegrumTheme.ink)
            Text("グルームへの返信から、そのまま会話を始められます。")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MegrumTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 12)
    }
}

struct MeguriMessageBubble: View {
    var message: MeguriMessage
    var isMine: Bool
    var onOpenPremium: () -> Void = {}

    var body: some View {
        VStack(alignment: isMine ? .trailing : .leading, spacing: 4) {
            if message.locked && !isMine {
                Button(action: onOpenPremium) {
                    MeguriLockedMessageBubbleContent()
                }
                .buttonStyle(.plain)
                .accessibilityLabel("プレミアムでメッセージを表示")
            } else {
                Text(messageText)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(isMine ? .white : MegrumTheme.ink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        isMine ? AnyShapeStyle(MegrumTheme.lavender) : AnyShapeStyle(.white.opacity(0.9)),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
            }

            Text(message.createdAt.formatted(date: .omitted, time: .shortened))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: isMine ? .trailing : .leading)
    }

    private var messageText: String {
        if message.locked {
            return "このメッセージは現在表示できません"
        }
        if let body = message.body, !body.isEmpty {
            return body
        }
        return message.messageType == .image ? "画像" : ""
    }
}

struct MeguriMessageInput: View {
    @Binding var text: String
    var isSending: Bool
    var onSend: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            TextField("メッセージ", text: $text, axis: .vertical)
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
            .disabled(text.isBlank || isSending)
            .opacity(text.isBlank ? 0.45 : 1)
            .accessibilityLabel("送信")
        }
    }
}
