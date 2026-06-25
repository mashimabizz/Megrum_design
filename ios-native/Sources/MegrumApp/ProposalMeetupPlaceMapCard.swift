import MapKit
import MegrumDesign
import SwiftUI

struct ProposalMeetupPlaceMapCard: View {
    @Binding var cameraPosition: MapCameraPosition
    var selectedCoordinate: CLLocationCoordinate2D?
    var markerTitle: String
    var coordinateCaption: String
    var onSelectCoordinate: (CLLocationCoordinate2D) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("地図で場所を選択", systemImage: "map")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            MapReader { proxy in
                Map(position: $cameraPosition, interactionModes: [.pan, .zoom]) {
                    if let selectedCoordinate {
                        Marker(markerTitle.isEmpty ? "待ち合わせ" : markerTitle, coordinate: selectedCoordinate)
                            .tint(MegrumTheme.lavender)
                    }
                }
                .frame(height: 216)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(.white.opacity(0.72), lineWidth: 1)
                }
                .gesture(
                    SpatialTapGesture()
                        .onEnded { value in
                            guard let coordinate = proxy.convert(value.location, from: .local) else {
                                return
                            }
                            onSelectCoordinate(coordinate)
                        }
                )
            }

            Text(coordinateCaption)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
