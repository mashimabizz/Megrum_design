import Foundation
import MegrumCore
import MegrumData
import XCTest

final class SupabaseRequestParityTests: XCTestCase {
    func testProposalStatusRawValuesMatchSchemaNames() {
        let schemaAllowedStatuses: Set<String> = [
            "draft",
            "sent",
            "negotiating",
            "agreement_one_side",
            "agreed",
            "rejected",
            "expired",
            "cancelled",
            "completed"
        ]

        XCTAssertEqual(Set(ProposalStatus.allCases.map(\.rawValue)), schemaAllowedStatuses)
    }

    func testExchangeMethodRawValuesMatchSchemaNames() {
        XCTAssertEqual(Set(ExchangeMethod.allCases.map(\.rawValue)), ["hand", "mail", "both"])
    }

    func testCreateProposalPayloadUsesSchemaColumnNamesForExchangeMethodAndListingID() throws {
        let client = SupabaseProposalClient(configuration: configuration)
        let senderID = uuid("11111111-1111-1111-1111-111111111111")
        let listingID = uuid("22222222-2222-2222-2222-222222222222")

        let request = try client.makeCreateProposalRequest(
            senderID: senderID,
            input: ProposalCreateInput(
                receiverID: uuid("33333333-3333-3333-3333-333333333333"),
                senderGoodsIDs: [uuid("44444444-4444-4444-4444-444444444444")],
                receiverGoodsIDs: [uuid("55555555-5555-5555-5555-555555555555")],
                exchangeMethod: .both,
                conditionTags: ["same-day"],
                message: " Listing origin ",
                status: .draft,
                listingID: listingID
            )
        )
        let payload = try firstPayloadRow(from: request)

        XCTAssertEqual(payload["exchange_method"] as? String, "both")
        XCTAssertEqual(payload["listing_id"] as? String, listingID.uuidString.lowercased())
        XCTAssertEqual(payload["status"] as? String, "draft")
        XCTAssertEqual(payload["agreed_by_sender"] as? Bool, false)
        XCTAssertNil(payload["exchangeMethod"])
        XCTAssertNil(payload["listingID"])
        XCTAssertNil(payload["agreementOneSide"])
    }

    func testProposalAgreementRPCUsesSnakeCaseInputsAndFixesBothExchangeMethod() throws {
        let client = SupabaseProposalClient(configuration: configuration)
        let senderID = uuid("11111111-1111-1111-1111-111111111111")
        let receiverID = uuid("22222222-2222-2222-2222-222222222222")
        let proposal = TradeProposal(
            id: uuid("33333333-3333-3333-3333-333333333333"),
            senderID: senderID,
            receiverID: receiverID,
            status: .negotiating,
            exchangeMethod: .both,
            senderGoodsIDs: [uuid("44444444-4444-4444-4444-444444444444")],
            receiverGoodsIDs: [uuid("55555555-5555-5555-5555-555555555555")],
            agreedBySender: false,
            agreedByReceiver: false
        )

        let request = try client.makeAgreeProposalRequest(
            userID: senderID,
            proposal: proposal,
            acceptedExchangeMethod: .hand
        )
        let payload = try objectPayload(from: request)

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://example.supabase.co/rest/v1/rpc/respond_to_proposal_for_viewer")
        XCTAssertEqual(payload["p_proposal_id"] as? String, "33333333-3333-3333-3333-333333333333")
        XCTAssertEqual(payload["p_action"] as? String, "agree")
        XCTAssertEqual(payload["p_accepted_exchange_method"] as? String, "hand")
        XCTAssertNil(payload["agreementOneSide"])
        XCTAssertNil(payload["exchangeMethod"])
    }

    func testProposalReadAndMutationSelectsPreserveListingID() throws {
        let client = SupabaseProposalClient(configuration: configuration)
        let viewerID = uuid("11111111-1111-1111-1111-111111111111")
        let senderID = uuid("22222222-2222-2222-2222-222222222222")
        let input = ProposalCreateInput(
            receiverID: uuid("33333333-3333-3333-3333-333333333333"),
            senderGoodsIDs: [uuid("44444444-4444-4444-4444-444444444444")],
            receiverGoodsIDs: [uuid("55555555-5555-5555-5555-555555555555")],
            exchangeMethod: .mail,
            listingID: uuid("66666666-6666-6666-6666-666666666666")
        )

        let loadSelect = try queryValue("select", in: client.makeLoadProposalsRequest(viewerID: viewerID))
        let createSelect = try queryValue("select", in: client.makeCreateProposalRequest(senderID: senderID, input: input))

        XCTAssertTrue(loadSelect.split(separator: ",").contains("listing_id"))
        XCTAssertTrue(createSelect.split(separator: ",").contains("listing_id"))
    }

    func testSentLocalExchangeProposalCreateRequestRejectsMissingMeetupColumns() {
        let client = SupabaseProposalClient(configuration: configuration)
        let senderID = uuid("11111111-1111-1111-1111-111111111111")

        for exchangeMethod in [ExchangeMethod.hand, .both] {
            XCTAssertThrowsError(
                try client.makeCreateProposalRequest(
                    senderID: senderID,
                    input: ProposalCreateInput(
                        receiverID: uuid("22222222-2222-2222-2222-222222222222"),
                        senderGoodsIDs: [uuid("33333333-3333-3333-3333-333333333333")],
                        receiverGoodsIDs: [uuid("44444444-4444-4444-4444-444444444444")],
                        exchangeMethod: exchangeMethod,
                        status: .sent
                    )
                )
            ) { error in
                XCTAssertEqual(error as? SupabaseProposalClientError, .missingMeetup)
            }
        }
    }

    func testSentLocalExchangeProposalCreatePayloadIncludesSchemaRequiredMeetupColumns() throws {
        let client = SupabaseProposalClient(configuration: configuration)
        let senderID = uuid("11111111-1111-1111-1111-111111111111")
        let meetup = ProposalMeetupInput(
            startAt: Date(timeIntervalSince1970: 1_000),
            endAt: Date(timeIntervalSince1970: 2_800),
            placeName: " 横浜アリーナ 北口 ",
            latitude: 35.5122,
            longitude: 139.6171
        )
        let requiredMeetupFields = [
            "meetup_start_at",
            "meetup_end_at",
            "meetup_place_name",
            "meetup_lat",
            "meetup_lng"
        ]

        for exchangeMethod in [ExchangeMethod.hand, .both] {
            let request = try client.makeCreateProposalRequest(
                senderID: senderID,
                input: ProposalCreateInput(
                    receiverID: uuid("22222222-2222-2222-2222-222222222222"),
                    senderGoodsIDs: [uuid("33333333-3333-3333-3333-333333333333")],
                    receiverGoodsIDs: [uuid("44444444-4444-4444-4444-444444444444")],
                    exchangeMethod: exchangeMethod,
                    status: .sent,
                    meetup: meetup
                )
            )
            let payload = try firstPayloadRow(from: request)
            let missingFields = requiredMeetupFields.filter { payload[$0] == nil }

            XCTAssertTrue(
                missingFields.isEmpty,
                "\(exchangeMethod.rawValue) sent proposal payload is missing schema-required meetup fields: \(missingFields)"
            )
            XCTAssertEqual(payload["meetup_place_name"] as? String, "横浜アリーナ 北口")
            XCTAssertNotNil(payload["meetup_candidates"])
        }
    }

    func testNotificationKindRawValuesMatchCurrentSchemaNames() {
        let schemaAllowedKinds: Set<String> = [
            "proposal_received",
            "proposal_accepted",
            "proposal_rejected",
            "proposal_revised",
            "message_received",
            "evidence_added",
            "trade_completed",
            "evaluation_received",
            "dispute_received",
            "dispute_responded",
            "dispute_closed",
            "cancel_requested",
            "expires_soon",
            "groom_reply",
            "meguri_message",
            "meguri_board_reply",
            "meguri_board_mention",
            "admin_announcement"
        ]
        let requestKinds = Set(
            MegrumNotificationKind.allCases
                .filter { $0 != .unknown }
                .map(\.rawValue)
        )

        XCTAssertEqual(requestKinds, schemaAllowedKinds)
    }

    func testNotificationRequestsSelectAndWriteLinkPathWithMeguriCategoryRoute() throws {
        let notificationClient = SupabaseNotificationClient(configuration: configuration)
        let loadRequest = try notificationClient.makeLoadNotificationsRequest(
            userID: uuid("11111111-1111-1111-1111-111111111111"),
            limit: 20
        )
        let loadSelect = try queryValue("select", in: loadRequest)

        XCTAssertTrue(loadSelect.split(separator: ",").contains("link_path"))
        XCTAssertFalse(loadSelect.contains("linkPath"))

        let groomClient = SupabaseGroomClient(configuration: configuration)
        let senderID = uuid("22222222-2222-2222-2222-222222222222")
        let recipientID = uuid("33333333-3333-3333-3333-333333333333")
        let reply = GroomReply(
            id: uuid("44444444-4444-4444-4444-444444444444"),
            groomPostID: uuid("55555555-5555-5555-5555-555555555555"),
            senderID: senderID,
            recipientID: recipientID,
            body: "hello"
        )
        let notificationRequest = try groomClient.makeReplyNotificationRequest(reply: reply)
        let payload = try firstPayloadRow(from: notificationRequest)
        let linkPath = try XCTUnwrap(payload["link_path"] as? String)

        XCTAssertEqual(payload["kind"] as? String, "groom_reply")
        XCTAssertTrue(linkPath.hasPrefix("/meguri-letters?"))
        XCTAssertTrue(linkPath.contains("userId=\(senderID.uuidString.lowercased())"))
        XCTAssertNil(payload["linkPath"])
    }

    private var configuration: SupabaseConfiguration {
        SupabaseConfiguration(
            projectURL: URL(string: "https://example.supabase.co")!,
            publishableKey: "sb_publishable_test"
        )
    }

    private func firstPayloadRow(from request: URLRequest) throws -> [String: Any] {
        let body = try XCTUnwrap(request.httpBody)
        let rows = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])
        return try XCTUnwrap(rows.first)
    }

    private func objectPayload(from request: URLRequest) throws -> [String: Any] {
        let body = try XCTUnwrap(request.httpBody)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
    }

    private func queryValue(_ name: String, in request: URLRequest) throws -> String {
        let url = try XCTUnwrap(request.url)
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let item = try XCTUnwrap(components.queryItems?.first { $0.name == name })
        return try XCTUnwrap(item.value)
    }

    private func uuid(_ value: String) -> UUID {
        UUID(uuidString: value)!
    }
}
