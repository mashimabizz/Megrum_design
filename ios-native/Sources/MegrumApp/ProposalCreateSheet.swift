import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct ProposalCreateSheet: View {
    @ObservedObject var appState: MegrumAppState
    var targetItem: GoodsItem
    var listingID: UUID?
    var receiverGoodsIDs: [UUID]?

    @Environment(\.dismiss) var dismiss
    @State var selectedSenderGoodsID: UUID?
    @State var exchangeMethod: ExchangeMethod = .mail
    @State var selectedConditionTags: Set<String> = []
    @State var message = ""
    @State var meetupStartAt = Date()
    @State var meetupEndAt = Date().addingTimeInterval(30 * 60)
    @State var meetupPlaceName = ""
    @State var meetupLatitudeText = ""
    @State var meetupLongitudeText = ""
    @StateObject var locationState = MegrumLocationState()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                ProposalCreateSheetHeader()

                ProposalCreateTargetCard(
                    targetItem: targetItem,
                    configuration: configuration
                )

                ProposalCreateSenderGoodsSection(
                    inventory: appState.inventory,
                    selectedGoodsID: $selectedSenderGoodsID
                )

                ProposalCreateExchangeMethodSection(
                    exchangeMethod: $exchangeMethod,
                    configuration: configuration
                )

                if configuration.requiresMeetupBeforeSubmit {
                    ProposalMeetupForm(
                        startAt: $meetupStartAt,
                        endAt: $meetupEndAt,
                        placeName: $meetupPlaceName,
                        latitudeText: $meetupLatitudeText,
                        longitudeText: $meetupLongitudeText,
                        isRequestingLocation: locationState.isRequestingLocation,
                        locationErrorMessage: locationState.locationErrorMessage
                    )
                }

                ProposalCreateConditionTagsSection(
                    tags: conditionTagOptions,
                    selectedTags: selectedConditionTags,
                    onToggle: toggleConditionTag
                )

                ProposalCreateMessageSection(message: $message)

                ProposalCreateSubmitButton(
                    title: configuration.submitTitle,
                    isCreating: appState.isCreatingProposal,
                    canSubmit: configuration.canSubmit
                ) {
                    Task {
                        await createProposal()
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 24)
            .padding(.bottom, 40)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .navigationTitle("打診作成")
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
        .onAppear {
            prepareOnAppear()
        }
        .task {
            if appState.mailingAddress == nil {
                await appState.loadMailingAddress()
            }
        }
        .onChange(of: exchangeMethod) { _, _ in
            handleExchangeMethodChange()
        }
        .onChange(of: meetupStartAt) { _, newValue in
            boundMeetupEnd(after: newValue)
        }
        .onChange(of: locationState.coordinate) { _, coordinate in
            applyCurrentLocation(coordinate)
        }
    }
}
