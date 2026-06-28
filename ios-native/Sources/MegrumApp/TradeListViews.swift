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
                if count > 0 {
                    TradeStageBadge(count: count, isSelected: selectedStage == stage)
                }
            }
            .font(.system(size: 16, weight: .heavy, design: .rounded))
            .foregroundStyle(selectedStage == stage ? MegrumTheme.ink : MegrumTheme.muted)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(selectedStage == stage ? AnyShapeStyle(.white.opacity(0.9)) : AnyShapeStyle(.clear), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel(for: stage, count: count))
        .accessibilityHint("やりとり一覧を\(stage.title)に切り替えます")
    }

    private func accessibilityLabel(for stage: TradeStage, count: Int) -> String {
        guard count > 0 else {
            return stage.title
        }
        return "\(stage.title) \(count)件"
    }
}

private struct TradeStageBadge: View {
    var count: Int
    var isSelected: Bool

    var body: some View {
        Text(displayText)
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, displayText.count >= 3 ? 6 : 7)
            .frame(minWidth: 22, minHeight: 22)
            .background(badgeFill, in: Capsule())
            .accessibilityHidden(true)
    }

    private var displayText: String {
        count > 99 ? "99+" : "\(count)"
    }

    private var badgeFill: some ShapeStyle {
        isSelected ? MegrumTheme.lavender : MegrumTheme.sky
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
