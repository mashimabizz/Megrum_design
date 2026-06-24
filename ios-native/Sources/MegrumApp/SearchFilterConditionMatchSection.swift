import MegrumDesign
import SwiftUI

struct SearchConditionMatchFilterSection: View {
    @Binding var filters: SearchConditionMatchFilters

    var body: some View {
        Section {
            SearchConditionMatchToggleRow(
                title: "Wishに合う",
                subtitle: "グッズ○",
                isOn: $filters.matchesWish
            )
            SearchConditionMatchToggleRow(
                title: SearchFilterPresentation.individualListingMatchTitle,
                subtitle: "グッズ◎",
                isOn: $filters.matchesIndividualListing
            )
            SearchConditionMatchToggleRow(
                title: "交換条件が合う",
                subtitle: "自分の交換条件と重なるもの",
                isOn: $filters.matchesExchangeCondition
            )
            SearchConditionMatchToggleRow(
                title: "支払条件が合う",
                subtitle: "自分の支払い条件と重なるもの",
                isOn: $filters.matchesPaymentCondition
            )
        } header: {
            Label("条件マッチ", systemImage: "heart")
        }
    }
}

private struct SearchConditionMatchToggleRow: View {
    var title: String
    var subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack {
                Text(title)
                Spacer(minLength: 12)
                Text(subtitle)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
        }
        .tint(MegrumTheme.lavender)
    }
}
