import Foundation
import MegrumCore

enum HomeLocalLocationLabel {
    static let resolvingText = "住所を確認中"
    static let unresolvedText = "現在地を取得済み"

    static func coordinateText(latitude: Double, longitude: Double) -> String {
        unresolvedText
    }

    static func coordinateText(_ coordinate: MegrumLocationCoordinate) -> String {
        coordinateText(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }

    static func isCoordinateBackedText(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed == resolvingText || trimmed == unresolvedText {
            return true
        }
        return coordinate(in: trimmed) != nil
    }

    static func coordinate(in text: String) -> MegrumLocationCoordinate? {
        let normalized = text
            .replacingOccurrences(of: "，", with: ",")
            .replacingOccurrences(of: "、", with: ",")
            .replacingOccurrences(of: "：", with: ":")
        let commaSeparatedPattern = #"-?\d{1,2}(?:\.\d+)?\s*,\s*-?\d{1,3}(?:\.\d+)?"#
        if let range = normalized.range(of: commaSeparatedPattern, options: .regularExpression) {
            let parts = normalized[range]
                .split(separator: ",", maxSplits: 1)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            if parts.count == 2,
               let latitude = Double(parts[0]),
               let longitude = Double(parts[1]),
               HomeLocalCoordinateStorageCodec.isValid(latitude: latitude, longitude: longitude) {
                return MegrumLocationCoordinate(latitude: latitude, longitude: longitude)
            }
        }

        guard normalized.localizedCaseInsensitiveContains("lat")
            || normalized.localizedCaseInsensitiveContains("lng")
            || normalized.contains("緯度")
            || normalized.contains("経度")
        else {
            return nil
        }
        let decimalPattern = #"-?\d{1,3}\.\d+"#
        let matches = normalized.matches(forRegularExpression: decimalPattern)
        guard matches.count >= 2,
              let latitude = Double(matches[0]),
              let longitude = Double(matches[1]),
              HomeLocalCoordinateStorageCodec.isValid(latitude: latitude, longitude: longitude)
        else {
            return nil
        }
        return MegrumLocationCoordinate(latitude: latitude, longitude: longitude)
    }
}

enum HomeLocalCoordinateStorageCodec {
    static func decode(latitudeText: String, longitudeText: String) -> MegrumLocationCoordinate? {
        guard let latitude = Double(latitudeText),
              let longitude = Double(longitudeText),
              isValid(latitude: latitude, longitude: longitude)
        else {
            return nil
        }
        return MegrumLocationCoordinate(latitude: latitude, longitude: longitude)
    }

    static func latitudeText(_ coordinate: MegrumLocationCoordinate?) -> String {
        coordinate.map { String(format: "%.8f", locale: Locale(identifier: "en_US_POSIX"), $0.latitude) } ?? ""
    }

    static func longitudeText(_ coordinate: MegrumLocationCoordinate?) -> String {
        coordinate.map { String(format: "%.8f", locale: Locale(identifier: "en_US_POSIX"), $0.longitude) } ?? ""
    }

    static func isValid(latitude: Double, longitude: Double) -> Bool {
        latitude.isFinite
            && longitude.isFinite
            && (-90...90).contains(latitude)
            && (-180...180).contains(longitude)
    }
}

private extension String {
    func matches(forRegularExpression pattern: String) -> [String] {
        guard let expression = try? NSRegularExpression(pattern: pattern) else {
            return []
        }
        let fullRange = NSRange(startIndex..<endIndex, in: self)
        return expression.matches(in: self, range: fullRange).compactMap { match in
            Range(match.range, in: self).map { String(self[$0]) }
        }
    }
}
