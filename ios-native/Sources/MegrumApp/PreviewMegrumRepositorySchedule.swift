import Foundation
import MegrumCore

public extension PreviewMegrumRepository {
    func loadSchedules(for proposal: TradeProposal, startAt: Date, endAt: Date) async throws -> [PersonalSchedule] {
        guard proposal.isParticipant(NativePreviewData.viewerID) else {
            return []
        }
        let participantIDs = Set([proposal.senderID, proposal.receiverID])
        return NativePreviewData.schedules
            .filter { participantIDs.contains($0.userID) && $0.overlaps(start: startAt, end: endAt) }
            .sorted { $0.startAt < $1.startAt }
    }

    func loadPersonalSchedules(startAt: Date, endAt: Date) async throws -> [PersonalSchedule] {
        NativePreviewData.schedules
            .filter { $0.userID == NativePreviewData.viewerID && $0.overlaps(start: startAt, end: endAt) }
            .sorted { $0.startAt < $1.startAt }
    }

    func loadProfileSchedules(userID: UUID, startAt: Date, endAt: Date) async throws -> [PersonalSchedule] {
        NativePreviewData.schedules
            .filter { $0.userID == userID && $0.overlaps(start: startAt, end: endAt) }
            .sorted { $0.startAt < $1.startAt }
    }

    func createSchedule(_ input: PersonalScheduleCreateInput) async throws -> PersonalSchedule {
        guard input.isValid else {
            throw MegrumRepositoryError.unsupportedMutation
        }
        return PersonalSchedule(
            id: UUID(),
            userID: NativePreviewData.viewerID,
            title: input.normalizedTitle,
            placeName: input.normalizedPlaceName,
            startAt: input.startAt,
            endAt: input.endAt,
            allDay: input.allDay,
            note: input.normalizedNote
        )
    }

    func loadHomeLocalModeSettings(now: Date) async throws -> HomeLocalActivitySettings? {
        nil
    }

    func saveHomeLocalModeSettings(
        _ settings: HomeLocalActivitySettings,
        now: Date
    ) async throws -> HomeLocalActivitySettings {
        var normalized = settings.normalizedForPersistence(now: now)
        if normalized.isEnabled, normalized.activityWindowID == nil {
            normalized.activityWindowID = UUID()
        }
        return normalized
    }
}
