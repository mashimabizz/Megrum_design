import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct LocalURLImage<Placeholder: View>: View {
    var url: URL
    var contentMode: ContentMode
    @ViewBuilder var placeholder: () -> Placeholder

    var body: some View {
        #if canImport(UIKit)
        if let image = platformImage {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: contentMode)
        } else {
            placeholder()
        }
        #elseif canImport(AppKit)
        if let image = platformImage {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: contentMode)
        } else {
            placeholder()
        }
        #else
        placeholder()
        #endif
    }

    #if canImport(UIKit)
    private var platformImage: UIImage? {
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        return UIImage(data: data)
    }
    #elseif canImport(AppKit)
    private var platformImage: NSImage? {
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        return NSImage(data: data)
    }
    #endif
}
