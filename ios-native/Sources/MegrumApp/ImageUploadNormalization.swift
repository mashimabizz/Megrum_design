import Foundation
import MegrumCore
#if canImport(UIKit)
import UIKit
#endif

let goodsEditorMaxPhotoUploadBytes = 10 * 1_024 * 1_024

func normalizedPhotoUpload(from data: Data) -> GoodsPhotoUpload {
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

private extension Data {
    func starts(withBytes bytes: [UInt8]) -> Bool {
        count >= bytes.count && Array(prefix(bytes.count)) == bytes
    }
}
