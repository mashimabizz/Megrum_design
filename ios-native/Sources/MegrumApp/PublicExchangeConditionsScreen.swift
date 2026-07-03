import MegrumCore
import MegrumDesign
import SwiftUI

struct PublicExchangeConditionsPresentation: Equatable {
    var standardSettings: HomeDefaultExchangeSettings?
    var listingConditions: [IndividualListing]
    var paymentSummaryText: String

    init(
        standardSettings: HomeDefaultExchangeSettings?,
        listings: [IndividualListing],
        profile: UserProfile?
    ) {
        self.standardSettings = standardSettings
        self.listingConditions = listings.filter { listing in
            listing.status == .active
                && IndividualListingExchangeSummary.extract(from: listing.note).summary != nil
        }
        self.paymentSummaryText = profile?.paymentSummaryText ?? "未設定"
    }

    var isEmpty: Bool {
        standardSettings == nil
            && listingConditions.isEmpty
            && paymentSummaryText == "未設定"
    }
}

struct PublicExchangeConditionsScreen: View {
    var displayName: String
    var settings: HomeDefaultExchangeSettings?
    var listings: [IndividualListing]
    var profile: UserProfile?

    @Environment(\.dismiss) private var dismiss

    private var presentation: PublicExchangeConditionsPresentation {
        PublicExchangeConditionsPresentation(
            standardSettings: settings,
            listings: listings,
            profile: profile
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                if let settings = presentation.standardSettings {
                    PublicExchangeStandardSettingsCard(settings: settings)
                }

                if !presentation.listingConditions.isEmpty {
                    listingConditionSection
                }

                if presentation.paymentSummaryText != "未設定" {
                    PublicExchangePaymentCard(summaryText: presentation.paymentSummaryText)
                }

                if presentation.isEmpty {
                    ContentUnavailableView(
                        "交換条件はまだ公開されていません",
                        systemImage: "arrow.left.arrow.right.circle",
                        description: Text("公開中の個別募集に交換条件が設定されると、ここに表示されます。")
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.top, 36)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 36)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .navigationTitle("交換条件")
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("交換条件")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            Text("\(displayName)さんが公開している交換条件です。編集はできません。")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var listingConditionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("個別募集の交換条件")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .padding(.horizontal, 2)

            ForEach(Array(presentation.listingConditions.enumerated()), id: \.element.id) { index, listing in
                VStack(alignment: .leading, spacing: 8) {
                    Text(IndividualListingListPresentation.conditionStripTitle(
                        index: index,
                        totalCount: presentation.listingConditions.count
                    ))
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .padding(.horizontal, 4)

                    IndividualListingExchangeConditionPanel(
                        listing: listing,
                        canEdit: false,
                        onEdit: {},
                        onShare: {},
                        onDelete: {}
                    )
                }
            }
        }
    }
}
