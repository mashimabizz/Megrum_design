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
    /// リプライ先が画像メッセージの時のサムネイルURL。
    var imageURL: URL?

    init(
        messageID: UUID? = nil,
        senderID: UUID?,
        senderName: String,
        avatarID: String?,
        avatarURL: URL?,
        initial: String,
        body: String,
        imageURL: URL? = nil
    ) {
        self.messageID = messageID
        self.senderID = senderID
        self.senderName = senderName
        self.avatarID = avatarID
        self.avatarURL = avatarURL
        self.initial = initial
        self.body = body
        self.imageURL = imageURL
    }

    /// 表示用の本文（画像のみのメッセージは「写真」）。
    var displayBody: String {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return imageURL != nil ? "写真" : ""
        }
        return trimmed
    }
}

/// バブルに表示する引用（返信元）の構造化データ。
struct ChatReplyQuote: Equatable {
    var messageID: UUID?
    var senderID: UUID?
    var senderName: String
    var preview: String
    var imageURL: URL?
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
        let encodedImageURL = reply.imageURL?.absoluteString
            .addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
        let meta = "\(reply.messageID?.uuidString ?? "")|\(reply.senderID?.uuidString ?? "")|\(encodedImageURL)"
        return "\(marker)\(metaSeparator)\(meta)\(metaSeparator)\(reply.senderName)「\(preview(of: reply.displayBody))」\n\(body)"
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
        var imageURL: URL?
        if quoteRaw.hasPrefix(metaSeparator) {
            let parts = quoteRaw.dropFirst().components(separatedBy: metaSeparator)
            if parts.count >= 2 {
                let ids = parts[0].components(separatedBy: "|")
                messageID = ids.first.flatMap(UUID.init(uuidString:))
                senderID = ids.count > 1 ? UUID(uuidString: ids[1]) : nil
                if ids.count > 2, let decoded = ids[2].removingPercentEncoding, !decoded.isEmpty {
                    imageURL = URL(string: decoded)
                }
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
            ChatReplyQuote(
                messageID: messageID,
                senderID: senderID,
                senderName: name,
                preview: preview,
                imageURL: imageURL
            ),
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
                Text(ChatReplyQuoteFormatter.preview(of: target.displayBody))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            if let imageURL = target.imageURL {
                ChatReplyQuoteImageThumb(url: imageURL, size: 38)
            }

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

/// バブル内に出す引用ブロック（LINE風）：返信元アイコン・太字名前・薄字プレビュー・
/// 画像リプライなら右に小さなサムネイル。下に区切り線を挟んで本文が続く。
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
            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 8) {
                    BoardThreadDetailAvatar(
                        avatarID: avatarID,
                        imageURL: avatarURL,
                        initial: String(quote.senderName.prefix(1)).uppercased(),
                        size: 26
                    )

                    VStack(alignment: .leading, spacing: 1) {
                        Text(quote.senderName)
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink)
                            .lineLimit(1)
                        Text(quote.imageURL != nil && quote.preview.isEmpty ? "写真" : quote.preview)
                            .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer(minLength: 6)

                    if let imageURL = quote.imageURL {
                        ChatReplyQuoteImageThumb(url: imageURL, size: 34)
                    }
                }

                Rectangle()
                    .fill(MegrumTheme.ink.opacity(0.12))
                    .frame(height: 0.8)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
        .padding(.bottom, 4)
        .accessibilityLabel("返信元: \(quote.senderName) \(quote.imageURL != nil && quote.preview.isEmpty ? "写真" : quote.preview)")
    }
}

/// 引用内の画像サムネイル。
struct ChatReplyQuoteImageThumb: View {
    var url: URL
    var size: CGFloat

    var body: some View {
        AsyncImage(url: url) { phase in
            if case .success(let image) = phase {
                image.resizable().scaledToFill()
            } else {
                MegrumTheme.lavender.opacity(0.14)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(.white.opacity(0.7), lineWidth: 1)
        }
        .accessibilityHidden(true)
    }
}

/// 自分のメッセージバブルの共通スタイル：紫→水色のほんのりグラデ。
enum MegrumChatBubbleStyle {
    static var mineBackground: AnyShapeStyle {
        AnyShapeStyle(
            LinearGradient(
                colors: [
                    MegrumTheme.lavender.opacity(0.36),
                    MegrumTheme.sky.opacity(0.34)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    static let mineText = MegrumTheme.ink
    static let otherBackground = AnyShapeStyle(Color.white.opacity(0.9))
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
