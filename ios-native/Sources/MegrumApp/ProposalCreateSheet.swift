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
    @State var draftState = ProposalCreateSheetDraftState()
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
                    selectedGoodsID: $draftState.selectedSenderGoodsID
                )

                ProposalCreateExchangeMethodSection(
                    exchangeMethod: $draftState.exchangeMethod,
                    configuration: configuration
                )

                if configuration.requiresMeetupBeforeSubmit {
                    ProposalMeetupForm(
                        startAt: $draftState.meetupStartAt,
                        endAt: $draftState.meetupEndAt,
                        placeName: $draftState.meetupPlaceName,
                        latitudeText: $draftState.meetupLatitudeText,
                        longitudeText: $draftState.meetupLongitudeText,
                        isRequestingLocation: locationState.isRequestingLocation,
                        locationErrorMessage: locationState.locationErrorMessage
                    )
                }

                ProposalCreateConditionTagsSection(
                    tags: conditionTagOptions,
                    selectedTags: draftState.selectedConditionTags,
                    onToggle: toggleConditionTag
                )

                ProposalCreateMessageSection(message: $draftState.message)

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
        .onChange(of: draftState.exchangeMethod) { _, _ in
            handleExchangeMethodChange()
        }
        .onChange(of: draftState.meetupStartAt) { _, newValue in
            boundMeetupEnd(after: newValue)
        }
        .onChange(of: locationState.coordinate) { _, coordinate in
            applyCurrentLocation(coordinate)
        }
    }
}
