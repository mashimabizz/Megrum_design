import Foundation
import MegrumDesign
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// リプライ対象（取引チャット・めぐりメッセージ・チャットルーム共通）。
struct ChatReplyTarget: Equatable {
    var messageID: UUID?
    var senderID: UUID?
    var senderName: String
    var avatarID: String?
    var avatarURL: URL?
    var initial: String
    var body: String

    init(
        messageID: UUID? = nil,
        senderID: UUID?,
        senderName: String,
        avatarID: String?,
        avatarURL: URL?,
        initial: String,
        body: String
    ) {
        self.messageID = messageID
        self.senderID = senderID
        self.senderName = senderName
        self.avatarID = avatarID
        self.avatarURL = avatarURL
        self.initial = initial
        self.body = body
    }
}

/// バブルに表示する引用（返信元）の構造化データ。
struct ChatReplyQuote: Equatable {
    var messageID: UUID?
    var senderID: UUID?
    var senderName: String
    var preview: String
}

/// リプライの引用をメッセージ本文へ埋め込み／取り出しするフォーマッタ。
/// DBスキーマを変えずに3チャットで同じ見た目のリプライを実現する。
enum ChatReplyQuoteFormatter {
    static let marker = "\u{21A9}\u{FE0E} "
    static let previewLimit = 40

    static func preview(of body: String) -> String {
        let flattened = body
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard flattened.count > previewLimit else {
            return flattened
        }
        return String(flattened.prefix(previewLimit)) + "…"
    }

    /// 不可視区切り（U+2063）で メッセージID|送信者ID を埋め込む（タップジャンプ・アイコン解決用）。
    static let metaSeparator = "\u{2063}"

    static func compose(reply: ChatReplyTarget, body: String) -> String {
        let meta = "\(reply.messageID?.uuidString ?? "")|\(reply.senderID?.uuidString ?? "")"
        return "\(marker)\(metaSeparator)\(meta)\(metaSeparator)\(reply.senderName)「\(preview(of: reply.body))」\n\(body)"
    }

    /// 本文から引用を分離する。引用が無ければ quote は nil。
    static func parse(_ body: String) -> (quote: ChatReplyQuote?, text: String) {
        guard body.hasPrefix(marker),
              let newlineIndex = body.firstIndex(of: "\n")
        else {
            return (nil, body)
        }
        var quoteRaw = String(body[body.index(body.startIndex, offsetBy: marker.count)..<newlineIndex])
        let text = String(body[body.index(after: newlineIndex)...])

        var messageID: UUID?
        var senderID: UUID?
        if quoteRaw.hasPrefix(metaSeparator) {
            let parts = quoteRaw.dropFirst().components(separatedBy: metaSeparator)
            if parts.count >= 2 {
                let ids = parts[0].components(separatedBy: "|")
                messageID = ids.first.flatMap(UUID.init(uuidString:))
                senderID = ids.count > 1 ? UUID(uuidString: ids[1]) : nil
                quoteRaw = parts.dropFirst().joined(separator: metaSeparator)
            }
        }

        // 「名前「プレビュー」」を分解（旧形式は名前と本文が繋がったまま表示する）。
        let name: String
        let preview: String
        if let openIndex = quoteRaw.firstIndex(of: "「"), quoteRaw.hasSuffix("」") {
            name = String(quoteRaw[..<openIndex])
            preview = String(quoteRaw[quoteRaw.index(after: openIndex)..<quoteRaw.index(before: quoteRaw.endIndex)])
        } else {
            name = ""
            preview = quoteRaw
        }
        return (
            ChatReplyQuote(messageID: messageID, senderID: senderID, senderName: name, preview: preview),
            text
        )
    }

    static func copyText(of body: String) -> String {
        parse(body).text
    }
}

/// 入力欄の上に出すリプライ先プレビュー（アイコン・名前・元メッセージ・×）。
struct ChatReplyComposerPreview: View {
    var target: ChatReplyTarget
    var onCancel: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            BoardThreadDetailAvatar(
                avatarID: target.avatarID,
                imageURL: target.avatarURL,
                initial: target.initial,
                size: 30
            )

            VStack(alignment: .leading, spacing: 1) {
                Text(target.senderName)
                    .font(.system(size: 12.5, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(1)
                Text(ChatReplyQuoteFormatter.preview(of: target.body))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Button {
                MegrumHaptics.performButtonTap(onCancel)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(MegrumTheme.muted)
                    .frame(width: 34, height: 34)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("リプライを取り消す")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.white.opacity(0.96))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(.black.opacity(0.07))
                .frame(height: 0.5)
        }
    }
}

/// バブル内に出す引用表示：左に返信元アイコン、名前は太字・元メッセージは薄字。
/// タップで元メッセージへスクロールできる（onTap 指定時）。
struct ChatReplyQuoteLine: View {
    var quote: ChatReplyQuote
    var isMine: Bool
    var avatarID: String?
    var avatarURL: URL?
    var onTap: (() -> Void)?

    var body: some View {
        Button {
            if let onTap {
                MegrumHaptics.performButtonTap(onTap)
            }
        } label: {
            HStack(spacing: 7) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(isMine ? Color.white.opacity(0.7) : MegrumTheme.lavender)
                    .frame(width: 3)

                BoardThreadDetailAvatar(
                    avatarID: avatarID,
                    imageURL: avatarURL,
                    initial: String(quote.senderName.prefix(1)).uppercased(),
                    size: 22
                )

                (
                    Text(quote.senderName.isEmpty ? "" : "\(quote.senderName)")
                        .font(.system(size: 11.5, weight: .black, design: .rounded))
                        .foregroundStyle(isMine ? Color.white.opacity(0.92) : MegrumTheme.ink.opacity(0.82))
                    + Text("「\(quote.preview)」")
                        .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(isMine ? Color.white.opacity(0.6) : MegrumTheme.muted.opacity(0.85))
                )
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
        .padding(.bottom, 4)
        .accessibilityLabel("返信元: \(quote.senderName) \(quote.preview)")
    }
}

extension View {
    /// LINE風の長押しメニュー（コピー・リプライ・通報）＋右スワイプでリプライ。
    /// - Parameters:
    ///   - copyText: コピーするテキスト（nil なら項目を出さない）
    ///   - onReply: リプライ開始（nil なら項目を出さない。右スワイプも無効）
    ///   - onReport: 通報（nil なら項目を出さない）
    func chatMessageInteraction(
        copyText: String?,
        onReply: (() -> Void)?,
        onReport: (() -> Void)?
    ) -> some View {
        self
            .contextMenu {
                if let copyText {
                    Button {
                        #if canImport(UIKit)
                        UIPasteboard.general.string = copyText
                        #endif
                    } label: {
                        Label("コピー", systemImage: "doc.on.doc")
                    }
                }
                if let onReply {
                    Button {
                        onReply()
                    } label: {
                        Label("リプライ", systemImage: "arrowshape.turn.up.left")
                    }
                }
                if let onReport {
                    Button(role: .destructive) {
                        onReport()
                    } label: {
                        Label("通報", systemImage: "exclamationmark.bubble")
                    }
                }
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 24)
                    .onEnded { value in
                        guard let onReply else {
                            return
                        }
                        let horizontal = abs(value.translation.width)
                        let vertical = abs(value.translation.height)
                        // 左右どちらでも、はっきり横へスワイプした時にリプライを開始する。
                        if horizontal > 56, horizontal > vertical * 1.4 {
                            MegrumHaptics.buttonTap()
                            onReply()
                        }
                    }
            )
    }
}
