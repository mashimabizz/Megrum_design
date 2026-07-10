import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct HomeExchangeSettingsContent: View {
    @Binding var draftPreference: HomeExchangePreference
    @Binding var draftLocalPrefecture: String
    @Binding var draftMailShippingFee: IndividualListingShippingFeeDraft
    @Binding var draftMailShippingDays: IndividualListingShippingDaysDraft
    @Binding var visibleMonth: Date
    var selectedDateKeys: Set<String>
    var dateDetails: [String: HomeExchangeLocalDateDetail]
    var onClose: () -> Void
    var onSelectPreference: (HomeExchangePreference) -> Void
    var onTapDay: (HomeExchangeCalendarDay) -> Void
    var onFinishDragSelection: ([HomeExchangeCalendarDay]) -> Void

    var body: some View {
        ZStack {
            HomeExchangeSettingsBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    HomeExchangeSettingsHeader(onClose: onClose)

                    HomeExchangePreferenceCardPicker(
                        selection: $draftPreference,
                        onSelect: onSelectPreference
                    )

                    mailConditionsSection
                    localConditionsSection
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 108)
            }
        }
    }

    @ViewBuilder
    private var mailConditionsSection: some View {
        if draftPreference.acceptsMail {
            HomeExchangeMailConditionsCard(
                shippingFee: $draftMailShippingFee,
                shippingDays: $draftMailShippingDays
            )
        }
    }

    @ViewBuilder
    private var localConditionsSection: some View {
        if draftPreference.acceptsLocal {
            Text("現地交換可能な場所と日程")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .padding(.horizontal, 2)

            HomeExchangeSettingsCalendarCard(
                visibleMonth: $visibleMonth,
                selectedPrefecture: $draftLocalPrefecture,
                selectedDateKeys: selectedDateKeys,
                dateDetails: dateDetails,
                onTapDay: onTapDay,
                onFinishDragSelection: onFinishDragSelection
            )

            HomeExchangeSettingsInstructionBanner()
        }
    }
}
