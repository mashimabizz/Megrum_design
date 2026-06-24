import CoreGraphics
import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

enum GoodsPhotoCropGeometry {
    static func platformImageSize(from data: Data) -> CGSize? {
        #if canImport(UIKit)
        UIImage(data: data).map { CGSize(width: $0.size.width, height: $0.size.height) }
        #elseif canImport(AppKit)
        NSImage(data: data).map { CGSize(width: $0.size.width, height: $0.size.height) }
        #else
        nil
        #endif
    }

    static func fittedImageRect(imageSize: CGSize, containerSize: CGSize) -> CGRect {
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

    static func screenRect(for normalizedRect: CGRect, in displayRect: CGRect) -> CGRect {
        CGRect(
            x: displayRect.minX + normalizedRect.minX * displayRect.width,
            y: displayRect.minY + normalizedRect.minY * displayRect.height,
            width: normalizedRect.width * displayRect.width,
            height: normalizedRect.height * displayRect.height
        )
    }

    static func normalizedRect(_ screenRect: CGRect, in displayRect: CGRect) -> CGRect {
        CGRect(
            x: (screenRect.minX - displayRect.minX) / displayRect.width,
            y: (screenRect.minY - displayRect.minY) / displayRect.height,
            width: screenRect.width / displayRect.width,
            height: screenRect.height / displayRect.height
        )
    }

    static func rect(from start: CGPoint, to end: CGPoint) -> CGRect {
        CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
    }

    static func clamped(_ point: CGPoint, to rect: CGRect) -> CGPoint {
        CGPoint(
            x: min(max(point.x, rect.minX), rect.maxX),
            y: min(max(point.y, rect.minY), rect.maxY)
        )
    }
}
