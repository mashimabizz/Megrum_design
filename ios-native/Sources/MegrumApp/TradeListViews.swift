import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct TradeDetailUnavailableScreen: View {
    var body: some View {
        ContentUnavailableView {
            Label("取引が見つかりません", systemImage: "tray")
        } description: {
            Text("一覧を更新して、もう一度やりとりを開いてください。")
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .navigationTitle("取引詳細")
        .megrumInlineNavigationTitle()
    }
}

struct TradeCard: View {
    var proposal: TradeProposal
    var viewerID: UUID?
    var profilesByUserID: [UUID: PublicUserProfile] = [:]
    var goodsByID: [UUID: GoodsItem] = [:]
    var lastActivityAt: Date?
    var viewerLastReadAt: Date?
    var isSelectionMode = false
    var isSelected = false
    var isSelectionEnabled = false
    var onLongPress: () -> Void = {}
    var onOpen: () -> Void

    private var presentation: TradeCardPresentation {
        TradeCardPresentation(
            proposal: proposal,
            viewerID: viewerID,
            profilesByUserID: profilesByUserID,
            lastActivityAt: lastActivityAt,
            viewerLastReadAt: viewerLastReadAt
        )
    }

    var body: some View {
        cardContent
            .contentShape(Rectangle())
            .modifier(TradeCardExclusivePressModifier(
                onTap: onOpen,
                onLongPress: isSelectionEnabled ? onLongPress : nil
            ))
            .accessibilityAddTraits(.isButton)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(isSelectionMode ? "選択状態を切り替えます" : "取引詳細をページで開きます")
    }

    private var cardContent: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                TradeCardHeader(presentation: presentation)

                TradeDealGoodsPanel(
                    offeredItems: previewItems(for: offeredGoodsIDs),
                    requestedItems: previewItems(for: requestedGoodsIDs)
                )

                TradeMeetupSummaryLine(
                    text: presentation.meetupSummaryText,
                    readState: presentation.readState
                )
            }
            .padding(.vertical, 17)

            TradeCardDivider(readState: presentation.readState)
        }
        .overlay(alignment: .topTrailing) {
            if isSelectionMode {
                TradeSelectionIndicator(
                    isSelected: isSelected,
                    isEnabled: isSelectionEnabled
                )
                .padding(.top, 15)
                .padding(.trailing, 4)
            }
        }
        .background {
            if presentation.readState == .unopened {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                MegrumTheme.lavender.opacity(0.21),
                                MegrumTheme.pink.opacity(0.13)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
        .opacity(isSelectionMode && !isSelectionEnabled ? 0.48 : 1)
    }

    private func previewItems(for ids: [UUID]) -> [GoodsItem] {
        ids.compactMap { goodsByID[$0] }
    }

    private var offeredGoodsIDs: [UUID] {
        viewerID.flatMap { proposal.goodsOffered(by: $0) } ?? proposal.senderGoodsIDs
    }

    private var requestedGoodsIDs: [UUID] {
        viewerID.flatMap { proposal.goodsRequested(by: $0) } ?? proposal.receiverGoodsIDs
    }

    private var accessibilityLabel: String {
        let parts = [
            "取引",
            presentation.readState.title,
            proposal.exchangeMethod.displayName,
            "ゆずるグッズ \(offeredGoodsIDs.count)件",
            "求めるグッズ \(requestedGoodsIDs.count)件"
        ]
        return parts.joined(separator: "、")
    }
}

private struct TradeCardExclusivePressModifier: ViewModifier {
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

private struct TradeSelectionIndicator: View {
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

private struct TradeCardHeader: View {
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

private struct TradeReadStateLabel: View {
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

private struct TradePartnerAvatar: View {
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

private struct TradeDetailLink: View {
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

private struct TradeMeetupSummaryLine: View {
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

private struct TradeCardDivider: View {
    var readState: TradeCardReadState

    var body: some View {
        Rectangle()
            .fill(MegrumTheme.ink.opacity(readState == .unopened ? 0.10 : 0.065))
            .frame(height: 0.5)
            .padding(.leading, 2)
    }
}

private extension TradeCardReadState {
    var showsStateBackground: Bool {
        switch self {
        case .unopened, .opened:
            true
        case .waitingForReply:
            false
        }
    }

    var stateBackgroundColor: Color {
        switch self {
        case .unopened:
            MegrumTheme.ink.opacity(0.09)
        case .opened:
            MegrumTheme.ink.opacity(0.055)
        case .waitingForReply:
            .clear
        }
    }

    var stateBorderColor: Color {
        switch self {
        case .unopened:
            MegrumTheme.ink.opacity(0.14)
        case .opened:
            MegrumTheme.ink.opacity(0.10)
        case .waitingForReply:
            .clear
        }
    }

    var stateColor: Color {
        switch self {
        case .unopened:
            MegrumTheme.ink
        case .opened:
            MegrumTheme.ink.opacity(0.72)
        case .waitingForReply:
            MegrumTheme.muted.opacity(0.70)
        }
    }

    var handleColor: Color {
        switch self {
        case .unopened:
            MegrumTheme.ink
        case .opened:
            MegrumTheme.ink.opacity(0.78)
        case .waitingForReply:
            MegrumTheme.muted.opacity(0.78)
        }
    }

    var stateWeight: Font.Weight {
        switch self {
        case .unopened:
            .black
        case .opened:
            .bold
        case .waitingForReply:
            .semibold
        }
    }

    var handleWeight: Font.Weight {
        switch self {
        case .unopened:
            .bold
        case .opened:
            .semibold
        case .waitingForReply:
            .semibold
        }
    }
}

struct TradeStageBar: View {
    @Binding var selectedStage: TradeStage
    var pendingCount: Int
    var inProgressCount: Int
    var completedCount: Int

    var body: some View {
        HStack(spacing: 8) {
            stageButton(.pending, count: pendingCount)
            stageButton(.inProgress, count: inProgressCount)
            stageButton(.completed, count: completedCount)
        }
        .padding(7)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.72), lineWidth: 1))
        .shadow(color: MegrumTheme.ink.opacity(0.12), radius: 18, y: 10)
    }

    private func stageButton(_ stage: TradeStage, count: Int) -> some View {
        Button {
            selectedStage = stage
        } label: {
            HStack(spacing: 7) {
                Text(stage.title)
                Text("\(count)")
                    .foregroundStyle(selectedStage == stage ? MegrumTheme.lavender : MegrumTheme.sky)
            }
            .font(.system(size: 16, weight: .heavy, design: .rounded))
            .foregroundStyle(selectedStage == stage ? MegrumTheme.ink : MegrumTheme.muted)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(selectedStage == stage ? AnyShapeStyle(.white.opacity(0.9)) : AnyShapeStyle(.clear), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(stage.title) \(count)件")
        .accessibilityHint("やりとり一覧を\(stage.title)に切り替えます")
    }
}

struct EmptyTradeStage: View {
    var stage: TradeStage

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(MegrumTheme.lavender)

            Text(stage.emptyTitle)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Text(stage.emptyMessage)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 18)
        .padding(.vertical, 30)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.62), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(stage.emptyTitle)。\(stage.emptyMessage)")
    }
}
