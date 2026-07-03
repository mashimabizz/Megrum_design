import Foundation
import MegrumCore

actor PreviewMeguriMessageMediaStore {
    static let shared = PreviewMeguriMessageMediaStore()

    func storePhoto(_ input: MeguriPhotoMessageCreateInput) throws -> URL {
        let directory = try imageDirectory()
        let filename = [
            input.senderID.uuidString.lowercased(),
            "meguri-message",
            UUID().uuidString.lowercased()
        ].joined(separator: "-")
        let fileURL = directory
            .appendingPathComponent(filename)
            .appendingPathExtension(fileExtension(for: input.imageContentType))
        try input.imageData.write(to: fileURL, options: .atomic)
        return fileURL
    }

    private func imageDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("megrum-preview-meguri-message-media", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func fileExtension(for contentType: String) -> String {
        switch contentType.lowercased() {
        case "image/png":
            "png"
        case "image/webp":
            "webp"
        default:
            "jpg"
        }
    }
}
