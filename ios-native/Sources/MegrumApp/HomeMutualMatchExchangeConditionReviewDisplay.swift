import Foundation
import MegrumCore

enum HomeMutualMatchExchangeConditionReviewDisplay {
    static func resolvedMethodTitle(_ signals: HomeExchangeConditionSignals) -> String? {
        guard let viewerMethod = handoffDraft(from: signals.viewerExchangeMethodTitle),
              let partnerMethod = handoffDraft(from: signals.partnerExchangeMethodTitle)
        else {
            return nil
        }

        switch (viewerMethod, partnerMethod) {
        case (.both, .local), (.local, .both):
            return IndividualListingHandoffDraft.local.title
        case (.both, .mail), (.mail, .both):
            return IndividualListingHandoffDraft.mail.title
        default:
            return nil
        }
    }

    static func methodNeedsDiscussion(_ signals: HomeExchangeConditionSignals) -> Bool {
        let methods = [
            handoffDraft(from: signals.viewerExchangeMethodTitle),
            handoffDraft(from: signals.partnerExchangeMethodTitle)
        ]

        if methods.allSatisfy({ $0 == .both }) {
            return true
        }

        if methods.contains(where: { $0 == .both }) && methods.contains(where: { $0 == nil }) {
            return true
        }

        return inferredMethodTitle(signals) == IndividualListingHandoffDraft.both.title
    }

    static func methodTitle(
        _ title: String?,
        signals: HomeExchangeConditionSignals
    ) -> String {
        displayMethodTitle(title) ?? inferredMethodTitle(signals)
    }

    static func localConditionText(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty
        else {
            return nil
        }
        let parts = value
            .components(separatedBy: " / ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .compactMap { part -> String? in
                guard !part.isEmpty else {
                    return nil
                }
                let normalized = normalizedForDisplay(part)
                if normalized == normalizedForDisplay("場所相談") || normalized == normalizedForDisplay("相談") {
                    return nil
                }
                if normalized == normalizedForDisplay(IndividualListingExchangeSummary.defaultLocalSchedule) {
                    return "日程は相談"
                }
                return part
            }
        return parts.isEmpty ? nil : parts.joined(separator: " / ")
    }

    private static func handoffDraft(from title: String?) -> IndividualListingHandoffDraft? {
        guard let title = title?.trimmingCharacters(in: .whitespacesAndNewlines),
              !title.isEmpty
        else {
            return nil
        }
        return IndividualListingHandoffDraft.allCases.first { draft in
            draft.title == title || (draft == .both && title == "どちらもOK")
        }
    }

    private static func displayMethodTitle(_ title: String?) -> String? {
        guard let title = title?.trimmingCharacters(in: .whitespacesAndNewlines),
              !title.isEmpty
        else {
            return nil
        }
        return title == "どちらもOK" ? IndividualListingHandoffDraft.both.title : title
    }

    private static func inferredMethodTitle(_ signals: HomeExchangeConditionSignals) -> String {
        switch (signals.localExchangeSelected, signals.postalAcceptedByBoth) {
        case (true, true):
            return IndividualListingHandoffDraft.both.title
        case (true, false):
            return "現地交換"
        case (false, true):
            return "郵送交換"
        case (false, false):
            return "未設定"
        }
    }

    private static func normalizedForDisplay(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "　", with: "")
            .replacingOccurrences(of: " ", with: "")
            .lowercased()
    }
}
