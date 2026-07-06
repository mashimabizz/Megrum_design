import Foundation
import MegrumDesign
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// リプライ対象（取引チャット・めぐりメッセージ・チャットルーム共通）。
struct ChatReplyTarget: Equatable {
    var senderID: UUID?
    var senderName: String
    var avatarID: String?
    var avatarURL: URL?
    var initial: String
    var body: String
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

    static func compose(reply: ChatReplyTarget, body: String) -> String {
        "\(marker)\(reply.senderName)「\(preview(of: reply.body))」\n\(body)"
    }

    /// 本文から引用行を分離する。引用が無ければ quote は nil。
    static func parse(_ body: String) -> (quote: String?, text: String) {
        guard body.hasPrefix(marker),
              let newlineIndex = body.firstIndex(of: "\n")
        else {
            return (nil, body)
        }
        let quote = String(body[body.index(body.startIndex, offsetBy: marker.count)..<newlineIndex])
        let text = String(body[body.index(after: newlineIndex)...])
        return (quote, text)
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

/// バブル内に出す引用表示（リプライ先の名前＋元メッセージ）。
struct ChatReplyQuoteLine: View {
    var quote: String
    var isMine: Bool

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(isMine ? Color.white.opacity(0.7) : MegrumTheme.lavender)
                .frame(width: 3)
            Text(quote)
                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                .foregroundStyle(isMine ? Color.white.opacity(0.82) : MegrumTheme.muted)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .padding(.bottom, 3)
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
                        let horizontal = value.translation.width
                        let vertical = abs(value.translation.height)
                        // 右方向へはっきりスワイプした時だけリプライを開始する。
                        if horizontal > 56, horizontal > vertical * 1.4 {
                            MegrumHaptics.buttonTap()
                            onReply()
                        }
                    }
            )
    }
}
