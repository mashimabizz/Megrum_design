import MapKit
import MegrumDesign
import SwiftUI

struct ProposalFlowMeetupForm: View {
    private enum Field: Hashable {
        case place
    }

    @Binding var startAt: Date
    @Binding var endAt: Date
    @Binding var placeName: String
    @Binding var latitudeText: String
    @Binding var longitudeText: String
    var isRequestingLocation: Bool
    var locationErrorMessage: String?
    var placeSuggestions: [String]
    var focusPlaceFieldRequest: Int
    @State private var cameraPosition: MapCameraPosition = .region(Self.fallbackRegion)
    @FocusState private var focusedField: Field?

    private static let fallbackCoordinate = CLLocationCoordinate2D(latitude: 35.681236, longitude: 139.767125)
    private static let mapSpan = MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
    private static let fallbackRegion = MKCoordinateRegion(center: fallbackCoordinate, span: mapSpan)

    private var selectedCoordinate: CLLocationCoordinate2D? {
        ProposalMeetupMapDraft.coordinate(latitudeText: latitudeText, longitudeText: longitudeText)?.clLocationCoordinate
    }

    var body: some View {
        ProposalCardSection(title: "待ち合わせ候補") {
            VStack(alignment: .leading, spacing: 14) {
                VStack(spacing: 0) {
                    DatePicker("開始日時", selection: $startAt, displayedComponents: [.date, .hourAndMinute])
                        .proposalFlowMeetupRow()
                    Divider()
                    DatePicker("終了日時", selection: $endAt, displayedComponents: [.date, .hourAndMinute])
                        .proposalFlowMeetupRow()
                }
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .padding(.horizontal, 12)
                .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 10) {
                    Label("地図で場所を選択", systemImage: "map")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)

                    MapReader { proxy in
                        Map(position: $cameraPosition, interactionModes: [.pan, .zoom]) {
                            if let selectedCoordinate {
                                Marker(
                                    placeName.isBlank ? "待ち合わせ" : placeName,
                                    coordinate: selectedCoordinate
                                )
                                .tint(MegrumTheme.lavender)
                            }
                        }
                        .frame(height: 184)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(.white.opacity(0.7), lineWidth: 1)
                        }
                        .gesture(
                            SpatialTapGesture()
                                .onEnded { value in
                                    guard let coordinate = proxy.convert(value.location, from: .local) else {
                                        return
                                    }
                                    applyMapSelection(coordinate)
                                }
                        )
                    }

                    VStack(spacing: 0) {
                        TextField("場所名", text: $placeName)
                            .focused($focusedField, equals: .place)
                            .proposalFlowMeetupRow()
                        Divider()
                        HStack(spacing: 12) {
                            TextField("緯度", text: $latitudeText)
                                #if os(iOS)
                                .keyboardType(.decimalPad)
                                #endif
                            TextField("経度", text: $longitudeText)
                                #if os(iOS)
                                .keyboardType(.decimalPad)
                                #endif
                        }
                        .proposalFlowMeetupRow()
                    }
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                    .padding(.horizontal, 12)
                    .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                    if !placeSuggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("予定から場所を反映")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundStyle(MegrumTheme.muted)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(placeSuggestions, id: \.self) { suggestion in
                                        Button {
                                            placeName = suggestion
                                        } label: {
                                            Text(suggestion)
                                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                                .lineLimit(1)
                                                .foregroundStyle(MegrumTheme.ink)
                                                .padding(.horizontal, 11)
                                                .frame(height: 34)
                                                .background(.white.opacity(0.72), in: Capsule())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                }

                HStack(spacing: 8) {
                    if isRequestingLocation {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Text(locationErrorMessage ?? "現在地が使える場合は緯度経度を自動入力します。")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .onAppear {
            syncCameraToSelectedCoordinate(animated: false)
        }
        .onChange(of: latitudeText) { _, _ in
            syncCameraToSelectedCoordinate(animated: true)
        }
        .onChange(of: longitudeText) { _, _ in
            syncCameraToSelectedCoordinate(animated: true)
        }
        .onChange(of: focusPlaceFieldRequest) { _, _ in
            focusedField = .place
        }
    }

    private func applyMapSelection(_ coordinate: CLLocationCoordinate2D) {
        guard ProposalMeetupMapDraft.isValid(latitude: coordinate.latitude, longitude: coordinate.longitude) else {
            return
        }
        latitudeText = ProposalMeetupMapDraft.coordinateText(coordinate.latitude)
        longitudeText = ProposalMeetupMapDraft.coordinateText(coordinate.longitude)
        let trimmedPlaceName = placeName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedPlaceName.isEmpty || trimmedPlaceName == "現在地" {
            placeName = ProposalMeetupMapDraft.fallbackPlaceName
        }
        withAnimation(.smooth(duration: 0.18)) {
            cameraPosition = .region(MKCoordinateRegion(center: coordinate, span: Self.mapSpan))
        }
    }

    private func syncCameraToSelectedCoordinate(animated: Bool) {
        guard let selectedCoordinate else {
            return
        }
        let region = MKCoordinateRegion(center: selectedCoordinate, span: Self.mapSpan)
        if animated {
            withAnimation(.smooth(duration: 0.18)) {
                cameraPosition = .region(region)
            }
        } else {
            cameraPosition = .region(region)
        }
    }
}
