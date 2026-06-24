import Foundation
import MegrumCore

enum ProposalPaymentOptionSection: String, Equatable, Sendable {
    case mutuallyAccepted
    case needsDiscussion

    var title: String {
        switch self {
        case .mutuallyAccepted:
            "相手もOK"
        case .needsDiscussion:
            "相談して選ぶ"
        }
    }
}

struct ProposalPaymentOption: Identifiable, Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        case method(UserPaymentMethod)
        case other(note: String, owner: Owner)
        case discussion
    }

    enum Owner: String, Equatable, Sendable {
        case viewer
        case partner

        var title: String {
            switch self {
            case .viewer:
                "自分の入力"
            case .partner:
                "相手の入力"
            }
        }
    }

    var id: String
    var title: String
    var subtitle: String?
    var section: ProposalPaymentOptionSection
    var kind: Kind

    var confirmationTitle: String {
        switch kind {
        case let .other(note, _):
            note
        case .discussion, .method:
            title
        }
    }
}

enum ProposalPaymentOptionCatalog {
    static func sections(
        viewerMethods: [UserPaymentMethod],
        viewerOtherNote: String?,
        partnerMethods: [UserPaymentMethod],
        partnerOtherNote: String?
    ) -> [(section: ProposalPaymentOptionSection, options: [ProposalPaymentOption])] {
        let viewer = Set(UserPaymentMethod.normalized(viewerMethods))
        let partner = Set(UserPaymentMethod.normalized(partnerMethods))
        let sharedConcreteMethods = UserPaymentMethod.allCases.filter { method in
            method != .other && viewer.contains(method) && partner.contains(method)
        }
        let hasSharedConcreteMethods = !sharedConcreteMethods.isEmpty
        let partnerOther = otherOption(
            note: partnerOtherNote,
            owner: .partner,
            section: .mutuallyAccepted
        )
        let mutuallyAcceptedPartnerOther = hasSharedConcreteMethods ? partnerOther : nil
        let mutuallyAccepted = sharedConcreteMethods.map {
            methodOption($0, section: .mutuallyAccepted)
        } + [mutuallyAcceptedPartnerOther].compactMap(\.self)

        let hasMutuallyAcceptedOption = !mutuallyAccepted.isEmpty
        let discussionConcrete = UserPaymentMethod.allCases
            .filter { $0 != .other }
            .filter { method in
                viewer.contains(method) || partner.contains(method)
            }
            .filter { method in
                hasMutuallyAcceptedOption ? !sharedConcreteMethods.contains(method) : true
            }
            .map { methodOption($0, section: .needsDiscussion) }

        let viewerOther = otherOption(
            note: viewerOtherNote,
            owner: .viewer,
            section: .needsDiscussion
        )
        let partnerOtherForDiscussion = hasSharedConcreteMethods ? nil : partnerOther?.withSection(.needsDiscussion)
        var discussion = discussionConcrete
        discussion.append(contentsOf: [viewerOther, partnerOtherForDiscussion].compactMap(\.self))
        if mutuallyAccepted.isEmpty && discussion.isEmpty {
            discussion = [
                ProposalPaymentOption(
                    id: "discussion-fallback",
                    title: "相談して決める",
                    subtitle: nil,
                    section: .needsDiscussion,
                    kind: .discussion
                )
            ]
        }

        return [
            (.mutuallyAccepted, mutuallyAccepted),
            (.needsDiscussion, discussion)
        ]
        .filter { !$0.options.isEmpty }
    }

    static func firstOption(
        viewerMethods: [UserPaymentMethod],
        viewerOtherNote: String?,
        partnerMethods: [UserPaymentMethod],
        partnerOtherNote: String?
    ) -> ProposalPaymentOption? {
        sections(
            viewerMethods: viewerMethods,
            viewerOtherNote: viewerOtherNote,
            partnerMethods: partnerMethods,
            partnerOtherNote: partnerOtherNote
        )
        .flatMap(\.options)
        .first
    }

    private static func methodOption(
        _ method: UserPaymentMethod,
        section: ProposalPaymentOptionSection
    ) -> ProposalPaymentOption {
        ProposalPaymentOption(
            id: "\(section.rawValue)-\(method.rawValue)",
            title: method.displayName,
            subtitle: nil,
            section: section,
            kind: .method(method)
        )
    }

    private static func otherOption(
        note: String?,
        owner: ProposalPaymentOption.Owner,
        section: ProposalPaymentOptionSection
    ) -> ProposalPaymentOption? {
        let trimmed = note?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty else {
            return nil
        }
        return ProposalPaymentOption(
            id: "\(section.rawValue)-other-\(owner.rawValue)-\(trimmed)",
            title: "その他（\(owner.title)）",
            subtitle: trimmed,
            section: section,
            kind: .other(note: trimmed, owner: owner)
        )
    }
}

private extension ProposalPaymentOption {
    func withSection(_ section: ProposalPaymentOptionSection) -> ProposalPaymentOption {
        ProposalPaymentOption(
            id: "\(section.rawValue)-\(id)",
            title: title,
            subtitle: subtitle,
            section: section,
            kind: kind
        )
    }
}
