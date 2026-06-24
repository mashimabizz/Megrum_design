import Foundation
import MegrumData

struct DisputeDetailSupabaseMapper: Equatable, Sendable {
    var viewerID: UUID?
    var reporterName: String?
    var respondentName: String?

    init(viewerID: UUID? = nil, reporterName: String? = nil, respondentName: String? = nil) {
        self.viewerID = viewerID
        self.reporterName = reporterName
        self.respondentName = respondentName
    }

    func model(from detail: SupabaseDisputeDetail) -> DisputeDetailModel {
        DisputeDetailModel(supabaseDetail: detail, mapper: self)
    }

    func message(from message: SupabaseDisputeMessage, in detail: SupabaseDisputeDetail) -> DisputeDetailMessageModel {
        DisputeDetailMessageModel(supabaseMessage: message, detail: detail, mapper: self)
    }

    func senderRole(for viewerID: UUID, in detail: SupabaseDisputeDetail) -> SupabaseDisputeParticipantRole? {
        viewerRole(for: viewerID, in: detail)?.participantRole
    }

    func viewerRole(for viewerID: UUID, in detail: SupabaseDisputeDetail) -> DisputeDetailViewerRole? {
        if viewerID == detail.reporterID {
            return .reporter
        }
        if viewerID == detail.respondentID {
            return .respondent
        }
        return nil
    }

    func displayReporterName(for detail: SupabaseDisputeDetail) -> String {
        if let reporterName = reporterName?.nilIfBlank {
            return reporterName
        }
        if viewerID == detail.reporterID {
            return "あなた"
        }
        if viewerID == detail.respondentID {
            return "相手"
        }
        return "申告者"
    }

    func displayRespondentName(for detail: SupabaseDisputeDetail) -> String {
        if let respondentName = respondentName?.nilIfBlank {
            return respondentName
        }
        if viewerID == detail.respondentID {
            return "あなた"
        }
        return "相手"
    }

    func displayName(for role: DisputeDetailMessageSenderRole, senderID: UUID?, in detail: SupabaseDisputeDetail) -> String {
        if let viewerID, senderID == viewerID {
            return "あなた"
        }

        switch role {
        case .reporter:
            return displayReporterName(for: detail)
        case .respondent:
            return displayRespondentName(for: detail)
        case .operator:
            return "運営"
        case .unknown:
            if senderID == detail.reporterID {
                return displayReporterName(for: detail)
            }
            if senderID == detail.respondentID {
                return displayRespondentName(for: detail)
            }
            return senderID == nil ? "運営" : "参加者"
        }
    }
}

extension DisputeDetailModel {
    init(supabaseDetail detail: SupabaseDisputeDetail, mapper: DisputeDetailSupabaseMapper = DisputeDetailSupabaseMapper()) {
        let status = DisputeDetailStatus(
            supabaseStatus: detail.status,
            outcome: detail.outcome,
            operatorComment: detail.operatorComment,
            closedAt: detail.closedAt,
            respondentRespondedAt: detail.respondentRespondedAt
        )
        let messages = Self.mappedMessages(from: detail, mapper: mapper)
        self.init(
            id: detail.id,
            proposalID: detail.proposalID,
            reporterID: detail.reporterID,
            respondentID: detail.respondentID,
            viewerRole: mapper.viewerID.flatMap { mapper.viewerRole(for: $0, in: detail) },
            ticketNo: detail.ticketNo,
            status: status,
            category: detail.category,
            reporterName: mapper.displayReporterName(for: detail),
            respondentName: mapper.displayRespondentName(for: detail),
            factMemo: detail.factMemo,
            evidencePhotoURLs: detail.evidencePhotoURLs.cleanedPhotoURLs,
            respondentEvidencePhotoURLs: detail.respondentEvidenceURLs.cleanedPhotoURLs,
            createdAt: detail.createdAt,
            submittedAt: detail.submittedAt,
            replyDeadlineAt: detail.respondentDeadlineAt,
            operatorDeadlineAt: detail.operatorDeadlineAt,
            resolvedAt: detail.closedAt,
            resolutionSummary: Self.resolutionSummary(from: detail, status: status),
            messages: messages
        )
    }

    private static func mappedMessages(
        from detail: SupabaseDisputeDetail,
        mapper: DisputeDetailSupabaseMapper
    ) -> [DisputeDetailMessageModel] {
        var messages = detail.messages.map { mapper.message(from: $0, in: detail) }

        let respondentBody = detail.respondentResponseText.nilIfBlank ?? detail.respondentResponse.nilIfBlank
        let respondentPhotoURLs = detail.respondentEvidenceURLs.cleanedPhotoURLs
        let hasPersistedRespondentMessage = messages.contains { message in
            message.senderRole == .respondent && (respondentBody == nil || message.body == respondentBody)
        }
        if !hasPersistedRespondentMessage, respondentBody != nil || !respondentPhotoURLs.isEmpty {
            messages.append(
                DisputeDetailMessageModel(
                    id: detail.id,
                    senderID: detail.respondentID,
                    senderRole: .respondent,
                    senderName: mapper.displayRespondentName(for: detail),
                    body: respondentBody ?? "証跡写真が追加されました。",
                    createdAt: detail.respondentRespondedAt ?? detail.updatedAt ?? detail.submittedAt,
                    photoURLs: respondentPhotoURLs
                )
            )
        }

        return messages.sorted { lhs, rhs in
            if lhs.createdAt == rhs.createdAt {
                return lhs.id.uuidString < rhs.id.uuidString
            }
            return lhs.createdAt < rhs.createdAt
        }
    }

    private static func resolutionSummary(from detail: SupabaseDisputeDetail, status: DisputeDetailStatus) -> String? {
        if status == .withdrawn {
            return "申告は取り下げられました。"
        }

        let outcome = detail.outcome.nilIfBlank
        let operatorComment = detail.operatorComment.nilIfBlank
        switch (outcome, operatorComment) {
        case let (.some(outcome), .some(operatorComment)):
            return "\(outcome)\n\(operatorComment)"
        case let (.some(outcome), .none):
            return outcome
        case let (.none, .some(operatorComment)):
            return operatorComment
        case (.none, .none):
            return nil
        }
    }
}

extension DisputeDetailMessageModel {
    init(
        supabaseMessage message: SupabaseDisputeMessage,
        detail: SupabaseDisputeDetail,
        mapper: DisputeDetailSupabaseMapper = DisputeDetailSupabaseMapper()
    ) {
        let role = DisputeDetailMessageSenderRole(supabaseRole: message.senderRole, senderID: message.senderID)
        self.init(
            id: message.id,
            senderID: message.senderID,
            senderRole: role,
            senderName: mapper.displayName(for: role, senderID: message.senderID, in: detail),
            body: message.body,
            createdAt: message.createdAt,
            photoURLs: message.photoURLs.cleanedPhotoURLs
        )
    }
}

private extension DisputeDetailViewerRole {
    var participantRole: SupabaseDisputeParticipantRole {
        switch self {
        case .reporter:
            .reporter
        case .respondent:
            .respondent
        }
    }
}

private extension DisputeDetailMessageSenderRole {
    init(supabaseRole: SupabaseDisputeParticipantRole?, senderID: UUID?) {
        switch supabaseRole {
        case .reporter:
            self = .reporter
        case .respondent:
            self = .respondent
        case .none:
            self = senderID == nil ? .operator : .unknown
        }
    }
}

private extension Array where Element == String {
    var cleanedPhotoURLs: [String] {
        map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
