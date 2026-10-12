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
    /// iter1226.459：アーカイブのピンもめぐりホームと同じ標準zoomで開く（iOS18+）。
    /// 旧経路（immersiveオーバーレイ）はiOS17フォールバックのみ。
    @State private var zoomRoute: GroomMapViewerRoute?
    @Namespace private var groomZoomNamespace

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
                onSelect: openArchivedGroom,
                groomZoomNamespace: groomZoomNamespace
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
        // iter1226.459：めぐりホームと同一方式（fullScreenCover + 標準zoom）。
        // source は地図overlayの常設ピン（GroomArchiveMap）なのでタップ即・一体でズームする。
        .fullScreenCover(item: $zoomRoute) { route in
            GroomArchiveStoryScreen(
                grooms: route.grooms,
                initialGroom: route.initialGroom,
                appState: appState,
                onDismiss: { zoomRoute = nil }
            )
            .modifier(GroomMapZoomDestination(sourceID: route.sourceID, namespace: groomZoomNamespace))
        }
        // iOS17フォールバック（openArchivedGroom が selectedGroom を立てた時のみ）。
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

    /// iter1226.459：iOS18+は標準zoom（source常設・タップ即提示）、iOS17は旧オーバーレイ。
    private func openArchivedGroom(_ groom: GroomPost) {
        #if os(iOS)
        if #available(iOS 18.0, *) {
            zoomRoute = GroomMapViewerRoute(
                sourceID: .groom(groom.id),
                grooms: archivedGrooms,
                initialGroom: groom
            )
            return
        }
        #endif
        presentationState.select(groom)
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
