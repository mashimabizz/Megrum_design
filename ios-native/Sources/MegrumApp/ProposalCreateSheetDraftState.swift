import Foundation
import MegrumCore

struct ProposalCreateSheetDraftState {
    var selectedSenderGoodsID: UUID?
    var exchangeMethod: ExchangeMethod
    var selectedConditionTags: Set<String>
    var message: String
    var meetupStartAt: Date
    var meetupEndAt: Date
    var meetupPlaceName: String
    var meetupLatitudeText: String
    var meetupLongitudeText: String

    init(now: Date = Date()) {
        selectedSenderGoodsID = nil
        exchangeMethod = .mail
        selectedConditionTags = []
        message = ""
        meetupStartAt = now
        meetupEndAt = now.addingTimeInterval(30 * 60)
        meetupPlaceName = ""
        meetupLatitudeText = ""
        meetupLongitudeText = ""
    }

    mutating func toggleConditionTag(_ tag: String) {
        if selectedConditionTags.contains(tag) {
            selectedConditionTags.remove(tag)
        } else {
            selectedConditionTags.insert(tag)
        }
    }

    mutating func pruneConditionTags(to options: [String]) {
        selectedConditionTags = selectedConditionTags.intersection(Set(options))
    }

    func orderedConditionTags(options: [String]) -> [String] {
        options.filter { selectedConditionTags.contains($0) }
    }

    mutating func boundMeetupEnd(after startAt: Date) {
        if meetupEndAt <= startAt {
            meetupEndAt = startAt.addingTimeInterval(30 * 60)
        }
    }

    mutating func applyCurrentLocation(
        _ coordinate: MegrumLocationCoordinate?,
        requiresMeetupBeforeSubmit: Bool
    ) {
        guard let coordinate, requiresMeetupBeforeSubmit else {
            return
        }
        if meetupPlaceName.isBlank {
            meetupPlaceName = "現在地"
        }
        if meetupLatitudeText.isBlank {
            meetupLatitudeText = ProposalMeetupMapDraft.coordinateText(coordinate.latitude)
        }
        if meetupLongitudeText.isBlank {
            meetupLongitudeText = ProposalMeetupMapDraft.coordinateText(coordinate.longitude)
        }
    }

    var meetupInput: ProposalMeetupInput? {
        guard
            let latitude = ProposalMeetupMapDraft.coordinateValue(from: meetupLatitudeText),
            let longitude = ProposalMeetupMapDraft.coordinateValue(from: meetupLongitudeText)
        else {
            return nil
        }
        let input = ProposalMeetupInput(
            startAt: meetupStartAt,
            endAt: meetupEndAt,
            placeName: meetupPlaceName,
            latitude: latitude,
            longitude: longitude
        )
        return input.isValid ? input : nil
    }
}
