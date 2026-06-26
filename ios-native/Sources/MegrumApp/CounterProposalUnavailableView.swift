import MegrumDesign
import SwiftUI

struct CounterProposalUnavailableView: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32, weight: .black))
                .foregroundStyle(MegrumTheme.lavender)

            Text("再打診に必要なグッズを読み込めませんでした")
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .multilineTextAlignment(.center)

            Text("少し時間をおいてから、もう一度お試しください。")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .navigationTitle("条件を変えて再打診")
        .megrumInlineNavigationTitle()
    }
}
