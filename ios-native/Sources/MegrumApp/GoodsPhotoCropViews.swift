import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct GoodsPhotoCropSession: Identifiable, Equatable {
    enum Source: Equatable {
        case newPhoto
        case selectedPhoto(photoID: UUID)
        case tradingCardBulk
    }

    var id: UUID
    var source: Source
    var upload: GoodsPhotoUpload
    var initialFrames: [TradingCardCropFrame]

    init(
        id: UUID = UUID(),
        source: Source,
        upload: GoodsPhotoUpload,
        initialFrames: [TradingCardCropFrame] = []
    ) {
        self.id = id
        self.source = source
        self.upload = upload
        self.initialFrames = initialFrames
    }
}

struct GoodsPhotoCropSheet: View {
    var session: GoodsPhotoCropSession
    var title: String
    var onCancel: () -> Void
    var onApply: ([GoodsPhotoUpload]) -> Void

    @State private var presentationState: GoodsPhotoCropSheetPresentationState

    init(
        session: GoodsPhotoCropSession,
        title: String,
        onCancel: @escaping () -> Void,
        onApply: @escaping ([GoodsPhotoUpload]) -> Void
    ) {
        self.session = session
        self.title = title
        self.onCancel = onCancel
        self.onApply = onApply
        _presentationState = State(initialValue: GoodsPhotoCropSheetPresentationState(initialFrames: session.initialFrames))
    }

    private var isBulkSession: Bool {
        session.source == .tradingCardBulk
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if isBulkSession, !session.initialFrames.isEmpty {
                        GoodsCropAutoDetectPill()
                    }

                    GoodsCropFrameCanvas(
                        imageData: session.upload.data,
                        frames: $presentationState.frames,
                        selectedFrameID: $presentationState.selectedFrameID
                    )
                    .frame(height: 430)

                    Text(hintText)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(MegrumTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)

                    GoodsCropPreviewStrip(
                        imageData: session.upload.data,
                        frames: presentationState.frames,
                        selectedFrameID: $presentationState.selectedFrameID,
                        onDelete: deleteFrame
                    )

                    if let message = presentationState.message {
                        Text(message)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.red)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(MegrumTheme.pink.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    Button(action: applyCrops) {
                        Text(applyTitle)
                            .font(.headline.weight(.black))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(MegrumTheme.lavender, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .background(MegrumTheme.canvas.ignoresSafeArea())
            .navigationTitle(title)
            .megrumInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("リセット", action: resetFrames)
                }
            }
        }
    }

    private var hintText: String {
        if isBulkSession {
            "枠をタップして選択、ドラッグで移動、四隅で大きさを調整できます。"
        } else {
            "写真の上をドラッグすると切り取り枠を描けます。そのまま追加すると写真全体を使います。"
        }
    }

    private var applyTitle: String {
        presentationState.frames.isEmpty
            ? "この内容で追加（写真全体）"
            : "この内容で追加（\(presentationState.frames.count)件）"
    }

    private func deleteFrame(_ frameID: UUID) {
        presentationState.deleteFrame(frameID)
    }

    private func resetFrames() {
        presentationState.reset(to: session.initialFrames)
    }

    private func applyCrops() {
        do {
            var uploads: [GoodsPhotoUpload] = []
            for frame in presentationState.frames {
                if GoodsPhotoCropSheet.isEffectivelyFullFrame(frame.rect) {
                    // ほぼ全体の枠は再エンコードせず元画像をそのまま使う
                    uploads.append(session.upload)
                } else {
                    let results = try TradingCardBulkRecognizer.cropFramesSynchronously([frame], in: session.upload.data)
                    uploads.append(contentsOf: results.map(\.upload))
                }
            }
            if uploads.isEmpty {
                // iter1226.436：枠なし＝写真全体をそのまま使う（再エンコードなし）。
                uploads = [session.upload]
            }
            onApply(uploads)
        } catch {
            presentationState.showFailureMessage(error.localizedDescription)
        }
    }

    static func isEffectivelyFullFrame(_ rect: CGRect, tolerance: CGFloat = 0.02) -> Bool {
        rect.minX <= tolerance
            && rect.minY <= tolerance
            && rect.maxX >= 1 - tolerance
            && rect.maxY >= 1 - tolerance
    }
}

private struct GoodsCropAutoDetectPill: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(MegrumTheme.sky)
                .frame(width: 8, height: 8)
            Text("AIが枠を自動で配置しました")
                .font(.caption.weight(.black))
                .foregroundStyle(MegrumTheme.ink)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 8)
        .background(MegrumTheme.sky.opacity(0.24), in: Capsule())
    }
}

