import Foundation

enum TradeAmountFormatter {
    static func yen(_ amount: Int) -> String {
        NumberFormatter.localizedString(from: NSNumber(value: amount), number: .decimal)
    }

    static func cashInputText(from text: String) -> String {
        groupedDigits(cashInputDigits(from: text))
    }

    static func cashInputValue(from text: String) -> Int? {
        let digits = cashInputDigits(from: text)
        guard !digits.isEmpty, let amount = Int(digits), amount > 0 else {
            return nil
        }
        return amount
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

    private static func cashInputDigits(from text: String) -> String {
        text.compactMap { character -> String? in
            guard let value = character.wholeNumberValue, (0...9).contains(value) else {
                return nil
            }
            return String(value)
        }
        .joined()
    }

    private static func groupedDigits(_ digits: String) -> String {
        guard !digits.isEmpty else {
            return ""
        }

        let trimmedDigits = digits.drop { $0 == "0" }
        let normalizedDigits = trimmedDigits.isEmpty ? "0" : String(trimmedDigits)
        let reversedDigits = Array(normalizedDigits.reversed())
        let chunks = stride(from: 0, to: reversedDigits.count, by: 3).map { index -> String in
            let endIndex = min(index + 3, reversedDigits.count)
            return String(reversedDigits[index..<endIndex].reversed())
        }
        return chunks.reversed().joined(separator: ",")
    }
}
