import Foundation
import MapKit
import MegrumCore
import MegrumDesign
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// FB(iter1226.391/392/399)：ホーム等からのグルーム投稿で、トピック/シリーズ確定の後に
/// 「投稿する場所を地図で選ぶ」全画面ステップ。めぐりホームのように地図を画面いっぱいに広げ、
/// ヘッダーも地図の上に透過配置。タップするとグルーム画像のピンが上から降りてくる。
struct GroomStoryLocationStepView: View {
    var photoData: Data?
    /// ピンには文字を付けないため未使用（呼び出し互換のため残す）。
    var caption: String?
    @Binding var selectedCoordinate: MegrumLocationCoordinate?
    var currentCoordinate: MegrumLocationCoordinate?
    var isRequestingLocation: Bool
    var canConfirm: Bool
    var onRequestLocation: () -> Void
    var onOutOfRange: (String) -> Void
    var onCancel: () -> Void
    var onConfirm: () -> Void

    @State private var cameraPosition = MapCameraPosition.automatic
    @State private var hasPreparedInitialPosition = false

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            mapLayer
                .ignoresSafeArea()

            header

            VStack(spacing: 0) {
                Spacer()
                confirmButton
            }
        }
        .onAppear(perform: prepareInitialSelectionIfNeeded)
        .onChange(of: currentCoordinate) { _, _ in
            prepareInitialSelectionIfNeeded()
        }
    }

    @ViewBuilder
    private var mapLayer: some View {
        if let baseCoordinate = currentCoordinate {
            MapReader { proxy in
                Map(position: $cameraPosition, interactionModes: [.pan, .zoom]) {
                    MapCircle(
                        center: baseCoordinate.clLocationCoordinate,
                        radius: MeguriAccessPolicy.creationRadiusMeters
                    )
                    .foregroundStyle(MegrumTheme.lavender.opacity(0.08))
                    .stroke(MegrumTheme.lavender.opacity(0.48), lineWidth: 1.8)

                    Annotation("現在地", coordinate: baseCoordinate.clLocationCoordinate) {
                        CurrentLocationDot()
                    }

                    if let selectedCoordinate {
                        Annotation(
                            "投稿する場所",
                            coordinate: selectedCoordinate.clLocationCoordinate,
                            anchor: .bottom
                        ) {
                            GroomLocationDropPin(imageData: photoData)
                                // 選択が変わるたびに再マウントして降下アニメを再生する。
                                .id(selectedCoordinate.creationPromptID)
                        }
                    }
                }
                .mapStyle(MeguriMapVisualStyle.quietStandard)
                .overlay {
                    MeguriMapBrandToneOverlay(
                        topWhiteOpacity: 0.30,
                        middleWhiteOpacity: 0.06,
                        bottomWhiteOpacity: 0.02
                    )
                }
                .gesture(
                    SpatialTapGesture()
                        .onEnded { value in
                            guard let coordinate = proxy.convert(value.location, from: .local) else {
                                return
                            }
                            selectTappedCoordinate(coordinate, baseCoordinate: baseCoordinate)
                        }
                )
            }
        } else {
            GroomLocationMissingView(
                isRequestingLocation: isRequestingLocation,
                onRequestLocation: onRequestLocation
            )
        }
    }

    private var header: some View {
        HStack {
            Button(action: onCancel) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(.black.opacity(0.34), in: Circle())
            }

            Spacer()

            Text("投稿する場所を選ぶ")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(.black.opacity(0.34), in: Capsule())

            Spacer()

            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
    }

    private var confirmButton: some View {
        Button(action: onConfirm) {
            Text("この場所にする")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    LinearGradient(
                        colors: canConfirm
                            ? [MegrumTheme.sky, MegrumTheme.lavender]
                            : [MegrumTheme.muted.opacity(0.55), MegrumTheme.muted.opacity(0.55)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .shadow(color: MegrumTheme.ink.opacity(0.22), radius: 16, y: 8)
        }
        .disabled(!canConfirm)
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
    }

    private func prepareInitialSelectionIfNeeded() {
        guard let baseCoordinate = currentCoordinate else {
            return
        }
        if selectedCoordinate == nil {
            selectedCoordinate = baseCoordinate
        }
        if !hasPreparedInitialPosition {
            hasPreparedInitialPosition = true
            centerMap(on: selectedCoordinate ?? baseCoordinate, spanMeters: 1_550)
        }
    }

    private func selectTappedCoordinate(
        _ coordinate: CLLocationCoordinate2D,
        baseCoordinate: MegrumLocationCoordinate
    ) {
        let tapped = MegrumLocationCoordinate(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        guard MeguriAccessPolicy.canCreateAt(
            tapped,
            currentCoordinate: baseCoordinate
        ) else {
            onOutOfRange(
                MeguriAccessPolicy.creationLocationMessage(
                    selectedCoordinate: tapped,
                    currentCoordinate: baseCoordinate
                )
            )
            return
        }
        selectedCoordinate = tapped
    }

    private func centerMap(on coordinate: MegrumLocationCoordinate, spanMeters: CLLocationDistance) {
        let region = MKCoordinateRegion(
            center: coordinate.clLocationCoordinate,
            latitudinalMeters: spanMeters,
            longitudinalMeters: spanMeters
        )
        withAnimation(.smooth(duration: 0.25)) {
            cameraPosition = .region(region)
        }
    }
}

/// タップ地点に「上から降りてくる」グルーム画像ピン（文字なし）。降下アニメは作成プロンプトと同じ。
private struct GroomLocationDropPin: View {
    var imageData: Data?

    @State private var presentationState = MeguriMapCreationPromptPresentationState()

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(.white)
                    .frame(width: 62, height: 62)
                    .shadow(color: MegrumTheme.ink.opacity(0.22), radius: 12, y: 6)

                #if canImport(UIKit)
                if let imageData, let image = UIImage(data: imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 54, height: 54)
                        .clipShape(Circle())
                } else {
                    fallbackIcon
                }
                #else
                fallbackIcon
                #endif
            }

            GroomLocationPinPointer()
                .fill(.white)
                .frame(width: 16, height: 10)
                .offset(y: -1)
                .shadow(color: MegrumTheme.ink.opacity(0.14), radius: 4, y: 3)
        }
        .offset(y: presentationState.dropPinYOffset)
        .opacity(presentationState.dropPinOpacity)
        .scaleEffect(presentationState.dropPinScale, anchor: .bottom)
        .onAppear {
            presentationState.prepare()
            withAnimation(.interpolatingSpring(stiffness: 250, damping: 17).delay(0.02)) {
                presentationState.show()
            }
        }
        .accessibilityHidden(true)
    }

    private var fallbackIcon: some View {
        Circle()
            .fill(MegrumTheme.lavender.opacity(0.18))
            .frame(width: 54, height: 54)
            .overlay {
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(MegrumTheme.lavender)
            }
    }
}

private struct GroomLocationPinPointer: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

private struct GroomLocationMissingView: View {
    var isRequestingLocation: Bool
    var onRequestLocation: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.001)
            VStack(spacing: 14) {
                Image(systemName: "location.circle")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.86))
                Text(isRequestingLocation ? "現在地を取得中…" : "現在地を取得すると場所を選べます")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                if !isRequestingLocation {
                    Button(action: onRequestLocation) {
                        Text("現在地を取得")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(.white, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MegrumTheme.ink.opacity(0.9))
    }
}
