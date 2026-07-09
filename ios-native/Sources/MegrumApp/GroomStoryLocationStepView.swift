import MegrumCore
import MegrumDesign
import SwiftUI

/// FB(iter1226.391/392)：ホーム等からのグルーム投稿で、トピック/シリーズ確定の後に
/// 「投稿する場所を地図で選ぶ」全画面ステップ。地図を画面いっぱいに出して最後に場所を決める。
struct GroomStoryLocationStepView: View {
    var photoData: Data?
    var caption: String?
    @Binding var selectedCoordinate: MegrumLocationCoordinate?
    var currentCoordinate: MegrumLocationCoordinate?
    var isRequestingLocation: Bool
    var canConfirm: Bool
    var onRequestLocation: () -> Void
    var onOutOfRange: (String) -> Void
    var onCancel: () -> Void
    var onConfirm: () -> Void

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                header

                ScrollView {
                    MeguriCreationLocationPicker(
                        title: "投稿する場所",
                        subtitle: "現在地から半径1km以内の地図上をタップして選択",
                        currentCoordinate: currentCoordinate,
                        isRequestingLocation: isRequestingLocation,
                        preview: photoData.map { .groom(imageData: $0, caption: caption) } ?? .pin,
                        // 画面いっぱいの地図（ヘッダー/ボタン/キャプション分を差し引いた高さ）。
                        mapHeight: max(320, proxy.size.height - 240),
                        selectedCoordinate: $selectedCoordinate,
                        onRequestLocation: onRequestLocation,
                        onOutOfRange: onOutOfRange
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                }

                confirmButton
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(MegrumTheme.canvas.ignoresSafeArea())
        }
    }

    private var header: some View {
        HStack {
            Button(action: onCancel) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(MegrumTheme.ink)
                    .frame(width: 40, height: 40)
            }
            Spacer()
            Text("投稿する場所を選ぶ")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
            Spacer()
            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 8)
        .padding(.top, 10)
        .background(MegrumTheme.canvas)
    }

    private var confirmButton: some View {
        Button(action: onConfirm) {
            Text("この場所にする")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    LinearGradient(
                        colors: canConfirm
                            ? [MegrumTheme.sky, MegrumTheme.lavender]
                            : [MegrumTheme.muted.opacity(0.5), MegrumTheme.muted.opacity(0.5)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
        }
        .disabled(!canConfirm)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 14)
        .background(MegrumTheme.canvas)
    }
}
