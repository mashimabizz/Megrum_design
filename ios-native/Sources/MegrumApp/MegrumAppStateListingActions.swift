import Foundation
import MegrumCore
import MegrumData

@MainActor
extension MegrumAppState {
    public func loadIndividualListings() async {
        guard !isLoadingIndividualListings else {
            return
        }

        isLoadingIndividualListings = true
        errorMessage = nil
        do {
            listings = try await repository.loadIndividualListings()
        } catch {
            MegrumAppLogger.general.error("Individual listing load failed: \(String(describing: error), privacy: .public)")
            errorMessage = "個別募集を読み込めませんでした"
        }
        isLoadingIndividualListings = false
    }

    public func createIndividualListing(_ input: IndividualListingCreateInput) async -> Bool {
        await createIndividualListingRecord(input) != nil
    }

    public func createIndividualListingRecord(_ input: IndividualListingCreateInput) async -> IndividualListing? {
        guard !isCreatingIndividualListing else {
            return nil
        }
        guard input.hasOfferCondition, input.hasReceivableCondition else {
            errorMessage = "譲るものと求めるものを選択してください"
            return nil
        }
        guard MegrumPlusAccessPolicy.canCreateIndividualListing(
            listings: listings,
            subscriptionState: subscriptionState
        ) else {
            errorMessage = MegrumPlusAccessPolicy.individualListingLimitMessage(listings: listings)
            return nil
        }

        let normalizedInput = IndividualListingInputNormalizer.normalized(input)

        isCreatingIndividualListing = true
        errorMessage = nil
        do {
            let created = try await repository.createIndividualListing(normalizedInput)
            listings = IndividualListingStateReducer.upserting(created, into: listings)
            isCreatingIndividualListing = false
            refreshHomeCandidatesAfterListingMutation()
            return created
        } catch {
            MegrumAppLogger.general.error("Individual listing create failed: \(String(describing: error), privacy: .public)")
            errorMessage = (error as? SupabaseRESTError)?.serverMessage ?? "個別募集を作成できませんでした"
            isCreatingIndividualListing = false
            return nil
        }
    }

    public func updateIndividualListing(
        listingID: UUID,
        primaryOptionID: UUID?,
        input: IndividualListingCreateInput,
        status: IndividualListingStatus
    ) async -> IndividualListing? {
        guard updatingIndividualListingID == nil else {
            return nil
        }
        guard input.hasOfferCondition, input.hasReceivableCondition else {
            errorMessage = "譲るものと求めるものを選択してください"
            return nil
        }

        let normalizedInput = IndividualListingInputNormalizer.normalized(input)

        updatingIndividualListingID = listingID
        errorMessage = nil
        do {
            let updated = try await repository.updateIndividualListing(
                listingID: listingID,
                primaryOptionID: primaryOptionID,
                input: normalizedInput,
                status: status
            )
            listings = IndividualListingStateReducer.upserting(updated, into: listings)
            updatingIndividualListingID = nil
            refreshHomeCandidatesAfterListingMutation()
            return updated
        } catch {
            MegrumAppLogger.general.error("Individual listing update failed: \(String(describing: error), privacy: .public)")
            errorMessage = (error as? SupabaseRESTError)?.serverMessage ?? "個別募集を更新できませんでした"
            updatingIndividualListingID = nil
            return nil
        }
    }

    public func archiveIndividualListing(_ listingID: UUID) async -> Bool {
        guard updatingIndividualListingID == nil else {
            return false
        }

        updatingIndividualListingID = listingID
        errorMessage = nil
        do {
            try await repository.archiveIndividualListing(listingID: listingID)
            listings = IndividualListingStateReducer.removing(listingID: listingID, from: listings)
            updatingIndividualListingID = nil
            refreshHomeCandidatesAfterListingMutation()
            return true
        } catch {
            MegrumAppLogger.general.error("Individual listing archive failed: \(String(describing: error), privacy: .public)")
            errorMessage = "個別募集を削除できませんでした"
            updatingIndividualListingID = nil
            return false
        }
    }

    private func refreshHomeCandidatesAfterListingMutation() {
        Task { @MainActor [weak self] in
            await self?.refreshHomeCandidates(reportsFailure: false)
        }
    }
}
