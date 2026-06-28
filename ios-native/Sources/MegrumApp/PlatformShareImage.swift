import SwiftUI

#if os(iOS)
import UIKit

func PlatformShareImage(data: Data) -> Image? {
    guard let image = UIImage(data: data) else {
        return nil
    }
    return Image(uiImage: image)
}
#elseif os(macOS)
import AppKit

func PlatformShareImage(data: Data) -> Image? {
    guard let image = NSImage(data: data) else {
        return nil
    }
    return Image(nsImage: image)
}
#endif
