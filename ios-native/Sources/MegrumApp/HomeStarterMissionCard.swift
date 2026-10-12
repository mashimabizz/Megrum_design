import MegrumDesign
import SwiftUI

/// ホーム最上部に常駐する「最初の3ステップ」ミッションカード。
/// マイグッズ登録・ほしいもの登録・個別募集作成の達成状況をチェックで示す。
struct HomeStarterMissionCard: View {
    let state: HomeStarterMissionState
    var onOpenInventory: () -> Void
    var onOpenWish: () -> Void
    var onOpenListings: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("最初の3ステップ")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Spacer()
                Text("\(3 - state.remainingCount)/3")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                Button {
                    MegrumHaptics.performButtonTap(onDismiss)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(MegrumTheme.muted)
                        .padding(6)
                }
                .buttonStyle(.plain)
            }

            row(
                done: state.inventoryDone,
                title: "持っているグッズを登録",
                action: onOpenInventory
            )
            row(
                done: state.wishDone,
                title: "ほしいものを登録",
                action: onOpenWish
            )
            row(
                done: state.listingDone,
                title: "個別募集を作る",
                action: onOpenListings
            )
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(MegrumTheme.lavender.opacity(0.28), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
    }

    @ViewBuilder
    private func row(done: Bool, title: String, action: @escaping () -> Void) -> some View {
        Button {
            MegrumHaptics.performButtonTap(action)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: done ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(done ? MegrumTheme.ok : MegrumTheme.lavender.opacity(0.5))

                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(done ? MegrumTheme.muted : MegrumTheme.ink)
                    .strikethrough(done, color: MegrumTheme.muted)

                Spacer()

                if !done {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(MegrumTheme.muted)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(done)
    }
}
