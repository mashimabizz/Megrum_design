import MegrumDesign
import SwiftUI

struct ProposalMeetupPlaceSaveButton: View {
    var canSave: Bool
    var onSave: () -> Void

    var body: some View {
        Button(action: onSave) {
            Text("この場所にする")
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: ProposalFlowBottomBarMetrics.buttonMinHeight)
                .background(
                    MegrumTheme.lavender,
                    in: RoundedRectangle(cornerRadius: ProposalFlowBottomBarMetrics.buttonCornerRadius, style: .continuous)
                )
                .shadow(color: MegrumTheme.lavender.opacity(canSave ? 0.28 : 0), radius: 14, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(!canSave)
        .opacity(canSave ? 1 : 0.48)
        .padding(.horizontal, ProposalFlowBottomBarMetrics.horizontalPadding)
        .padding(.top, ProposalFlowBottomBarMetrics.topPadding)
        .padding(.bottom, ProposalFlowBottomBarMetrics.bottomPadding)
        .background(MegrumTheme.canvas.ignoresSafeArea(edges: .bottom))
    }
}
