import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct TradeMessageBubble: View {
    var message: TradeMessage
    var isMine: Bool
    var cancelApprovalPrompt: TradeCancelApprovalPrompt?
    var isApprovingCancel: Bool = false
    var onOpenImage: (URL) -> Void
    var onOpenDispute: (TradeDisputeSummary) -> Void = { _ in }
    var onApproveCancel: () -> Void = {}

    private var bodyText: String? {
        message.body?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }

    var body: some View {
        if message.messageType == .system {
            systemMessage
        } else {
            userMessage
        }
    }

    private var userMessage: some View {
        VStack(alignment: isMine ? .trailing : .leading, spacing: 4) {
            if let photoURL = message.photoURL {
                photoMessage(photoURL)
            }

            switch message.messageType {
            case .location:
                let presentation = TradeOperationalMessagePresentation(message: message)
                locationPreviewBubble(presentation: presentation)
            case .arrivalStatus:
                let presentation = TradeOperationalMessagePresentation(message: message)
                richTextBubble(
                    title: presentation.title,
                    systemImage: presentation.systemImage,
                    body: presentation.body,
                    detail: presentation.detail
                )
            case .text, .photo, .outfitPhoto:
                if let bodyText {
                    textBubble(bodyText)
                }
            case .system:
                EmptyView()
            }

            Text(message.createdAt.formatted(date: .omitted, time: .shortened))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: isMine ? .trailing : .leading)
    }

    @ViewBuilder
    private var systemMessage: some View {
        let presentation = TradeSystemMessagePresentation(message: message)
        if let disputeSummary = TradeDisputeSummary(message: message) {
            Button {
                onOpenDispute(disputeSummary)
            } label: {
                systemMessageContent(presentation: presentation, showsDisclosure: true)
            }
            .buttonStyle(.plain)
        } else {
            VStack(spacing: 8) {
                systemMessageContent(presentation: presentation, showsDisclosure: false)
                if cancelApprovalPrompt?.canApprove == true {
                    Button(action: onApproveCancel) {
                        HStack(spacing: 8) {
                            if isApprovingCancel {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            Text("キャンセルに同意する")
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(MegrumTheme.lavender, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(isApprovingCancel)
                    .accessibilityLabel("キャンセル申請に同意する")
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private func systemMessageContent(presentation: TradeSystemMessagePresentation, showsDisclosure: Bool) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: presentation.systemImage)
                .font(.system(size: 13, weight: .bold))
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 3) {
                Text(presentation.title)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                Text(presentation.body)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .fixedSize(horizontal: false, vertical: true)
                if let detail = presentation.detail {
                    Text(detail)
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                }
            }
            if showsDisclosure {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .heavy))
                    .padding(.top, 2)
            }
        }
        .foregroundStyle(MegrumTheme.muted)
        .padding(.horizontal, 13)
        .padding(.vertical, 9)
        .frame(maxWidth: 320, alignment: .leading)
        .background(.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .frame(maxWidth: .infinity, alignment: .center)
        .accessibilityLabel(presentation.accessibilityLabel)
    }

    private func photoMessage(_ photoURL: URL) -> some View {
        Button {
            onOpenImage(photoURL)
        } label: {
            AsyncImage(url: photoURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    MegrumTheme.sky.opacity(0.18)
                        .overlay {
                            Image(systemName: "photo")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(MegrumTheme.muted)
                        }
                case .empty:
                    MegrumTheme.sky.opacity(0.12)
                        .overlay {
                            ProgressView()
                        }
                @unknown default:
                    Color.clear
                }
            }
            .frame(width: 210, height: message.messageType == .outfitPhoto ? 280 : 250)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(alignment: .topLeading) {
                if let label = photoLabel {
                    Label(label, systemImage: "photo.fill")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.46), in: Capsule())
                        .padding(9)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(photoLabel ?? "取引チャットの写真")を拡大表示")
    }

    private func textBubble(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(isMine ? .white : MegrumTheme.ink)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: 300, alignment: isMine ? .trailing : .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                isMine ? AnyShapeStyle(MegrumTheme.lavender) : AnyShapeStyle(.white.opacity(0.9)),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
    }

    private func richTextBubble(title: String, systemImage: String, body: String, detail: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(isMine ? .white.opacity(0.86) : MegrumTheme.lavender)
            Text(body)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .fixedSize(horizontal: false, vertical: true)
            if let detail {
                Text(detail)
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(isMine ? .white.opacity(0.78) : MegrumTheme.muted)
            }
        }
        .foregroundStyle(isMine ? .white : MegrumTheme.ink)
        .frame(maxWidth: 300, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            isMine ? AnyShapeStyle(MegrumTheme.lavender) : AnyShapeStyle(.white.opacity(0.9)),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
    }

    private func locationPreviewBubble(presentation: TradeOperationalMessagePresentation) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.82, green: 0.91, blue: 0.82),
                        Color(red: 0.8, green: 0.88, blue: 0.96)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                mapGrid

                Circle()
                    .fill(MegrumTheme.lavender)
                    .frame(width: 34, height: 34)
                    .overlay {
                        Text("!")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .shadow(color: MegrumTheme.lavender.opacity(0.32), radius: 8, y: 3)
            }
            .frame(height: 132)

            VStack(alignment: .leading, spacing: 5) {
                Label(presentation.title, systemImage: presentation.systemImage)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                Text(presentation.body)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
                Text("地図アプリで開く →")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.white.opacity(0.94))
        }
        .frame(width: 262)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.white.opacity(0.86), lineWidth: 1)
        }
        .shadow(color: MegrumTheme.ink.opacity(0.05), radius: 10, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(presentation.title)。\(presentation.body)")
    }

    private var mapGrid: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { index in
                Capsule()
                    .fill(.white.opacity(0.56))
                    .frame(width: 230, height: 5)
                    .rotationEffect(.degrees(index.isMultiple(of: 2) ? -14 : 16))
                    .offset(y: CGFloat(index - 2) * 22)
            }
            ForEach(0..<4, id: \.self) { index in
                Capsule()
                    .fill(MegrumTheme.sky.opacity(0.36))
                    .frame(width: 5, height: 150)
                    .rotationEffect(.degrees(index.isMultiple(of: 2) ? 32 : -28))
                    .offset(x: CGFloat(index - 1) * 44)
            }
        }
    }

    private var photoLabel: String? {
        switch message.messageType {
        case .photo:
            "写真"
        case .outfitPhoto:
            "服装写真"
        default:
            nil
        }
    }
}
