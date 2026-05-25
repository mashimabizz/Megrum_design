import CoreImage
import ExpoModulesCore
import UIKit
import Vision

private enum TradingCardCropperError: LocalizedError {
  case imageLoadFailed
  case cgImageUnavailable
  case invalidFrame
  case cropFailed
  case writeFailed

  var errorDescription: String? {
    switch self {
    case .imageLoadFailed:
      return "画像を読み込めませんでした。"
    case .cgImageUnavailable:
      return "画像データを処理できませんでした。"
    case .invalidFrame:
      return "カード枠の座標が不正です。"
    case .cropFailed:
      return "カード画像の切り出しに失敗しました。"
    case .writeFailed:
      return "切り出し画像を保存できませんでした。"
    }
  }
}

private enum RectangleDetectionConfig {
  static let maximumObservations = 30
  static let minimumAspectRatio: VNAspectRatio = 0.6
  static let maximumAspectRatio: VNAspectRatio = 0.85
  static let minimumSize: Float = 0.05
  static let minimumConfidence: VNConfidence = 0.6
  static let quadratureTolerance: VNDegrees = 20
}

public final class TradingCardCropperModule: Module {
  private let context = CIContext(options: [.useSoftwareRenderer: false])

  public func definition() -> ModuleDefinition {
    Name("TradingCardCropper")

    AsyncFunction("detectCardsAsync") { (imagePath: String) async throws -> [[String: Any]] in
      let image = try self.loadNormalizedImage(imagePath)
      guard let cgImage = image.cgImage else {
        throw TradingCardCropperError.cgImageUnavailable
      }

      let request = VNDetectRectanglesRequest()
      request.maximumObservations = RectangleDetectionConfig.maximumObservations
      request.minimumAspectRatio = RectangleDetectionConfig.minimumAspectRatio
      request.maximumAspectRatio = RectangleDetectionConfig.maximumAspectRatio
      request.minimumSize = RectangleDetectionConfig.minimumSize
      request.minimumConfidence = RectangleDetectionConfig.minimumConfidence
      request.quadratureTolerance = RectangleDetectionConfig.quadratureTolerance

      let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
      try handler.perform([request])

      let observations = (request.results ?? []).sorted { lhs, rhs in
        let leftCenter = self.normalizedTopLeftCenter(lhs)
        let rightCenter = self.normalizedTopLeftCenter(rhs)
        if abs(leftCenter.y - rightCenter.y) > 0.05 {
          return leftCenter.y < rightCenter.y
        }
        return leftCenter.x < rightCenter.x
      }

      return observations.map { observation in
        [
          "topLeft": self.visionPointToTopLeft(observation.topLeft),
          "topRight": self.visionPointToTopLeft(observation.topRight),
          "bottomRight": self.visionPointToTopLeft(observation.bottomRight),
          "bottomLeft": self.visionPointToTopLeft(observation.bottomLeft)
        ]
      }
    }

    AsyncFunction("cropCardsAsync") { (imagePath: String, frames: [[String: Any]]) async throws -> [String] in
      let image = try self.loadNormalizedImage(imagePath)
      guard let cgImage = image.cgImage else {
        throw TradingCardCropperError.cgImageUnavailable
      }
      let ciImage = CIImage(cgImage: cgImage)
      let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
      let outputDirectory = try self.makeOutputDirectory()

      return try frames.enumerated().map { index, frame in
        let topLeft = try self.parsePoint(frame["topLeft"])
        let topRight = try self.parsePoint(frame["topRight"])
        let bottomRight = try self.parsePoint(frame["bottomRight"])
        let bottomLeft = try self.parsePoint(frame["bottomLeft"])

        guard let filter = CIFilter(name: "CIPerspectiveCorrection") else {
          throw TradingCardCropperError.cropFailed
        }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgPoint: self.uiPointToCI(topLeft, imageSize: imageSize)), forKey: "inputTopLeft")
        filter.setValue(CIVector(cgPoint: self.uiPointToCI(topRight, imageSize: imageSize)), forKey: "inputTopRight")
        filter.setValue(CIVector(cgPoint: self.uiPointToCI(bottomRight, imageSize: imageSize)), forKey: "inputBottomRight")
        filter.setValue(CIVector(cgPoint: self.uiPointToCI(bottomLeft, imageSize: imageSize)), forKey: "inputBottomLeft")

        guard let outputImage = filter.outputImage,
              let outputCGImage = self.context.createCGImage(outputImage, from: outputImage.extent)
        else {
          throw TradingCardCropperError.cropFailed
        }

        let cropped = UIImage(cgImage: outputCGImage, scale: 1, orientation: .up)
        return try self.writeImage(cropped, directory: outputDirectory, suffix: "crop-\(index + 1)")
      }
    }

    AsyncFunction("rotateImagesAsync") { (imagePaths: [String], rotations: [Int]) async throws -> [String] in
      let outputDirectory = try self.makeOutputDirectory()
      return try imagePaths.enumerated().map { index, imagePath in
        let turns = self.normalizedQuarterTurns(rotations.indices.contains(index) ? rotations[index] : 0)
        let image = try self.loadNormalizedImage(imagePath)
        let rotated = turns == 0 ? image : self.rotateImage(image, quarterTurns: turns)
        return try self.writeImage(rotated, directory: outputDirectory, suffix: "rotate-\(index + 1)")
      }
    }
  }

  private func loadNormalizedImage(_ imagePath: String) throws -> UIImage {
    let url = fileURL(from: imagePath)
    guard let image = UIImage(contentsOfFile: url.path) else {
      throw TradingCardCropperError.imageLoadFailed
    }
    if image.imageOrientation == .up {
      return image
    }
    let format = UIGraphicsImageRendererFormat()
    format.scale = image.scale
    let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
    return renderer.image { _ in
      image.draw(in: CGRect(origin: .zero, size: image.size))
    }
  }

  private func fileURL(from rawPath: String) -> URL {
    if let url = URL(string: rawPath), url.isFileURL {
      return url
    }
    return URL(fileURLWithPath: rawPath)
  }

  private func makeOutputDirectory() throws -> URL {
    let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    let directory = caches.appendingPathComponent("trading-card-crops", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory
  }

  private func writeImage(_ image: UIImage, directory: URL, suffix: String) throws -> String {
    guard let data = image.jpegData(compressionQuality: 0.92) else {
      throw TradingCardCropperError.writeFailed
    }
    let url = directory.appendingPathComponent("\(UUID().uuidString)-\(suffix).jpg")
    try data.write(to: url, options: [.atomic])
    return url.absoluteString
  }

  private func parsePoint(_ value: Any?) throws -> CGPoint {
    guard let dictionary = value as? [String: Any],
          let x = dictionary["x"] as? Double,
          let y = dictionary["y"] as? Double
    else {
      throw TradingCardCropperError.invalidFrame
    }
    return CGPoint(x: max(0, min(1, x)), y: max(0, min(1, y)))
  }

  private func uiPointToCI(_ point: CGPoint, imageSize: CGSize) -> CGPoint {
    CGPoint(
      x: point.x * imageSize.width,
      y: (1 - point.y) * imageSize.height
    )
  }

  private func visionPointToTopLeft(_ point: CGPoint) -> [String: Double] {
    [
      "x": Double(max(0, min(1, point.x))),
      "y": Double(max(0, min(1, 1 - point.y)))
    ]
  }

  private func normalizedTopLeftCenter(_ observation: VNRectangleObservation) -> CGPoint {
    let x = (observation.topLeft.x + observation.topRight.x + observation.bottomRight.x + observation.bottomLeft.x) / 4
    let yVision = (observation.topLeft.y + observation.topRight.y + observation.bottomRight.y + observation.bottomLeft.y) / 4
    return CGPoint(x: x, y: 1 - yVision)
  }

  private func normalizedQuarterTurns(_ raw: Int) -> Int {
    let mod = raw % 4
    return mod >= 0 ? mod : mod + 4
  }

  private func rotateImage(_ image: UIImage, quarterTurns: Int) -> UIImage {
    let turns = normalizedQuarterTurns(quarterTurns)
    if turns == 0 {
      return image
    }

    let newSize = turns == 2
      ? image.size
      : CGSize(width: image.size.height, height: image.size.width)
    let renderer = UIGraphicsImageRenderer(size: newSize)
    return renderer.image { context in
      let cgContext = context.cgContext
      cgContext.translateBy(x: newSize.width / 2, y: newSize.height / 2)
      cgContext.rotate(by: CGFloat(turns) * .pi / 2)
      image.draw(in: CGRect(
        x: -image.size.width / 2,
        y: -image.size.height / 2,
        width: image.size.width,
        height: image.size.height
      ))
    }
  }
}
