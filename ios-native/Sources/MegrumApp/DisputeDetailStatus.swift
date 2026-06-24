import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

enum DisputeDetailStatus: String, CaseIterable, Identifiable, Equatable, Sendable {
    case filed
    case submitted
    case replyWindow = "reply_window"
    case replyReceived = "reply_received"
    case arbitration
    case resolved
    case withdrawn

    var id: String { rawValue }

    init(rawStatus: String) {
        switch rawStatus.normalizedDisputeStatus {
        case "response_pending":
            self = .replyWindow
        case "responded":
            self = .replyReceived
        case "arbitrating":
            self = .arbitration
        case "closed":
            self = .resolved
        default:
            self = DisputeDetailStatus(rawValue: rawStatus.normalizedDisputeStatus) ?? .submitted
        }
    }

    init(supabaseStatus: String, outcome: String?, operatorComment: String?, closedAt: Date?, respondentRespondedAt: Date?) {
        let normalized = supabaseStatus.normalizedDisputeStatus
        if normalized == "closed" {
            self = outcome.nilIfBlank == nil && operatorComment.nilIfBlank == nil ? .withdrawn : .resolved
            return
        }
        if normalized == "response_pending", respondentRespondedAt != nil {
            self = .replyReceived
            return
        }
        self.init(rawStatus: normalized)
    }

    var displayName: String {
        switch self {
        case .filed:
            "申告作成中"
        case .submitted:
            "申告送信済"
        case .replyWindow:
            "反論受付中"
        case .replyReceived:
            "反論受領"
        case .arbitration:
            "仲裁中"
        case .resolved:
            "仲裁決定済"
        case .withdrawn:
            "取り下げ済"
        }
    }

    var systemImage: String {
        switch self {
        case .filed:
            "square.and.pencil"
        case .submitted:
            "tray.and.arrow.up.fill"
        case .replyWindow:
            "bubble.left.and.bubble.right.fill"
        case .replyReceived:
            "text.bubble.fill"
        case .arbitration:
            "person.2.badge.gearshape.fill"
        case .resolved:
            "checkmark.seal.fill"
        case .withdrawn:
            "arrow.uturn.backward.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .resolved:
            MegrumTheme.ok
        case .withdrawn:
            MegrumTheme.muted
        case .arbitration:
            MegrumTheme.sky
        default:
            MegrumTheme.lavender
        }
    }

    var allowsReply: Bool {
        self == .submitted || self == .replyWindow
    }

    var allowsWithdrawal: Bool {
        switch self {
        case .filed, .submitted, .replyWindow:
            true
        case .replyReceived, .arbitration, .resolved, .withdrawn:
            false
        }
    }
}

private extension String {
    var normalizedDisputeStatus: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "-", with: "_")
    }
}
