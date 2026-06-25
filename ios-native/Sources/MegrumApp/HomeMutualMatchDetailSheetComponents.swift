import MegrumCore
import MegrumDesign
import SwiftUI

struct HomeMutualMatchSelectedPreviewCard: View {
    var pair: HomeMutualMatchProposalPair
    var review: HomeMutualMatchConditionReview

    @State private var isShowingConditionHelp = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.left.arrow.right.circle.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(MegrumTheme.lavender)

                Text("何を交換するか")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
            }

            HStack(spacing: 10) {
                HomeMutualMatchPreviewSide(
                    title: "求めるグッズ",
                    item: pair.receiverDisplayItem,
                    tint: MegrumTheme.lavender
                )

                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(MegrumTheme.muted.opacity(0.64))

                HomeMutualMatchPreviewSide(
                    title: "譲るグッズ",
                    item: pair.senderDisplayItem,
                    tint: MegrumTheme.pink
                )
            }

            Divider().opacity(0.45)

            VStack(alignment: .leading, spacing: 9) {
                HStack(spacing: 6) {
                    Text("確認ポイント")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)

                    Button {
                        isShowingConditionHelp = true
                    } label: {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 15, weight: .black))
                            .foregroundStyle(MegrumTheme.lavender)
                            .frame(width: 26, height: 26)
                            .background(MegrumTheme.lavender.opacity(0.10), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("確認ポイントの説明を開く")
                    .popover(isPresented: $isShowingConditionHelp) {
                        HomeMutualMatchConditionHelpPopover()
                            .presentationCompactAdaptation(.popover)
                    }

                    Spacer(minLength: 0)
                }

                ForEach(HomeMutualMatchConditionReviewPointPolicy.points(for: pair, review: review)) { point in
                    HomeMutualMatchConditionReviewRow(point: point)
                }
            }
        }
        .padding(14)
        .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(MegrumTheme.lavender.opacity(0.20), lineWidth: 1)
        }
        .shadow(color: MegrumTheme.lavender.opacity(0.08), radius: 14, y: 8)
        .accessibilityElement(children: .contain)
    }
}
