import Foundation
import MegrumCore

struct IndividualListingsPresentationState: Equatable {
    var editorRoute: IndividualListingEditorRoute?
    var locallyEditedListings: [UUID: IndividualListing] = [:]
    var didPresentInitialEditor = false
    var pendingDeleteListing: IndividualListing?
    var showsMegrumPlusUpsell = false

    var hasPendingDelete: Bool {
        pendingDeleteListing != nil
    }

    func displayedListings(_ listings: [IndividualListing]) -> [IndividualListing] {
        listings.map { listing in
            locallyEditedListings[listing.id] ?? listing
        }
    }

    mutating func clearLocalEdits() {
        locallyEditedListings.removeAll()
    }

    mutating func recordEdited(_ listing: IndividualListing) {
        locallyEditedListings[listing.id] = listing
    }

    mutating func removeLocalEdit(for listingID: UUID) {
        locallyEditedListings.removeValue(forKey: listingID)
    }

    mutating func openEdit(_ listing: IndividualListing, initialStep: IndividualListingEditorStep) {
        editorRoute = .edit(listing, initialStep: initialStep)
    }

    mutating func closeEditor() {
        editorRoute = nil
    }

    mutating func openCreateEditor(
        optionKind: IndividualListingOptionKind?,
        listings: [IndividualListing],
        subscriptionState: UserSubscriptionState
    ) {
        guard MegrumPlusAccessPolicy.canCreateIndividualListing(
            listings: listings,
            subscriptionState: subscriptionState
        ) else {
            showsMegrumPlusUpsell = true
            return
        }
        editorRoute = .create(optionKind: optionKind)
    }

    mutating func shouldPresentInitialEditor(
        initiallyPresentsEditor: Bool,
        initialEditorOptionKind: IndividualListingOptionKind?,
        initialEditorStep: IndividualListingEditorStep
    ) -> Bool {
        guard
            !didPresentInitialEditor,
            initiallyPresentsEditor || initialEditorOptionKind != nil || initialEditorStep != .haves
        else {
            return false
        }
        didPresentInitialEditor = true
        return true
    }

    mutating func requestDelete(_ listing: IndividualListing) {
        pendingDeleteListing = listing
    }

    mutating func clearPendingDelete() {
        pendingDeleteListing = nil
    }
}
