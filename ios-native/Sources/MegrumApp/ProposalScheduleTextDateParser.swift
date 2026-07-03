import Foundation

enum ProposalScheduleTextDateParser {
    static func date(from text: String, now: Date = .now) -> Date? {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "　", with: " ")
        guard !normalized.isEmpty,
              normalized != IndividualListingExchangeSummary.defaultLocalSchedule
        else {
            return nil
        }

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(
                    in: normalized,
                    range: NSRange(normalized.startIndex..., in: normalized)
                  ),
                  let monthRange = Range(match.range(withName: "month"), in: normalized),
                  let dayRange = Range(match.range(withName: "day"), in: normalized),
                  let month = Int(normalized[monthRange]),
                  let day = Int(normalized[dayRange])
            else {
                continue
            }
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current
            let currentYear = calendar.component(.year, from: now)
            return calendar.date(from: DateComponents(year: currentYear, month: month, day: day, hour: 12))
        }
        return nil
    }

    private static let patterns = [
        #"(?<month>\d{1,2})月(?<day>\d{1,2})日"#,
        #"(?<month>\d{1,2})/(?<day>\d{1,2})"#,
        #"(?<month>\d{1,2})\.(?<day>\d{1,2})"#
    ]
}
