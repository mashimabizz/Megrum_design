import MapKit
import MegrumDesign
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

#if DEBUG
struct MeguriHomeDesignPreview: View {
    var sheetMode: MeguriHomeSheetMode = .normal

    @State private var cameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 35.7056, longitude: 139.7519),
            span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.014)
        )
    )

    var body: some View {
        ZStack(alignment: .top) {
            MeguriDesignColors.canvas
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Color.white.opacity(0.98)
                    .frame(height: MeguriDesignMetrics.mapTop)

                Map(position: $cameraPosition, interactionModes: []) {}
                    .overlay(Color.white.opacity(0.24))
                    .frame(height: sheetMode.mapHeight - MeguriDesignMetrics.mapTop)
                    .allowsHitTesting(false)
            }
            .frame(height: sheetMode.mapHeight)
            .ignoresSafeArea(edges: .top)

            MeguriMapOverlay(mode: sheetMode)
                .padding(.top, MeguriDesignMetrics.mapTop)
                .frame(height: sheetMode.mapHeight)

            MeguriHomeHeader()
                .padding(.horizontal, MeguriDesignMetrics.edgePadding)
                .padding(.top, MeguriDesignMetrics.headerTop)

            if sheetMode == .normal {
                MeguriMapControls()
                    .padding(.trailing, 18)
                    .padding(.top, 352)
            }

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: sheetMode.sheetTop)

                MeguriConversationSheet(mode: sheetMode)
                    .frame(height: MeguriDesignMetrics.previewHeight - sheetMode.sheetTop - MeguriDesignMetrics.tabBarHeight + 10)
            }

            VStack {
                Spacer()
                MeguriTabBar(mode: sheetMode)
            }
        }
        .frame(
            width: MeguriDesignMetrics.previewWidth,
            height: MeguriDesignMetrics.previewHeight
        )
        .clipShape(RoundedRectangle(cornerRadius: 0))
        .meguriDesignPreviewChromeHidden()
    }
}

enum MeguriHomeSheetMode {
    case normal
    case expanded

    var mapHeight: CGFloat {
        switch self {
        case .normal:
            520
        case .expanded:
            190
        }
    }

    var sheetTop: CGFloat {
        switch self {
        case .normal:
            430
        case .expanded:
            168
        }
    }
}

#Preview("めぐりホーム") {
    MeguriHomeDesignPreview(sheetMode: .normal)
}

#Preview("めぐりホーム 下タブ引き上げ") {
    MeguriHomeDesignPreview(sheetMode: .expanded)
}

#endif
