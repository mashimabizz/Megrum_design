import Foundation
import MegrumCore

extension MegrumAppState {
    public func loadSchedules(for proposal: TradeProposal, startAt: Date, endAt: Date) async {
        guard loadingSchedulesProposalID != proposal.id else {
            return
        }
        guard startAt < endAt else {
            schedulesByProposalID = ScheduleStateReducer.replacingProposalSchedules(
                in: schedulesByProposalID,
                proposalID: proposal.id,
                schedules: []
            )
            return
        }

        loadingSchedulesProposalID = proposal.id
        errorMessage = nil
        do {
            let schedules = try await repository.loadSchedules(
                for: proposal,
                startAt: startAt,
                endAt: endAt
            )
            schedulesByProposalID = ScheduleStateReducer.replacingProposalSchedules(
                in: schedulesByProposalID,
                proposalID: proposal.id,
                schedules: schedules
            )
        } catch {
            errorMessage = "スケジュールを読み込めませんでした"
        }
        loadingSchedulesProposalID = nil
    }

    public func loadPersonalSchedules(startAt: Date, endAt: Date) async {
        guard !isLoadingPersonalSchedules else {
            return
        }
        guard startAt < endAt else {
            personalSchedules = []
            return
        }

        isLoadingPersonalSchedules = true
        errorMessage = nil
        do {
            personalSchedules = try await repository.loadPersonalSchedules(startAt: startAt, endAt: endAt)
        } catch {
            errorMessage = "スケジュールを読み込めませんでした"
        }
        isLoadingPersonalSchedules = false
    }

    public func loadProfileSchedules(userID: UUID, startAt: Date, endAt: Date) async {
        guard loadingProfileScheduleUserID != userID else {
            return
        }
        guard startAt < endAt else {
            profileSchedulesByUserID[userID] = []
            return
        }

        loadingProfileScheduleUserID = userID
        errorMessage = nil
        do {
            profileSchedulesByUserID[userID] = try await repository.loadProfileSchedules(
                userID: userID,
                startAt: startAt,
                endAt: endAt
            )
        } catch {
            errorMessage = "スケジュールを読み込めませんでした"
        }
        loadingProfileScheduleUserID = nil
    }

    public func createSchedule(_ input: PersonalScheduleCreateInput, for proposal: TradeProposal? = nil) async -> Bool {
        guard input.isValid else {
            errorMessage = "予定名と時間を確認してください"
            return false
        }
        guard !isCreatingSchedule else {
            return false
        }

        isCreatingSchedule = true
        errorMessage = nil
        do {
            let schedule = try await repository.createSchedule(input)
            if let proposal {
                schedulesByProposalID = ScheduleStateReducer.appendingProposalSchedule(
                    schedule,
                    to: schedulesByProposalID,
                    proposalID: proposal.id
                )
            } else {
                personalSchedules = ScheduleStateReducer.appendingPersonalSchedule(
                    schedule,
                    to: personalSchedules
                )
            }
            isCreatingSchedule = false
            return true
        } catch {
            errorMessage = "スケジュールを保存できませんでした"
            isCreatingSchedule = false
            return false
        }
    }
}
