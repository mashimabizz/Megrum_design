import Foundation
import MegrumCore
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

struct GoodsCropFrameCanvas: View {
    var imageData: Data
    @Binding var frames: [TradingCardCropFrame]
    @Binding var selectedFrameID: UUID?

    @State private var dragStart: CGPoint?
    @State private var draftRect: CGRect?

    private var imageSize: CGSize? {
        GoodsPhotoCropGeometry.platformImageSize(from: imageData)
    }

    var body: some View {
        GeometryReader { proxy in
            let displayRect = GoodsPhotoCropGeometry.fittedImageRect(
                imageSize: imageSize ?? CGSize(width: 1, height: 1),
                containerSize: proxy.size
            )

            ZStack {
                Color.black.opacity(0.06)

                GoodsCropSourceImage(data: imageData)
                    .frame(width: displayRect.width, height: displayRect.height)
                    .position(x: displayRect.midX, y: displayRect.midY)

                ForEach(frames) { frame in
                    let rect = GoodsPhotoCropGeometry.screenRect(for: frame.rect, in: displayRect)
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
                let start = dragStart ?? GoodsPhotoCropGeometry.clamped(value.startLocation, to: displayRect)
                dragStart = start
                let current = GoodsPhotoCropGeometry.clamped(value.location, to: displayRect)
                draftRect = GoodsPhotoCropGeometry.rect(from: start, to: current)
            }
            .onEnded { value in
                defer {
                    dragStart = nil
                    draftRect = nil
                }
                guard let start = dragStart else {
                    return
                }
                let current = GoodsPhotoCropGeometry.clamped(value.location, to: displayRect)
                let screen = GoodsPhotoCropGeometry.rect(from: start, to: current)
                guard screen.width >= 28, screen.height >= 28 else {
                    return
                }
                let normalized = GoodsPhotoCropGeometry.normalizedRect(screen, in: displayRect)
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
