import MapKit
import MegrumCore
import MegrumDesign
import SwiftUI

struct GroomArchiveScreen: View {
    @ObservedObject var appState: MegrumAppState
    var currentCoordinate: MegrumLocationCoordinate?
    @Environment(\.dismiss) private var dismiss
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var presentationState = GroomArchivePresentationState()

    private var archivedGrooms: [GroomPost] {
        GroomArchiveOrdering.sorted(appState.ownGroomArchive)
    }

    private var isArchiveLimited: Bool {
        MegrumPlusAccessPolicy.isGroomArchiveLimited(subscriptionState: appState.subscriptionState)
            && archivedGrooms.count >= MegrumPlusLimits.freeGroomArchiveLimit
    }

    var body: some View {
        ZStack(alignment: .top) {
            GroomArchiveMap(
                cameraPosition: $cameraPosition,
                grooms: archivedGrooms,
                currentCoordinate: currentCoordinate,
                onSelect: { presentationState.select($0) }
            )
            .ignoresSafeArea()

            GroomArchiveHeader(
                count: archivedGrooms.count,
                isLoading: appState.isLoadingGroomArchive,
                onClose: { dismiss() }
            )
            .padding(.horizontal, 18)
            .padding(.top, 14)

            if archivedGrooms.isEmpty, !appState.isLoadingGroomArchive {
                GroomArchiveEmptyState()
                    .padding(.horizontal, 28)
                    .frame(maxHeight: .infinity)
            }

            VStack {
                Spacer()
                if isArchiveLimited {
                    GroomArchiveLimitNotice {
                        presentationState.showMegrumPlus()
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 10)
                }
            }

            HStack {
                Spacer()
                GroomArchiveTimelineAxis(
                    grooms: archivedGrooms,
                    focusedGroomID: presentationState.focusedGroomID,
                    onFocus: focusGroom
                )
                .padding(.trailing, 6)
                .padding(.top, 104)
                .padding(.bottom, isArchiveLimited ? 104 : 54)
            }
        }
        .background(MegrumTheme.canvas)
        .task {
            await appState.loadSubscriptionState(reportsFailure: false)
            await appState.loadGroomArchive()
            updateCameraPosition()
        }
        .onChange(of: archivedGrooms) { _, _ in
            updateCameraPosition()
        }
        .onChange(of: presentationState.focusedGroomID) { _, _ in
            updateCameraPositionForFocusedGroom()
        }
        #if os(iOS)
        .groomViewerImmersiveOverlay(item: $presentationState.selectedGroom) { groom, dismiss in
            GroomArchiveStoryScreen(
                grooms: archivedGrooms,
                initialGroom: groom,
                appState: appState,
                onDismiss: dismiss
            )
        }
        #else
        .sheet(item: $presentationState.selectedGroom) { groom in
            GroomArchiveStoryScreen(
                grooms: archivedGrooms,
                initialGroom: groom,
                appState: appState
            )
        }
        #endif
        .sheet(isPresented: $presentationState.showsMegrumPlus) {
            NavigationStack {
                SubscriptionSettingsScreen(appState: appState)
            }
        }
    }

    private func updateCameraPosition() {
        cameraPosition = .region(
            GroomArchiveMapRegion.region(
                for: archivedGrooms,
                currentCoordinate: archivedGrooms.isEmpty ? currentCoordinate : nil
            )
        )
    }

    private func focusGroom(_ groom: GroomPost) {
        presentationState.focus(groom)
    }

    private func updateCameraPositionForFocusedGroom() {
        guard let groom = presentationState.focusedGroom(in: archivedGrooms) else {
            return
        }
        withAnimation(.easeInOut(duration: 0.28)) {
            cameraPosition = .region(GroomArchiveMapRegion.focusedRegion(for: groom))
        }
    }
}
