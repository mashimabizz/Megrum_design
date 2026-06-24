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
