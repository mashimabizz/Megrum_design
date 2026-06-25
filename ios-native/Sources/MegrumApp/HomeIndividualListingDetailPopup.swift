import MegrumCore
import MegrumDesign
import SwiftUI

struct HomeIndividualListingDetailPopup: View {
    var detail: HomeIndividualListingDetailContext
    var selectedWantedOptionID: UUID?
    var onSelectWantedOption: ((HomeIndividualListingWantedOption) -> Void)?

    init(
        detail: HomeIndividualListingDetailContext,
        selectedWantedOptionID: UUID? = nil,
        onSelectWantedOption: ((HomeIndividualListingWantedOption) -> Void)? = nil
    ) {
        self.detail = detail
        self.selectedWantedOptionID = selectedWantedOptionID
        self.onSelectWantedOption = onSelectWantedOption
    }

    var body: some View {
        HomeSheetScaffold(bottomButton: nil) {
            VStack(alignment: .leading, spacing: 14) {
                Text("個別募集の詳細")
                    .font(.system(size: 21, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)

                HomeIndividualListingCombinationPanels(
                    detail: detail,
                    selectedWantedOptionID: selectedWantedOptionID,
                    onSelectWantedOption: onSelectWantedOption
                )
            }
        }
    }
}

private struct HomeIndividualListingCombinationPanels: View {
    var detail: HomeIndividualListingDetailContext
    var selectedWantedOptionID: UUID?
    var onSelectWantedOption: ((HomeIndividualListingWantedOption) -> Void)?

    init(
        detail: HomeIndividualListingDetailContext,
        selectedWantedOptionID: UUID? = nil,
        onSelectWantedOption: ((HomeIndividualListingWantedOption) -> Void)? = nil
    ) {
        self.detail = detail
        self.selectedWantedOptionID = selectedWantedOptionID
        self.onSelectWantedOption = onSelectWantedOption
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            HomeIndividualListingWantedPanel(
                detail: detail,
                selectedWantedOptionID: selectedWantedOptionID,
                onSelectWantedOption: onSelectWantedOption
            )
                .frame(maxWidth: .infinity)

            HomeIndividualListingOfferedPanel(detail: detail)
                .frame(maxWidth: .infinity)
        }
    }
}
