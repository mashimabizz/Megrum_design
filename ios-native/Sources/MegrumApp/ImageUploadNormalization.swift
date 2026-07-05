import Foundation
import MegrumCore
#if canImport(UIKit)
import UIKit
#endif

let goodsEditorMaxPhotoUploadBytes = 10 * 1_024 * 1_024
private let photoUploadMaxPixelDimension: CGFloat = 2_048
private let chatPhotoUploadMaxPixelDimension: CGFloat = 1_600
private let photoUploadTargetBytes = 2_500_000
private let chatPhotoUploadTargetBytes = 1_800_000

#if canImport(UIKit)
private let imageUploadJPEGCompressionQualities: [CGFloat] = [
    0.84,
    0.78,
    0.72,
    0.66,
    0.60,
    0.54,
    0.48,
    0.42,
]
#endif

func normalizedChatPhotoUpload(from data: Data) -> GoodsPhotoUpload {
    #if canImport(UIKit)
    if let upload = normalizedImageUpload(
        from: data,
        detectedOriginalContentType: detectedChatDisplayImageContentType(data),
        maxUploadBytes: SupabaseChatPhotoStorage.maxUploadBytes,
        maxPixelDimension: chatPhotoUploadMaxPixelDimension,
        targetBytes: chatPhotoUploadTargetBytes
    ) {
        return upload
    }
    #endif

    if let contentType = detectedChatDisplayImageContentType(data),
       data.count <= SupabaseChatPhotoStorage.maxUploadBytes {
        return GoodsPhotoUpload(data: data, contentType: contentType)
    }

    #if canImport(UIKit)
    if let image = UIImage(data: data),
       let jpegData = image.jpegData(compressionQuality: 0.88) {
        return GoodsPhotoUpload(data: jpegData, contentType: "image/jpeg")
    }
    #endif

    return GoodsPhotoUpload(data: data, contentType: "image/jpeg")
}

func normalizedPhotoUpload(from data: Data) -> GoodsPhotoUpload {
    #if canImport(UIKit)
    if let upload = normalizedImageUpload(
        from: data,
        detectedOriginalContentType: detectedSupportedImageContentType(data),
        maxUploadBytes: goodsEditorMaxPhotoUploadBytes,
        maxPixelDimension: photoUploadMaxPixelDimension,
        targetBytes: photoUploadTargetBytes
    ) {
        return upload
    }
    #endif

    if let contentType = detectedSupportedImageContentType(data),
       data.count <= goodsEditorMaxPhotoUploadBytes {
        return GoodsPhotoUpload(data: data, contentType: contentType)
    }

    #if canImport(UIKit)
    if let image = UIImage(data: data),
       let jpegData = image.jpegData(compressionQuality: 0.88) {
        return GoodsPhotoUpload(data: jpegData, contentType: "image/jpeg")
    }
    #endif

    return GoodsPhotoUpload(data: data, contentType: "image/jpeg")
}

#if canImport(UIKit)
func normalizedCameraPhotoData(from image: UIImage) -> Data? {
    compressedJPEGData(
        from: image,
        maxPixelDimension: photoUploadMaxPixelDimension,
        targetBytes: photoUploadTargetBytes
    )
}
#endif

func goodsEditorPhotoUploadError(for upload: GoodsPhotoUpload) -> String? {
    upload.data.count > goodsEditorMaxPhotoUploadBytes ? "写真は10MB以下にしてください" : nil
}

func inferredPhotoMessageContentType(from data: Data) -> String {
    let bytes = [UInt8](data.prefix(12))
    if bytes.count >= 8,
       bytes[0] == 0x89,
       bytes[1] == 0x50,
       bytes[2] == 0x4E,
       bytes[3] == 0x47 {
        return "image/png"
    }
    if bytes.count >= 12,
       bytes[0] == 0x52,
       bytes[1] == 0x49,
       bytes[2] == 0x46,
       bytes[3] == 0x46,
       bytes[8] == 0x57,
       bytes[9] == 0x45,
       bytes[10] == 0x42,
       bytes[11] == 0x50 {
        return "image/webp"
    }
    return "image/jpeg"
}

func detectedSupportedImageContentType(_ data: Data) -> String? {
    if data.starts(withBytes: [0xFF, 0xD8, 0xFF]) {
        return "image/jpeg"
    }
    if data.starts(withBytes: [0x89, 0x50, 0x4E, 0x47]) {
        return "image/png"
    }
    if data.starts(withBytes: [0x47, 0x49, 0x46]) {
        return "image/gif"
    }
    if data.count >= 12 {
        let signature = String(data: Data(data[8..<12]), encoding: .ascii)
        if signature == "WEBP" {
            return "image/webp"
        }
    }
    return nil
}

private func detectedChatDisplayImageContentType(_ data: Data) -> String? {
    guard let contentType = detectedSupportedImageContentType(data) else {
        return nil
    }
    return contentType == "image/gif" ? nil : contentType
}

#if canImport(UIKit)
private func normalizedImageUpload(
    from data: Data,
    detectedOriginalContentType: String?,
    maxUploadBytes: Int,
    maxPixelDimension: CGFloat,
    targetBytes: Int
) -> GoodsPhotoUpload? {
    guard let image = UIImage(data: data),
          image.orientedPixelSize.width > 0,
          image.orientedPixelSize.height > 0,
          let jpegData = compressedJPEGData(
              from: image,
              maxPixelDimension: maxPixelDimension,
              targetBytes: min(targetBytes, maxUploadBytes)
          )
    else {
        return nil
    }

    let originalCanBeUploaded = detectedOriginalContentType != nil && data.count <= maxUploadBytes
    let imageNeedsResize = image.orientedPixelSize.maxSide > maxPixelDimension
    let jpegIsSmaller = jpegData.count < data.count

    if !originalCanBeUploaded || imageNeedsResize || jpegIsSmaller {
        return GoodsPhotoUpload(data: jpegData, contentType: "image/jpeg")
    }

    if let detectedOriginalContentType {
        return GoodsPhotoUpload(data: data, contentType: detectedOriginalContentType)
    }
    return GoodsPhotoUpload(data: jpegData, contentType: "image/jpeg")
}

private func compressedJPEGData(
    from image: UIImage,
    maxPixelDimension: CGFloat,
    targetBytes: Int
) -> Data? {
    var fallbackData: Data?
    for pixelDimension in compressionPixelDimensions(upTo: maxPixelDimension) {
        let resizedImage = image.resizedForUpload(maxPixelDimension: pixelDimension)
        for quality in imageUploadJPEGCompressionQualities {
            guard let data = resizedImage.jpegData(compressionQuality: quality) else {
                continue
            }
            fallbackData = data
            if data.count <= targetBytes {
                return data
            }
        }
    }
    return fallbackData
}

private func compressionPixelDimensions(upTo maxPixelDimension: CGFloat) -> [CGFloat] {
    [maxPixelDimension, 1_600, 1_280, 1_024]
        .filter { $0 <= maxPixelDimension }
        .reduce(into: [CGFloat]()) { dimensions, value in
            guard !dimensions.contains(value) else {
                return
            }
            dimensions.append(value)
        }
}

private extension UIImage {
    var orientedPixelSize: CGSize {
        if let cgImage {
            let rawSize = CGSize(width: cgImage.width, height: cgImage.height)
            switch imageOrientation {
            case .left, .leftMirrored, .right, .rightMirrored:
                return CGSize(width: rawSize.height, height: rawSize.width)
            default:
                return rawSize
            }
        }
        return CGSize(width: size.width * scale, height: size.height * scale)
    }

    func resizedForUpload(maxPixelDimension: CGFloat) -> UIImage {
        let sourcePixelSize = orientedPixelSize
        guard sourcePixelSize.maxSide > maxPixelDimension || imageOrientation != .up else {
            return self
        }

        let scaleRatio = maxPixelDimension / sourcePixelSize.maxSide
        let targetSize = CGSize(
            width: (sourcePixelSize.width * scaleRatio).rounded(),
            height: (sourcePixelSize.height * scaleRatio).rounded()
        )
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: targetSize, format: format).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: targetSize))
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}

private extension CGSize {
    var maxSide: CGFloat {
        max(width, height)
    }
}
#endif

private extension Data {
    func starts(withBytes bytes: [UInt8]) -> Bool {
        count >= bytes.count && Array(prefix(bytes.count)) == bytes
    }
}
