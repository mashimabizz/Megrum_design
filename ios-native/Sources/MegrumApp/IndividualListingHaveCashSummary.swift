import Foundation

struct IndividualListingHaveCashSummary: Equatable {
    var pricingMode: IndividualListingCashPricingMode
    var amount: Int?

    var storageLine: String {
        let value = pricingMode == .specifiedAmount ? "¥\(max(0, amount ?? 0))" : "定価"
        return "譲る金額: \(value)"
    }

    static func extract(from note: String?) -> (summary: IndividualListingHaveCashSummary?, remainingNote: String?) {
        guard let note else {
            return (nil, nil)
        }
        let lines = note
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard let summaryIndex = lines.firstIndex(where: { $0.hasPrefix("譲る金額:") }) else {
            let remaining = note.trimmingCharacters(in: .whitespacesAndNewlines)
            return (nil, remaining.isEmpty ? nil : remaining)
        }

        let summary = parse(lines[summaryIndex])
        let remainingLines = lines
            .enumerated()
            .filter { $0.offset != summaryIndex && !$0.element.isEmpty }
            .map(\.element)
        let remaining = remainingLines.joined(separator: "\n")
        return (summary, remaining.isEmpty ? nil : remaining)
    }

    private static func parse(_ line: String) -> IndividualListingHaveCashSummary? {
        let rawValue = line
            .dropFirst("譲る金額:".count)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !rawValue.isEmpty else {
            return IndividualListingHaveCashSummary(pricingMode: .listPrice, amount: nil)
        }
        let normalized = rawValue
            .replacingOccurrences(of: "¥", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "円", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let amount = Int(normalized), amount > 0 {
            return IndividualListingHaveCashSummary(pricingMode: .specifiedAmount, amount: amount)
        }
        return IndividualListingHaveCashSummary(pricingMode: .listPrice, amount: nil)
    }
}
