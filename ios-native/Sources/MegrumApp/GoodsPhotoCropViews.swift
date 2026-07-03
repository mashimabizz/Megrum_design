import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct GoodsPhotoCropSession: Identifiable, Equatable {
    enum Source: Equatable {
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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("写真上をドラッグして切り取り枠を追加できます。不要な枠は下のプレビューから削除できます。")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(MegrumTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)

                    GoodsCropFrameCanvas(
                        imageData: session.upload.data,
                        frames: $presentationState.frames,
                        selectedFrameID: $presentationState.selectedFrameID
                    )
                    .frame(height: 430)

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
                        Text("この切り取りで追加")
                            .font(.headline.weight(.black))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(MegrumTheme.lavender, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(!presentationState.canApply)
                    .opacity(presentationState.canApply ? 1 : 0.45)
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
                    Button("全削除", action: clearFrames)
                        .disabled(!presentationState.canApply)
                }
            }
        }
    }

    private func deleteFrame(_ frameID: UUID) {
        presentationState.deleteFrame(frameID)
    }

    private func clearFrames() {
        presentationState.clearFrames()
    }

    private func applyCrops() {
        do {
            let results = try TradingCardBulkRecognizer.cropFramesSynchronously(presentationState.frames, in: session.upload.data)
            let uploads = results.map(\.upload)
            guard !uploads.isEmpty else {
                presentationState.showEmptyFrameMessage()
                return
            }
            onApply(uploads)
        } catch {
            presentationState.showFailureMessage(error.localizedDescription)
        }
    }
}
