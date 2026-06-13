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
    private static let actionColor = Color(red: 0.84, green: 0.46, blue: 0.36)
    private static let calmColor = Color(red: 0.23, green: 0.49, blue: 0.58)

    var proposal: TradeProposal
    var viewerID: UUID?
    var profilesByUserID: [UUID: PublicUserProfile] = [:]
    var goodsByID: [UUID: GoodsItem] = [:]
    var onOpen: () -> Void

    private var presentation: TradeCardPresentation {
        TradeCardPresentation(
            proposal: proposal,
            viewerID: viewerID,
            profilesByUserID: profilesByUserID
        )
    }

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: 13) {
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(MegrumTheme.lavender.opacity(0.16))
                        .frame(width: 42, height: 42)
                        .overlay {
                            Text(presentation.partnerInitial)
                                .font(.system(size: 17, weight: .black, design: .rounded))
                                .foregroundStyle(MegrumTheme.lavender)
                        }

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 8) {
                            Text("@\(presentation.partnerHandle)")
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundStyle(MegrumTheme.ink)
                                .lineLimit(1)

                            Text(presentation.directionText)
                                .font(.system(size: 9.5, weight: .black, design: .rounded))
                                .foregroundStyle(directionForegroundColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(directionBackgroundColor, in: Capsule())
                        }
                    }

                    Spacer(minLength: 8)

                    Label("詳細", systemImage: "chevron.right")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .labelStyle(.titleAndIcon)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(statusColor.opacity(0.11), in: Capsule())
                        .foregroundStyle(statusColor)
                }

                HStack(spacing: 8) {
                    Text(presentation.statusText)
                        .font(.system(size: 10.5, weight: .black, design: .rounded))
                        .foregroundStyle(statusColor)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(statusColor.opacity(0.12), in: Capsule())

                    if let responseText = presentation.responseText {
                        Text(responseText)
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(responseColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(responseColor.opacity(0.10), in: Capsule())
                    }

                    Spacer(minLength: 0)
                }

                TradeDealGoodsPanel(
                    offeredItems: previewItems(for: offeredGoodsIDs),
                    requestedItems: previewItems(for: requestedGoodsIDs)
                )

                HStack(alignment: .top, spacing: 9) {
                    Image(systemName: "mappin.circle")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(MegrumTheme.lavender)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(presentation.meetupSummaryText)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink)
                            .lineLimit(2)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(alignment: .leading) {
                if presentation.needsAction {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(Self.actionColor)
                        .frame(width: 3)
                        .padding(.vertical, 18)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(cardBorderColor, lineWidth: presentation.needsAction ? 1.4 : 1)
            }
            .shadow(color: MegrumTheme.ink.opacity(0.07), radius: 18, y: 10)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("取引詳細をページで開きます")
    }

    private var statusColor: Color {
        switch presentation.tone {
        case .action:
            Self.actionColor
        case .live:
            Self.calmColor
        case .idle:
            MegrumTheme.ink
        }
    }

    private var cardBorderColor: Color {
        presentation.needsAction ? Self.actionColor.opacity(0.24) : MegrumTheme.ink.opacity(0.08)
    }

    private var directionForegroundColor: Color {
        presentation.isReceived ? MegrumTheme.lavender : Self.calmColor
    }

    private var directionBackgroundColor: Color {
        if presentation.isReceived {
            return MegrumTheme.lavender.opacity(0.14)
        }
        return MegrumTheme.sky.opacity(0.22)
    }

    private var responseColor: Color {
        presentation.needsAction ? Self.actionColor : Self.calmColor
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
        var parts = [
            "取引",
            presentation.statusText,
            proposal.exchangeMethod.displayName,
            "ゆずるグッズ \(offeredGoodsIDs.count)件",
            "求めるグッズ \(requestedGoodsIDs.count)件"
        ]
        if !proposal.conditionTags.isEmpty {
            parts.append("条件 \(proposal.conditionTags.joined(separator: "、"))")
        }
        return parts.joined(separator: "、")
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
