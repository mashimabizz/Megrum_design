import Foundation
import MegrumData
import SwiftUI

struct DisputeReplyDraft: Equatable, Sendable {
    static let maxBodyLength = 4_000

    var body: String = ""
    var includesEvidenceNote = true

    var normalizedBody: String {
        body.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isSubmittable: Bool {
        validationMessage == nil
    }

    var validationMessage: String? {
        if normalizedBody.isEmpty {
            return "本文を入力してください"
        }
        if normalizedBody.count > Self.maxBodyLength {
            return "本文は\(Self.maxBodyLength)文字以内で入力してください"
        }
        return nil
    }
}

enum DisputeDetailLoadState: Equatable, Sendable {
    case loading
    case loaded(DisputeDetailModel)
    case empty
    case failed(String)

    var model: DisputeDetailModel? {
        if case .loaded(let model) = self {
            return model
        }
        return nil
    }
}

enum DisputeDetailActionError: LocalizedError, Equatable {
    case notCompleted
    case notParticipant

    var errorDescription: String? {
        switch self {
        case .notCompleted:
            "操作を完了できませんでした。"
        case .notParticipant:
            "この申告を操作できません。"
        }
    }
}

@MainActor
final class DisputeDetailStore: ObservableObject {
    typealias DetailAction = () async throws -> DisputeDetailModel?
    typealias ReplyAction = (DisputeReplyDraft) async throws -> DisputeDetailModel?
    typealias WithdrawAction = () async throws -> DisputeDetailModel?

    struct Actions {
        var detail: DetailAction
        var reply: ReplyAction
        var withdraw: WithdrawAction

        init(
            detail: @escaping DetailAction,
            reply: @escaping ReplyAction,
            withdraw: @escaping WithdrawAction
        ) {
            self.detail = detail
            self.reply = reply
            self.withdraw = withdraw
        }

        static func supabase(
            ticketID: UUID,
            viewerID: UUID,
            client: SupabaseDisputeClient,
            mapper: DisputeDetailSupabaseMapper? = nil
        ) -> Actions {
            let mapper = mapper ?? DisputeDetailSupabaseMapper(viewerID: viewerID)
            return Actions(
                detail: {
                    try await client.loadDispute(ticketID: ticketID).map(mapper.model(from:))
                },
                reply: { draft in
                    guard let detail = try await client.loadDispute(ticketID: ticketID) else {
                        return nil
                    }
                    guard let senderRole = mapper.senderRole(for: viewerID, in: detail) else {
                        throw DisputeDetailActionError.notParticipant
                    }
                    _ = try await client.createDisputeReply(
                        SupabaseDisputeReplyCreateInput(
                            disputeID: ticketID,
                            senderID: viewerID,
                            senderRole: senderRole,
                            body: draft.normalizedBody
                        )
                    )
                    return try await client.loadDispute(ticketID: ticketID).map(mapper.model(from:))
                },
                withdraw: {
                    try await client.withdrawDispute(ticketID: ticketID, reporterID: viewerID)
                        .map(mapper.model(from:))
                }
            )
        }
    }

    @Published private(set) var state: DisputeDetailLoadState
    @Published var replyDraft: DisputeReplyDraft
    @Published private(set) var isLoading = false
    @Published private(set) var isSubmittingReply = false
    @Published private(set) var isWithdrawing = false
    @Published private(set) var actionErrorMessage: String?

    private let detail: DetailAction
    private let reply: ReplyAction
    private let withdraw: WithdrawAction
    private var hasLoaded = false

    convenience init(
        initialState: DisputeDetailLoadState = .loading,
        initialReplyDraft: DisputeReplyDraft = DisputeReplyDraft(),
        detail: @escaping DetailAction,
        reply: @escaping ReplyAction,
        withdraw: @escaping WithdrawAction
    ) {
        self.init(
            initialState: initialState,
            initialReplyDraft: initialReplyDraft,
            actions: Actions(detail: detail, reply: reply, withdraw: withdraw)
        )
    }

    init(
        initialState: DisputeDetailLoadState = .loading,
        initialReplyDraft: DisputeReplyDraft = DisputeReplyDraft(),
        actions: Actions
    ) {
        self.state = initialState
        self.replyDraft = initialReplyDraft
        self.detail = actions.detail
        self.reply = actions.reply
        self.withdraw = actions.withdraw
        self.hasLoaded = initialState.model != nil
    }

    func loadIfNeeded() async {
        guard !hasLoaded else {
            return
        }
        await load()
    }

    func load() async {
        hasLoaded = true
        isLoading = true
        if state.model == nil {
            state = .loading
        }
        do {
            state = try await resolvedState(from: detail())
        } catch {
            state = .failed(Self.message(for: error))
        }
        isLoading = false
    }

    func submitReply() async {
        let draft = replyDraft
        guard draft.isSubmittable, !isSubmittingReply else {
            return
        }
        guard state.model?.canSubmitReply == true else {
            actionErrorMessage = "この状態では反論を送信できません。"
            return
        }

        isSubmittingReply = true
        actionErrorMessage = nil
        do {
            let updated = try await reply(draft)
            replyDraft = DisputeReplyDraft()
            if let updated {
                state = .loaded(updated)
            } else {
                state = try await resolvedState(from: detail())
            }
        } catch {
            actionErrorMessage = Self.message(for: error)
        }
        isSubmittingReply = false
    }

    func withdrawDispute() async {
        guard state.model?.canWithdraw == true, !isWithdrawing else {
            return
        }

        isWithdrawing = true
        actionErrorMessage = nil
        do {
            state = try await resolvedState(from: withdraw())
        } catch {
            actionErrorMessage = Self.message(for: error)
        }
        isWithdrawing = false
    }

    func clearActionError() {
        actionErrorMessage = nil
    }

    private func resolvedState(from model: DisputeDetailModel?) -> DisputeDetailLoadState {
        if let model {
            return .loaded(model)
        }
        return .empty
    }

    private static func message(for error: Error) -> String {
        let localized = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        if !localized.isEmpty {
            return localized
        }
        return "時間をおいてもう一度お試しください。"
    }
}
