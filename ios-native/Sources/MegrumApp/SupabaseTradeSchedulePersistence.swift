import Foundation
import MegrumCore
import MegrumData

struct SupabaseTradeSchedulePersistence: Sendable {
    private let scheduleClient: SupabaseScheduleClient
    private let userID: UUID

    init(scheduleClient: SupabaseScheduleClient, userID: UUID) {
        self.scheduleClient = scheduleClient
        self.userID = userID
    }

    func loadSchedules(
        for proposal: TradeProposal,
        startAt: Date,
        endAt: Date
    ) async throws -> [PersonalSchedule] {
        let userIDs = Self.scheduleParticipantIDs(for: proposal, viewerID: userID)
        guard !userIDs.isEmpty else {
            return []
        }
        return try await scheduleClient.loadSchedules(
            userIDs: userIDs,
            startAt: startAt,
            endAt: endAt
        )
    }

    func loadPersonalSchedules(startAt: Date, endAt: Date) async throws -> [PersonalSchedule] {
        try await scheduleClient.loadSchedules(
            userIDs: [userID],
            startAt: startAt,
            endAt: endAt
        )
    }

    func createSchedule(_ input: PersonalScheduleCreateInput) async throws -> PersonalSchedule {
        try await scheduleClient.createSchedule(userID: userID, input: input)
    }

    static func scheduleParticipantIDs(for proposal: TradeProposal, viewerID: UUID) -> [UUID] {
        guard proposal.isParticipant(viewerID) else {
            return []
        }
        var userIDs = [viewerID]
        if let partnerID = proposal.partnerID(for: viewerID) {
            userIDs.append(partnerID)
        }
        return userIDs
    }
}
