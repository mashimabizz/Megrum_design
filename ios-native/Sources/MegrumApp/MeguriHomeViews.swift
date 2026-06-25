import MegrumCore
import MapKit
import SwiftUI

struct MeguriHomeContent: View {
    @Binding var cameraPosition: MapCameraPosition
    var viewer: UserProfile?
    var grooms: [GroomPost]
    var mapGrooms: [GroomPost]
    var threads: [BoardThread]
    var replyCounts: [UUID: Int]
    var currentCoordinate: MegrumLocationCoordinate?
    var isLoading: Bool
    var selectedScope: BoardThread.Audience
    var selectedPrefecture: String
    var notice: MegrumLocationNotice?
    var isRequestingLocation: Bool
    @Binding var boardSheetDetent: MeguriBoardSheetDetent
    var onOpenMap: () -> Void
    var onRecenterMap: () -> Void
    var onSelectGroom: (GroomPost) -> Void
    var onSelectThread: (BoardThread) -> Void
    var onNoticeAction: () -> Void
    var onChangeScope: (BoardThread.Audience) -> Void
    var onOpenPrefecture: () -> Void
    var onOpenGroomComposer: () -> Void
    var onOpenThreadComposer: () -> Void
    var onOpenGroomArchive: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                MeguriHomeMapBackdrop(
                    cameraPosition: $cameraPosition,
                    grooms: mapGrooms,
                    threads: threads,
                    currentCoordinate: currentCoordinate,
                    viewerID: viewer?.id,
                    onSelectGroom: onSelectGroom,
                    onSelectThread: onSelectThread
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        VStack(spacing: 10) {
                            MeguriMapRecenterButton(
                                isRequesting: isRequestingLocation,
                                action: onRecenterMap
                            )
                            MeguriGroomArchiveButton(action: onOpenGroomArchive)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 78)

                    if let notice {
                        MeguriHomeNoticeCard(notice: notice, action: onNoticeAction)
                            .padding(.horizontal, 38)
                            .padding(.top, 14)
                    }

                    Spacer()
                }

                MeguriBoardBottomSheet(
                    detent: $boardSheetDetent,
                    viewportHeight: proxy.size.height,
                    threads: threads,
                    grooms: grooms,
                    replyCounts: replyCounts,
                    isLoading: isLoading,
                    selectedScope: selectedScope,
                    selectedPrefecture: selectedPrefecture,
                    onChangeScope: onChangeScope,
                    onOpenPrefecture: onOpenPrefecture,
                    onOpenGroomComposer: onOpenGroomComposer,
                    onOpenThreadComposer: onOpenThreadComposer,
                    onOpenThread: onSelectThread
                )
                .frame(height: MeguriBoardSheetLayout.expandedHeight(in: proxy.size.height), alignment: .top)
            }
        }
    }
}
