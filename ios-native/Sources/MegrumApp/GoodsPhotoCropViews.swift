import CoreGraphics
import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

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

    @State private var frames: [TradingCardCropFrame]
    @State private var selectedFrameID: UUID?
    @State private var message: String?

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
        _frames = State(initialValue: session.initialFrames)
        _selectedFrameID = State(initialValue: session.initialFrames.first?.id)
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
                        frames: $frames,
                        selectedFrameID: $selectedFrameID
                    )
                    .frame(height: 430)

                    GoodsCropPreviewStrip(
                        imageData: session.upload.data,
                        frames: frames,
                        selectedFrameID: $selectedFrameID,
                        onDelete: deleteFrame
                    )

                    if let message {
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
                    .disabled(frames.isEmpty)
                    .opacity(frames.isEmpty ? 0.45 : 1)
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
                        .disabled(frames.isEmpty)
                }
            }
        }
    }

    private func deleteFrame(_ frameID: UUID) {
        frames.removeAll { $0.id == frameID }
        if selectedFrameID == frameID {
            selectedFrameID = frames.first?.id
        }
    }

    private func clearFrames() {
        frames = []
        selectedFrameID = nil
    }

    private func applyCrops() {
        do {
            let results = try TradingCardBulkRecognizer.cropFramesSynchronously(frames, in: session.upload.data)
            let uploads = results.map(\.upload)
            guard !uploads.isEmpty else {
                message = "切り取り枠を追加してください。"
                return
            }
            onApply(uploads)
        } catch {
            message = error.localizedDescription
        }
    }
}

private struct GoodsCropFrameCanvas: View {
    var imageData: Data
    @Binding var frames: [TradingCardCropFrame]
    @Binding var selectedFrameID: UUID?

    @State private var dragStart: CGPoint?
    @State private var draftRect: CGRect?

    private var imageSize: CGSize? {
        platformImageSize(from: imageData)
    }

    var body: some View {
        GeometryReader { proxy in
            let displayRect = fittedImageRect(
                imageSize: imageSize ?? CGSize(width: 1, height: 1),
                containerSize: proxy.size
            )

            ZStack {
                Color.black.opacity(0.06)

                GoodsCropSourceImage(data: imageData)
                    .frame(width: displayRect.width, height: displayRect.height)
                    .position(x: displayRect.midX, y: displayRect.midY)

                ForEach(frames) { frame in
                    let rect = screenRect(for: frame.rect, in: displayRect)
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(frame.id == selectedFrameID ? Color.yellow : Color.yellow.opacity(0.72), lineWidth: frame.id == selectedFrameID ? 3 : 2)
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedFrameID = frame.id
                        }
                }

                if let draftRect {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(Color.yellow.opacity(0.86), style: StrokeStyle(lineWidth: 2, dash: [7, 5]))
                        .frame(width: draftRect.width, height: draftRect.height)
                        .position(x: draftRect.midX, y: draftRect.midY)
                }

                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(dragGesture(in: displayRect))
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(.white.opacity(0.58), lineWidth: 1)
            }
        }
    }

    private func dragGesture(in displayRect: CGRect) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                let start = dragStart ?? clamped(value.startLocation, to: displayRect)
                dragStart = start
                let current = clamped(value.location, to: displayRect)
                draftRect = rect(from: start, to: current)
            }
            .onEnded { value in
                defer {
                    dragStart = nil
                    draftRect = nil
                }
                guard let start = dragStart else {
                    return
                }
                let current = clamped(value.location, to: displayRect)
                let screen = rect(from: start, to: current)
                guard screen.width >= 28, screen.height >= 28 else {
                    return
                }
                let normalized = normalizedRect(screen, in: displayRect)
                let frame = TradingCardCropFrame(rect: normalized)
                frames.append(frame)
                selectedFrameID = frame.id
            }
    }
}

private struct GoodsCropSourceImage: View {
    var data: Data

    var body: some View {
        #if canImport(UIKit)
        if let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else {
            GoodsCreatePhotoPreviewPlaceholder()
        }
        #elseif canImport(AppKit)
        if let image = NSImage(data: data) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
        } else {
            GoodsCreatePhotoPreviewPlaceholder()
        }
        #else
        GoodsCreatePhotoPreviewPlaceholder()
        #endif
    }
}

private struct GoodsCropPreviewStrip: View {
    var imageData: Data
    var frames: [TradingCardCropFrame]
    @Binding var selectedFrameID: UUID?
    var onDelete: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("切り取りプレビュー")
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(MegrumTheme.ink)
                Spacer()
                Text("\(frames.count)件")
                    .font(.caption.weight(.black))
                    .foregroundStyle(MegrumTheme.lavender)
            }

            if frames.isEmpty {
                Text("写真上をドラッグすると、ここに切り取り候補が追加されます。")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(MegrumTheme.muted)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.70), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(frames) { frame in
                            GoodsCropPreviewTile(
                                imageData: imageData,
                                frame: frame,
                                isSelected: selectedFrameID == frame.id,
                                onSelect: { selectedFrameID = frame.id },
                                onDelete: { onDelete(frame.id) }
                            )
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.48), lineWidth: 1)
        }
    }
}

private struct GoodsCropPreviewTile: View {
    var imageData: Data
    var frame: TradingCardCropFrame
    var isSelected: Bool
    var onSelect: () -> Void
    var onDelete: () -> Void

    private var previewData: Data? {
        guard let result = try? TradingCardBulkRecognizer.cropFramesSynchronously([frame], in: imageData),
              let first = result.first
        else {
            return nil
        }
        return first.data
    }

    var body: some View {
        Button(action: onSelect) {
            ZStack(alignment: .topTrailing) {
                if let previewData {
                    GoodsCreatePhotoPreview(data: previewData)
                } else {
                    GoodsCreatePhotoPreviewPlaceholder()
                }
            }
            .frame(width: 86, height: 112)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isSelected ? Color.yellow : .white.opacity(0.60), lineWidth: isSelected ? 3 : 1)
            }
            .overlay(alignment: .topTrailing) {
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(.black.opacity(0.45), in: Circle())
                }
                .buttonStyle(.plain)
                .padding(6)
            }
        }
        .buttonStyle(.plain)
    }
}

private func platformImageSize(from data: Data) -> CGSize? {
    #if canImport(UIKit)
    UIImage(data: data).map { CGSize(width: $0.size.width, height: $0.size.height) }
    #elseif canImport(AppKit)
    NSImage(data: data).map { CGSize(width: $0.size.width, height: $0.size.height) }
    #else
    nil
    #endif
}

private func fittedImageRect(imageSize: CGSize, containerSize: CGSize) -> CGRect {
    guard imageSize.width > 0, imageSize.height > 0, containerSize.width > 0, containerSize.height > 0 else {
        return CGRect(origin: .zero, size: containerSize)
    }
    let scale = min(containerSize.width / imageSize.width, containerSize.height / imageSize.height)
    let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
    return CGRect(
        x: (containerSize.width - size.width) / 2,
        y: (containerSize.height - size.height) / 2,
        width: size.width,
        height: size.height
    )
}

private func screenRect(for normalizedRect: CGRect, in displayRect: CGRect) -> CGRect {
    CGRect(
        x: displayRect.minX + normalizedRect.minX * displayRect.width,
        y: displayRect.minY + normalizedRect.minY * displayRect.height,
        width: normalizedRect.width * displayRect.width,
        height: normalizedRect.height * displayRect.height
    )
}

private func normalizedRect(_ screenRect: CGRect, in displayRect: CGRect) -> CGRect {
    CGRect(
        x: (screenRect.minX - displayRect.minX) / displayRect.width,
        y: (screenRect.minY - displayRect.minY) / displayRect.height,
        width: screenRect.width / displayRect.width,
        height: screenRect.height / displayRect.height
    )
}

private func rect(from start: CGPoint, to end: CGPoint) -> CGRect {
    CGRect(
        x: min(start.x, end.x),
        y: min(start.y, end.y),
        width: abs(end.x - start.x),
        height: abs(end.y - start.y)
    )
}

private func clamped(_ point: CGPoint, to rect: CGRect) -> CGPoint {
    CGPoint(
        x: min(max(point.x, rect.minX), rect.maxX),
        y: min(max(point.y, rect.minY), rect.maxY)
    )
}
