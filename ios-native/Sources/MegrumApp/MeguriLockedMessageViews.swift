import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct MeguriLockedMessagePreview: View {
    var text: String = "メッセージが届いています"

    var body: some View {
        MeguriMessageBlurredText(
            text: text,
            font: .system(size: 13, weight: .bold, design: .rounded),
            lineLimit: 1,
            width: 124,
            expandsShortText: false,
            reservesLineSpace: false
        )
        .frame(height: 20, alignment: .leading)
        .accessibilityHidden(true)
    }
}

struct MeguriLockedMessageBubbleContent: View {
    var text: String
    var onOpenPremium: () -> Void

    var body: some View {
        ZStack {
            MeguriMessageBlurredText(
                text: text,
                font: .system(size: 15, weight: .bold, design: .rounded),
                lineLimit: 3,
                width: 232,
                expandsShortText: true,
                reservesLineSpace: true
            )
            .frame(minHeight: 76, alignment: .topLeading)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            Button(action: onOpenPremium) {
                Label("メッセージを見る", systemImage: "lock.open.fill")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .frame(height: 34)
                    .background(MegrumTheme.lavender, in: Capsule())
                    .shadow(color: MegrumTheme.lavender.opacity(0.22), radius: 10, y: 4)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("メッセージを見る")
        }
        .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(MegrumTheme.lavender.opacity(0.18), lineWidth: 1)
        }
        .shadow(color: MegrumTheme.ink.opacity(0.06), radius: 8, y: 3)
    }
}

struct MeguriMessageBlurredText: View {
    var text: String
    var font: Font
    var lineLimit: Int?
    var width: CGFloat
    var expandsShortText: Bool = false
    var reservesLineSpace: Bool = false

    var body: some View {
        blurredText
            .font(font)
            .foregroundStyle(MegrumTheme.ink)
            .multilineTextAlignment(.leading)
            .blur(radius: lineLimit == 1 ? 3.7 : 5.0)
            .opacity(0.68)
            .frame(width: width, alignment: .leading)
            .privacySensitive()
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var blurredText: some View {
        let displayText = expandsShortText
            ? MeguriLockedMessageTextPresentation.expandedText(text)
            : text
        if let lineLimit {
            Text(displayText)
                .lineLimit(lineLimit, reservesSpace: reservesLineSpace)
        } else {
            Text(displayText)
        }
    }
}

enum MeguriLockedMessageTextPresentation {
    static func expandedText(_ text: String, minimumCharacterCount: Int = 54) -> String {
        let baseText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let visibleText = baseText.isEmpty ? "メッセージが届いています" : baseText
        guard visibleText.count < minimumCharacterCount else {
            return visibleText
        }

        var expanded = visibleText
        while expanded.count < minimumCharacterCount {
            expanded += " " + visibleText
        }
        return expanded
    }
}
