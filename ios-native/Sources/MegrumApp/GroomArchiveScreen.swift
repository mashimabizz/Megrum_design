import MapKit
import MegrumCore
import MegrumDesign
import SwiftUI

struct GroomArchiveScreen: View {
    @ObservedObject var appState: MegrumAppState
    var currentCoordinate: MegrumLocationCoordinate?
    @Environment(\.dismiss) private var dismiss
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedGroom: GroomPost?

    private var archivedGrooms: [GroomPost] {
        GroomArchiveOrdering.sorted(appState.ownGroomArchive)
    }

    var body: some View {
        ZStack(alignment: .top) {
            GroomArchiveMap(
                cameraPosition: $cameraPosition,
                grooms: archivedGrooms,
                currentCoordinate: currentCoordinate,
                onSelect: { selectedGroom = $0 }
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
                GroomArchiveThumbnailRail(
                    grooms: archivedGrooms,
                    selectedGroomID: selectedGroom?.id,
                    onSelect: { selectedGroom = $0 }
                )
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
            }
        }
        .background(MegrumTheme.canvas)
        .task {
            await appState.loadGroomArchive()
            updateCameraPosition()
        }
        .onChange(of: archivedGrooms) { _, _ in
            updateCameraPosition()
        }
        #if os(iOS)
        .fullScreenCover(item: $selectedGroom) { groom in
            GroomArchiveStoryScreen(
                grooms: archivedGrooms,
                initialGroom: groom,
                appState: appState
            )
        }
        #else
        .sheet(item: $selectedGroom) { groom in
            GroomArchiveStoryScreen(
                grooms: archivedGrooms,
                initialGroom: groom,
                appState: appState
            )
        }
        #endif
    }

    private func updateCameraPosition() {
        cameraPosition = .region(
            GroomArchiveMapRegion.region(
                for: archivedGrooms,
                currentCoordinate: currentCoordinate
            )
        )
    }
}
