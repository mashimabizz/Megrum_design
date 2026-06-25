@testable import MegrumApp
import Foundation
import MegrumCore
import MegrumData
import XCTest

final class HomeMutualMatchLiveDataTests: XCTestCase {
    func testMichilionLiveMutualMatchAppearsForSeededPartner() async throws {
        let environment = ProcessInfo.processInfo.environment
        guard environment["MEGRUM_LIVE_MICHILION_MUTUAL_MATCH_TEST"] == "1" else {
            throw XCTSkip("Set MEGRUM_LIVE_MICHILION_MUTUAL_MATCH_TEST=1 after seeding the michilion visible mutual-match rows.")
        }
        guard
            let configuration = SupabaseConfiguration.fromEnvironment(environment),
            let viewerIDValue = environment["MEGRUM_MUTUAL_MATCH_VIEWER_ID"],
            let viewerID = UUID(uuidString: viewerIDValue)
        else {
            XCTFail("Missing MEGRUM_SUPABASE_URL / MEGRUM_SUPABASE_PUBLISHABLE_KEY / MEGRUM_MUTUAL_MATCH_VIEWER_ID.")
            return
        }

        let expectedHandle = environment["MEGRUM_MUTUAL_MATCH_EXPECTED_HANDLE"] ?? "haru_trade_0624"
        let fullComposition = try await SupabaseHomeClient(configuration: configuration)
            .loadHomeComposition(userID: viewerID, partnerLimit: 500)
        let fullSections = HomeCandidateComposer.sections(from: fullComposition)
        XCTAssertNotNil(
            fullSections.mutualMatchCandidates.first { $0.partnerHandle == expectedHandle },
            "The seeded visible partner should also appear through the full home-composition loader used by the app repository."
        )

        let composition = try await loadScopedLiveComposition(
            configuration: configuration,
            viewerID: viewerID,
            expectedPartnerHandle: expectedHandle
        )
        let sections = HomeCandidateComposer.sections(from: composition)
        let candidate = try XCTUnwrap(
            sections.mutualMatchCandidates.first { $0.partnerHandle == expectedHandle },
            "The seeded visible partner should appear in the mutual-match tab data for michilion."
        )

        XCTAssertEqual(candidate.partnerName, "はる")
        XCTAssertEqual(candidate.partnerGoodsItems.first?.memberName, "SUGA")
        XCTAssertEqual(candidate.viewerGoodsItems.first?.memberName, "ジン")
        XCTAssertEqual(candidate.partnerGoodsItems.first?.goodsTypeName, "トレカ")
        XCTAssertEqual(candidate.viewerGoodsItems.first?.goodsTypeName, "トレカ")
        XCTAssertTrue(candidate.attentionKinds.contains(.ready))

        let uiCandidates = HomeMutualMatchCandidateFactory.candidates(
            mutualMatchData: sections.mutualMatchCandidates,
            viewerID: viewerID,
            inventoryItems: sections.possibleItems,
            matchedItems: sections.matchedItems,
            possibleItems: sections.possibleItems,
            goodsTypes: [],
            conditionSignalsByItemID: sections.conditionSignalsByItemID
        )
        let uiCandidate = try XCTUnwrap(
            uiCandidates.first { $0.partnerHandle == expectedHandle },
            "The seeded visible partner should survive the UI candidate factory used by the mutual-match tab."
        )
        XCTAssertEqual(uiCandidate.partnerGoodsItems.first?.memberName, "SUGA")
        XCTAssertEqual(uiCandidate.viewerGoodsItems.first?.memberName, "ジン")
    }

    func testMichilionLiveReceiveSelectionAppearsForSeededPartnerListing() async throws {
        let environment = ProcessInfo.processInfo.environment
        guard environment["MEGRUM_LIVE_MICHILION_RECEIVE_SELECTION_TEST"] == "1" else {
            throw XCTSkip("Set MEGRUM_LIVE_MICHILION_RECEIVE_SELECTION_TEST=1 after running scripts/seed_michilion_receive_selection_live_data.py.")
        }
        guard
            let configuration = SupabaseConfiguration.fromEnvironment(environment),
            let viewerIDValue = environment["MEGRUM_MUTUAL_MATCH_VIEWER_ID"],
            let viewerID = UUID(uuidString: viewerIDValue)
        else {
            XCTFail("Missing MEGRUM_SUPABASE_URL / MEGRUM_SUPABASE_PUBLISHABLE_KEY / MEGRUM_MUTUAL_MATCH_VIEWER_ID.")
            return
        }

        let expectedHandle = environment["MEGRUM_RECEIVE_SELECTION_EXPECTED_HANDLE"] ?? "haru_trade_0624"
        let composition = try await loadScopedLiveComposition(
            configuration: configuration,
            viewerID: viewerID,
            expectedPartnerHandle: expectedHandle
        )
        let sections = HomeCandidateComposer.sections(from: composition)
        let expectedOwnerID = try XCTUnwrap(composition.partnerUsers.first?.id)
        let candidate = try XCTUnwrap(
            receiveSelectionCandidate(in: sections, expectedOwnerID: expectedOwnerID),
            "The seeded partner listing should create a goods candidate with receive selection context."
        )
        let signals = try XCTUnwrap(sections.conditionSignalsByItemID[candidate.id])
        let detail = try XCTUnwrap(signals.individualListingSelection?.detail)

        XCTAssertEqual(detail.offeredLogic, .atLeast)
        XCTAssertEqual(detail.offeredMinimumCount, 2)
        XCTAssertGreaterThanOrEqual(detail.offeredItems.count, 3)

        let sheetContext = HomeGoodsHitDetailSelectionContext(
            selection: HomeDiscoverySheetPayload(
                goods: HomeMockGoods.from(item: candidate, index: 0, goodsTypes: []),
                signals: signals
            ),
            viewerOfferGoods: [],
            selectionState: HomeListingSheetSelectionState()
        )
        XCTAssertTrue(sheetContext.showsReceiveSelection)
        XCTAssertEqual(sheetContext.receiveRequirementLabel, "2個以上")
        XCTAssertEqual(sheetContext.receiveGoods.count, detail.offeredItems.count)
    }

    private func loadScopedLiveComposition(
        configuration: SupabaseConfiguration,
        viewerID: UUID,
        expectedPartnerHandle: String
    ) async throws -> SupabaseHomeComposition {
        let client = SupabaseRESTClient(configuration: configuration)
        let viewerUser = try await fetchUsers(
            client,
            queryItems: [
                URLQueryItem(name: "id", value: "eq.\(viewerID.uuidString.lowercased())"),
                URLQueryItem(name: "limit", value: "1")
            ]
        ).first
        let partnerRows = try await fetchUsers(
            client,
            queryItems: [
                URLQueryItem(name: "handle", value: "eq.\(expectedPartnerHandle)"),
                URLQueryItem(name: "limit", value: "1")
            ]
        )
        let partnerUser = try XCTUnwrap(partnerRows.first)
        let partnerID = partnerUser.id

        let viewerInventory = try await fetchGoods(
            client,
            queryItems: scopedGoodsQueryItems(userID: viewerID, kind: "for_trade", status: "eq.active")
        )
        let viewerWishes = try await fetchGoods(
            client,
            queryItems: scopedGoodsQueryItems(userID: viewerID, kind: "wanted", status: "neq.archived")
        )
        let partnerInventory = try await fetchGoods(
            client,
            queryItems: scopedGoodsQueryItems(userID: partnerID, kind: "for_trade", status: "eq.active")
        )
        let partnerWishes = try await fetchGoods(
            client,
            queryItems: scopedGoodsQueryItems(userID: partnerID, kind: "wanted", status: "neq.archived")
        )
        let viewerListings: [SupabaseHomeListingRow] = try await client.fetchRows(
            from: "listings",
            select: Self.listingSelect,
            queryItems: activeListingsQueryItems(userID: viewerID)
        )
        let partnerListings: [SupabaseHomeListingRow] = try await client.fetchRows(
            from: "listings",
            select: Self.listingSelect,
            queryItems: activeListingsQueryItems(userID: partnerID)
        )
        let listingIDs = (viewerListings + partnerListings).map(\.id)
        let listingWishOptions: [SupabaseHomeListingWishOptionRow] = listingIDs.isEmpty
            ? []
            : try await client.fetchRows(
                from: "listing_wish_options",
                select: Self.listingWishOptionSelect,
                queryItems: [
                    URLQueryItem(name: "listing_id", value: inFilter(listingIDs)),
                    URLQueryItem(name: "order", value: "position.asc")
                ]
            )
        let inventoryIDs = (viewerInventory + viewerWishes + partnerInventory + partnerWishes).map(\.id)
        let inventoryTags: [SupabaseHomeInventoryTagRow] = inventoryIDs.isEmpty
            ? []
            : try await client.fetchRows(
                from: "goods_inventory_tags",
                select: Self.inventoryTagSelect,
                queryItems: [
                    URLQueryItem(name: "inventory_id", value: inFilter(inventoryIDs))
                ]
            )

        return SupabaseHomeComposition(
            localMode: nil,
            viewerUser: viewerUser,
            viewerInventory: viewerInventory,
            viewerWishes: viewerWishes,
            viewerListings: viewerListings,
            partnerInventory: partnerInventory,
            partnerWishes: partnerWishes,
            partnerUsers: [partnerUser],
            partnerListings: partnerListings,
            listingWishOptions: listingWishOptions,
            viewerActivityWindows: [],
            partnerActivityWindows: [],
            inventoryTags: inventoryTags,
            unreadNotificationIDs: []
        )
    }

    private func fetchUsers(
        _ client: SupabaseRESTClient,
        queryItems: [URLQueryItem]
    ) async throws -> [SupabaseHomeUserRow] {
        do {
            return try await client.fetchRows(
                from: "users",
                select: Self.userSelect,
                queryItems: queryItems
            )
        } catch let error as SupabaseRESTError where error == .unexpectedStatus(400) {
            return try await client.fetchRows(
                from: "users",
                select: Self.userLegacySelect,
                queryItems: queryItems
            )
        }
    }

    private func fetchGoods(
        _ client: SupabaseRESTClient,
        queryItems: [URLQueryItem]
    ) async throws -> [SupabaseHomeGoodsRow] {
        do {
            return try await client.fetchRows(
                from: "goods_inventory",
                select: Self.goodsSelect,
                queryItems: queryItems
            )
        } catch let error as SupabaseRESTError where error == .unexpectedStatus(400) {
            return try await client.fetchRows(
                from: "goods_inventory",
                select: Self.goodsLegacySelect,
                queryItems: queryItems
            )
        }
    }

    private func scopedGoodsQueryItems(userID: UUID, kind: String, status: String) -> [URLQueryItem] {
        [
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString.lowercased())"),
            URLQueryItem(name: "kind", value: "eq.\(kind)"),
            URLQueryItem(name: "status", value: status)
        ]
    }

    private func activeListingsQueryItems(userID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString.lowercased())"),
            URLQueryItem(name: "status", value: "eq.active")
        ]
    }

    private func inFilter(_ ids: [UUID]) -> String {
        "in.(\(ids.map { $0.uuidString.lowercased() }.joined(separator: ",")))"
    }

    private func receiveSelectionCandidate(
        in sections: HomeCandidateSections,
        expectedOwnerID: UUID
    ) -> GoodsItem? {
        (sections.matchedItems + sections.possibleItems).first { item in
            guard item.ownerID == expectedOwnerID,
                  let selection = sections.conditionSignalsByItemID[item.id]?.individualListingSelection,
                  let detail = selection.detail
            else {
                return false
            }
            return detail.offeredLogic == .atLeast
                && detail.offeredMinimumCount >= 2
                && detail.offeredItems.count > 1
        }
    }

    private static let goodsSelect = "id,user_id,kind,group_id,character_id,character_request_id,goods_type_id,title,photo_urls,quantity,locked_qty,market_available_qty,exchange_type,hue,status,group:groups_master(name),character:characters_master(name),goods_type:goods_types_master(name),updated_at"
    private static let goodsLegacySelect = "id,user_id,kind,group_id,character_id,character_request_id,goods_type_id,title,photo_urls,quantity,exchange_type,hue,status,group:groups_master(name),character:characters_master(name),goods_type:goods_types_master(name),updated_at"
    private static let userSelect = "id,handle,display_name,primary_area,avatar_url,age,payment_methods,payment_note,is_test_account"
    private static let userLegacySelect = "id,handle,display_name,primary_area,avatar_url"
    private static let listingSelect = "id,user_id,have_ids,have_qtys,have_logic,have_min_count,have_group_id,have_goods_type_id,status,note,created_at,updated_at"
    private static let listingWishOptionSelect = "id,listing_id,position,wish_ids,wish_qtys,logic,min_count,exchange_type,is_cash_offer,cash_amount,wish_group_id,wish_goods_type_id,created_at,updated_at"
    private static let inventoryTagSelect = "inventory_id,tag_id,tag:tags_master(label)"

    func testSeededLiveMutualMatchesCoverDisplayPatterns() async throws {
        let environment = ProcessInfo.processInfo.environment
        guard environment["MEGRUM_LIVE_MUTUAL_MATCH_TEST"] == "1" else {
            throw XCTSkip("Set MEGRUM_LIVE_MUTUAL_MATCH_TEST=1 with a seeded viewer to run the live Supabase mutual match check.")
        }
        guard
            let configuration = SupabaseConfiguration.fromEnvironment(environment),
            let viewerIDValue = environment["MEGRUM_MUTUAL_MATCH_VIEWER_ID"],
            let viewerID = UUID(uuidString: viewerIDValue)
        else {
            XCTFail("Missing MEGRUM_SUPABASE_URL / MEGRUM_SUPABASE_PUBLISHABLE_KEY / MEGRUM_MUTUAL_MATCH_VIEWER_ID.")
            return
        }

        let composition = try await SupabaseHomeClient(configuration: configuration)
            .loadHomeComposition(userID: viewerID, partnerLimit: 500)
        let sections = HomeCandidateComposer.sections(from: composition)
        let candidatesByHandle = Dictionary(grouping: sections.mutualMatchCandidates) { candidate in
            candidate.partnerHandle
        }

        let ready = try XCTUnwrap(candidatesByHandle["codex_mm_ready"]?.first)
        XCTAssertEqual(ready.attentionKinds, [.ready])
        XCTAssertEqual(ready.partnerGoodsItems.count, 1)
        XCTAssertEqual(ready.viewerGoodsItems.count, 1)

        let tagMismatch = try XCTUnwrap(candidatesByHandle["codex_mm_tag"]?.first)
        XCTAssertTrue(tagMismatch.attentionKinds.contains(.tagMismatch))

        let amountInsufficient = try XCTUnwrap(candidatesByHandle["codex_mm_cash"]?.first)
        XCTAssertTrue(amountInsufficient.attentionKinds.contains(.amountInsufficient))
        XCTAssertEqual(amountInsufficient.partnerDisplayItems.first?.kind, .cashAmount)
        XCTAssertEqual(amountInsufficient.partnerDisplayItems.first?.title, "¥2,000")
        XCTAssertEqual(amountInsufficient.viewerDisplayItems.first?.kind, .cashAmount)
        XCTAssertEqual(amountInsufficient.viewerDisplayItems.first?.title, "¥1,500")

        let setCandidate = try XCTUnwrap(candidatesByHandle["codex_mm_set"]?.first)
        XCTAssertGreaterThanOrEqual(setCandidate.partnerGoodsItems.count, 2)
        XCTAssertGreaterThanOrEqual(setCandidate.viewerGoodsItems.count, 2)

        let uiCandidates = HomeMutualMatchCandidateFactory.candidates(
            mutualMatchData: sections.mutualMatchCandidates,
            viewerID: viewerID,
            inventoryItems: sections.possibleItems,
            matchedItems: sections.matchedItems,
            possibleItems: sections.possibleItems,
            goodsTypes: [],
            conditionSignalsByItemID: sections.conditionSignalsByItemID
        )
        let setUICandidate = try XCTUnwrap(uiCandidates.first { $0.partnerHandle == "codex_mm_set" })
        XCTAssertEqual(setUICandidate.requestedGoodsBadgeTitle, "セット")
        XCTAssertEqual(setUICandidate.offeredGoodsBadgeTitle, "セット")

        XCTAssertNil(
            candidatesByHandle["codex_mm_nomatch"],
            "A member-level mismatch must not appear as a mutual match."
        )

        if environment["MEGRUM_LIVE_MUTUAL_MATCH_EXPECT_AMOUNT_INCLUDED"] == "1" {
            let amountIncluded = try XCTUnwrap(candidatesByHandle["codex_mm_amount"]?.first)
            XCTAssertTrue(amountIncluded.attentionKinds.contains(.amountIncluded))
        }
    }
}
