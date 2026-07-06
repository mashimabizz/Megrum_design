import MegrumDesign
import SwiftUI

struct TradeCardExclusivePressModifier: ViewModifier {
    var onTap: () -> Void
    var onLongPress: (() -> Void)?

    /// 押下中はパネル背景を暗くして「押した」ことを視覚的に返す。
    /// GestureState なので指を離す・スクロールに移った時点で自動的に解除される。
    @GestureState private var isPressed = false

    @ViewBuilder
    func body(content: Content) -> some View {
        let highlighted = content
            .overlay {
                Color.black.opacity(isPressed ? 0.12 : 0)
                    .allowsHitTesting(false)
            }
            .animation(.easeOut(duration: isPressed ? 0.08 : 0.24), value: isPressed)
            .simultaneousGesture(pressHighlightGesture)

        if let onLongPress {
            highlighted.gesture(
                ExclusiveGesture(
                    LongPressGesture(minimumDuration: 0.45, maximumDistance: 18),
                    TapGesture()
                )
                .onEnded { value in
                    switch value {
                    case .first(true):
                        MegrumHaptics.longPress()
                        onLongPress()
                    case .second:
                        MegrumHaptics.buttonTap()
                        onTap()
                    case .first(false):
                        break
                    }
                }
            )
        } else {
            highlighted.onTapGesture {
                MegrumHaptics.buttonTap()
                onTap()
            }
        }
    }

    /// 押下ハイライト専用（タップ／長押しの判定には関与しない）。
    /// 指が大きく動いた（＝スクロール）時はハイライトを消す。
    private var pressHighlightGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($isPressed) { value, state, _ in
                let moved = abs(value.translation.width) > 12 || abs(value.translation.height) > 12
                state = !moved
            }
    }
}

struct TradeSelectionIndicator: View {
    var isSelected: Bool
    var isEnabled: Bool

    var body: some View {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .font(.system(size: 24, weight: .heavy))
            .foregroundStyle(isSelected ? MegrumTheme.lavender : MegrumTheme.muted.opacity(isEnabled ? 0.62 : 0.32))
            .background(.white.opacity(0.88), in: Circle())
            .accessibilityHidden(true)
    }
}

struct TradeCardHeader: View {
    var presentation: TradeCardPresentation

    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            TradePartnerAvatar(
                initial: presentation.partnerInitial,
                avatarURL: presentation.partnerAvatarURL,
                readState: presentation.readState
            )

            Text("@\(presentation.partnerHandle)")
                .font(.system(size: 12.5, weight: presentation.readState.handleWeight, design: .rounded))
                .foregroundStyle(presentation.readState.handleColor)
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            if let demographicText = presentation.partnerDemographicText {
                TradePartnerMetaText(demographicText)
            }

            if let ratingText = presentation.partnerRatingText {
                TradePartnerMetaText(ratingText)
            }

            Spacer(minLength: 6)

            HStack(spacing: 5) {
                Text(presentation.updatedText)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted.opacity(0.76))
                    .lineLimit(1)

                if presentation.unreadBadgeCount > 0 {
                    TradeUnreadBadge(count: presentation.unreadBadgeCount)
                }
            }
            .fixedSize(horizontal: true, vertical: false)
        }
    }
}

private struct TradeUnreadBadge: View {
    var count: Int

    private var displayText: String {
        count > 99 ? "99+" : "\(count)"
    }

    var body: some View {
        Text(displayText)
            .font(.system(size: 10, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .monospacedDigit()
            .lineLimit(1)
            .padding(.horizontal, count > 9 ? 6 : 0)
            .frame(minWidth: 18, minHeight: 18)
            .background {
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                MegrumTheme.pink.opacity(0.98),
                                MegrumTheme.lavender.opacity(0.94)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        Capsule(style: .continuous)
                            .strokeBorder(.white.opacity(0.72), lineWidth: 1)
                    }
            }
            .shadow(color: MegrumTheme.pink.opacity(0.34), radius: 7, y: 2)
            .accessibilityLabel("未読\(count)件")
    }
}

struct TradePartnerAvatar: View {
    var initial: String
    var avatarURL: URL? = nil
    var readState: TradeCardReadState

    var body: some View {
        Group {
            if let avatarURL {
                AsyncImage(url: avatarURL) { phase in
                    if case .success(let image) = phase {
                        image.resizable().scaledToFill()
                    } else {
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: 22, height: 22)
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .accessibilityHidden(true)
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 9, style: .continuous)
            .fill(MegrumTheme.lavender.opacity(readState == .unopened ? 0.14 : 0.09))
            .overlay {
                Text(initial)
                    .font(.system(size: 10.5, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender.opacity(readState == .waitingForReply ? 0.62 : 0.92))
            }
    }
}

struct TradePartnerMetaText: View {
    var text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: 10.5, weight: .bold, design: .rounded))
            .foregroundStyle(MegrumTheme.muted.opacity(0.82))
            .lineLimit(1)
            .minimumScaleFactor(0.78)
    }
}

struct TradeMeetupSummaryLine: View {
    var text: String
    var systemImage: String = "mappin.circle"
    var readState: TradeCardReadState

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(MegrumTheme.muted.opacity(readState == .waitingForReply ? 0.54 : 0.78))

            Text(text)
                .font(.system(size: 11.5, weight: readState == .unopened ? .bold : .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink.opacity(readState == .waitingForReply ? 0.62 : 0.84))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct TradeCardDivider: View {
    var readState: TradeCardReadState

    var body: some View {
        Rectangle()
            .fill(MegrumTheme.ink.opacity(readState == .unopened ? 0.10 : 0.065))
            .frame(height: 0.5)
            .padding(.leading, 2)
    }
}
