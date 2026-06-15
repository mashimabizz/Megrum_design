import Foundation

enum TradeAmountFormatter {
    static func yen(_ amount: Int) -> String {
        NumberFormatter.localizedString(from: NSNumber(value: amount), number: .decimal)
    }

    static func fixedPrice(amount: Int?, fallback: String = "定価") -> String {
        guard let amount else {
            return fallback
        }
        return "定価 \(yen(amount))円"
    }

    static func compactYen(_ amount: Int) -> String {
        "¥\(yen(amount))"
    }
}
