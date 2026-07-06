import MegrumCore
import MegrumDesign
import SwiftUI

struct TradeUserMessageStack: View {
    var message: TradeMessage
    var isMine: Bool
    var isReadByPartner: Bool
    var onOpenImage: (URL) -> Void

    private var bodyText: String? {
        message.body.nilIfBlank
    }

    var body: some View {
        VStack(alignment: isMine ? .trailing : .leading, spacing: 4) {
            switch message.messageType {
            case .location:
                messageRow {
                    TradeLocationPreviewBubble(presentation: TradeOperationalMessagePresentation(message: message))
                }
            case .arrivalStatus:
                let presentation = TradeOperationalMessagePresentation(message: message)
                messageRow {
                    TradeRichOperationalMessageBubble(
                        title: presentation.title,
                        systemImage: presentation.systemImage,
                        messageBody: presentation.body,
                        detail: presentation.detail,
                        isMine: isMine
                    )
                }
            case .text, .photo, .outfitPhoto:
                if TradePhotoMessageLayout.isPhotoMessage(message.messageType), bodyText == nil {
                    messageRow {
                        photoBubble
                    }
                } else if TradePhotoMessageLayout.isPhotoMessage(message.messageType) {
                    photoBubble
                    if let bodyText {
                        messageRow {
                            TradeTextMessageBubble(
                                text: bodyText,
                                isMine: isMine
                            )
                        }
                    }
                } else if let bodyText {
                    messageRow {
                        TradeTextMessageBubble(
                            text: bodyText,
                            isMine: isMine
                        )
                    }
                }
            case .system:
                EmptyView()
            }
        }
    }

    private func messageRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .bottom, spacing: 6) {
            if isMine {
                inlineMeta
            }
            content()
            if !isMine {
                inlineMeta
            }
        }
    }

    private var photoBubble: some View {
        TradePhotoMessageBubble(message: message, photoURL: message.photoURL, onOpenImage: onOpenImage)
    }

    private var inlineMeta: some View {
        TradeMessageMeta(
            message: message,
            isMine: isMine,
            isReadByPartner: isReadByPartner
        )
        .padding(.bottom, 3)
    }
}

struct TradeMessageMeta: View {
    var message: TradeMessage
    var isMine: Bool
    var isReadByPartner: Bool
    var alignsLeading: Bool = false
    var foregroundColor: Color = MegrumTheme.muted.opacity(0.82)

    var body: some View {
        VStack(alignment: metaAlignment, spacing: 1) {
            if isMine, isReadByPartner {
                Text("既読")
            }
            Text(ChatTimestampFormatter.timeText(for: message.createdAt))
        }
        .font(.system(size: 10.5, weight: .bold, design: .rounded))
        .foregroundStyle(foregroundColor)
        .padding(.bottom, 2)
    }

    private var metaAlignment: HorizontalAlignment {
        if alignsLeading {
            return .leading
        }
        return isMine ? .trailing : .leading
    }
}
