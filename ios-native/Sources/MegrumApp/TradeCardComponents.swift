import MegrumDesign
import SwiftUI

struct TradeCardExclusivePressModifier: ViewModifier {
    var onTap: () -> Void
    var onLongPress: (() -> Void)?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let onLongPress {
            content.gesture(
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
                        onTap()
                    case .first(false):
                        break
                    }
                }
            )
        } else {
            content.onTapGesture(perform: onTap)
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
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                TradeReadStateLabel(readState: presentation.readState)

                HStack(spacing: 7) {
                    TradePartnerAvatar(initial: presentation.partnerInitial, readState: presentation.readState)

                    Text("@\(presentation.partnerHandle)")
                        .font(.system(size: 12.5, weight: presentation.readState.handleWeight, design: .rounded))
                        .foregroundStyle(presentation.readState.handleColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    Text("・\(presentation.updatedText)")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted.opacity(0.76))
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 10)

            TradeDetailLink(readState: presentation.readState)
        }
    }
}

struct TradeReadStateLabel: View {
    var readState: TradeCardReadState

    var body: some View {
        Text(readState.title)
            .font(.system(size: 13, weight: readState.stateWeight, design: .rounded))
            .foregroundStyle(readState.stateColor)
            .lineLimit(1)
            .padding(.horizontal, readState.showsStateBackground ? 8 : 0)
            .padding(.vertical, readState.showsStateBackground ? 4 : 0)
            .background {
                if readState.showsStateBackground {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(readState.stateBackgroundColor)
                }
            }
            .overlay {
                if readState.showsStateBackground {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(readState.stateBorderColor, lineWidth: 0.8)
                }
            }
    }
}

struct TradePartnerAvatar: View {
    var initial: String
    var readState: TradeCardReadState

    var body: some View {
        RoundedRectangle(cornerRadius: 9, style: .continuous)
            .fill(MegrumTheme.lavender.opacity(readState == .unopened ? 0.14 : 0.09))
            .frame(width: 22, height: 22)
            .overlay {
                Text(initial)
                    .font(.system(size: 10.5, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender.opacity(readState == .waitingForReply ? 0.62 : 0.92))
            }
            .accessibilityHidden(true)
    }
}

struct TradeDetailLink: View {
    var readState: TradeCardReadState

    var body: some View {
        HStack(spacing: 4) {
            Text("詳細")
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .bold))
        }
        .font(.system(size: 12, weight: readState == .unopened ? .bold : .semibold, design: .rounded))
        .foregroundStyle(MegrumTheme.ink.opacity(readState == .waitingForReply ? 0.50 : 0.68))
        .padding(.top, 1)
    }
}

struct TradeMeetupSummaryLine: View {
    var text: String
    var readState: TradeCardReadState

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "mappin.circle")
                .font(.system(size: 15.5, weight: .bold))
                .foregroundStyle(MegrumTheme.muted.opacity(readState == .waitingForReply ? 0.54 : 0.78))

            Text(text)
                .font(.system(size: 12, weight: readState == .unopened ? .bold : .semibold, design: .rounded))
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
