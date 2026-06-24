@testable import MegrumApp
import MegrumData
import XCTest

final class HomeMutualMatchConditionPoliciesTests: XCTestCase {
    func testLocalExchangeKeepsCandidateButAddsDateDiscussionWhenEitherScheduleIsFlexible() throws {
        let evaluation = try exchangeEvaluation(
            viewer: summary(
                handoffMethod: .local,
                prefecture: "東京都",
                schedule: IndividualListingExchangeSummary.defaultLocalSchedule
            ),
            partner: summary(
                handoffMethod: .local,
                prefecture: "東京都",
                schedule: "6/28 18:00"
            )
        )

        XCTAssertEqual(evaluation.attentionKinds, [.dateNeedsDiscussion])
        XCTAssertTrue(evaluation.signals.localExchangeSelected)
        XCTAssertFalse(evaluation.signals.postalAcceptedByBoth)
        XCTAssertTrue(evaluation.signals.prefectureMatches)
        XCTAssertTrue(evaluation.signals.dateMatches)
        XCTAssertTrue(evaluation.signals.dateNeedsDiscussion)
    }

    func testLocalExchangeSignalOmitsBlankPlaceMemoForDisplay() throws {
        let evaluation = try exchangeEvaluation(
            viewer: summary(
                handoffMethod: .local,
                prefecture: "東京都",
                placeMemo: "",
                schedule: IndividualListingExchangeSummary.defaultLocalSchedule
            ),
            partner: summary(
                handoffMethod: .local,
                prefecture: "東京都",
                placeMemo: "東京ドーム",
                schedule: "6/28 18:00"
            )
        )

        XCTAssertEqual(evaluation.signals.viewerLocalConditionText, "東京都 / 相談して決める")
        XCTAssertEqual(evaluation.signals.partnerLocalConditionText, "東京都 / 東京ドーム / 6/28 18:00")
        XCTAssertFalse(evaluation.signals.viewerLocalConditionText?.contains("場所相談") == true)
    }

    func testLocalExchangeDoesNotAddDateDiscussionWhenSingleOverlappingDateIsDecided() throws {
        let evaluation = try exchangeEvaluation(
            viewer: summary(
                handoffMethod: .local,
                prefecture: "東京都",
                schedule: "6/28 18:00、6/29 13:00"
            ),
            partner: summary(
                handoffMethod: .local,
                prefecture: "東京都",
                schedule: "6/28 18:00"
            )
        )

        XCTAssertEqual(evaluation.attentionKinds, [])
        XCTAssertTrue(evaluation.signals.dateMatches)
        XCTAssertFalse(evaluation.signals.dateNeedsDiscussion)
    }

    func testLocalExchangeAddsPrefectureAndDateDiscussionWhenBothDiffer() throws {
        let evaluation = try exchangeEvaluation(
            viewer: summary(
                handoffMethod: .local,
                prefecture: "東京都",
                schedule: "6/28 18:00"
            ),
            partner: summary(
                handoffMethod: .both,
                prefecture: "大阪府",
                schedule: "6/29 18:00"
            )
        )

        XCTAssertEqual(evaluation.attentionKinds, [.prefectureNeedsDiscussion, .dateNeedsDiscussion])
        XCTAssertTrue(evaluation.signals.localExchangeSelected)
        XCTAssertFalse(evaluation.signals.prefectureMatches)
        XCTAssertFalse(evaluation.signals.dateMatches)
    }

    func testLocalExchangePrefectureUnsetDoesNotAddDateConcern() throws {
        let evaluation = try exchangeEvaluation(
            viewer: summary(
                handoffMethod: .local,
                prefecture: "",
                schedule: "6/28 18:00"
            ),
            partner: summary(
                handoffMethod: .local,
                prefecture: "東京都",
                schedule: "6/29 18:00"
            )
        )

        XCTAssertEqual(evaluation.attentionKinds, [.prefectureUnset])
        XCTAssertTrue(evaluation.signals.prefectureUnset)
        XCTAssertTrue(evaluation.signals.dateMatches)
    }

    func testExchangeMethodMismatchWhenNoCommonRouteExists() throws {
        let evaluation = try exchangeEvaluation(
            viewer: summary(handoffMethod: .local),
            partner: summary(handoffMethod: .mail)
        )

        XCTAssertEqual(evaluation.attentionKinds, [.exchangeMethodMismatch])
        XCTAssertFalse(evaluation.signals.localExchangeSelected)
        XCTAssertFalse(evaluation.signals.postalAcceptedByBoth)
    }

    func testMailExchangeShippingFeeMatrixUsesDiscussionNotMismatch() throws {
        let matched = try exchangeEvaluation(
            viewer: summary(handoffMethod: .mail, shippingFee: .owner),
            partner: summary(handoffMethod: .mail, shippingFee: .owner)
        )
        XCTAssertEqual(matched.attentionKinds, [])
        XCTAssertTrue(matched.signals.postalAcceptedByBoth)
        XCTAssertFalse(matched.signals.shippingFeeNeedsDiscussion)

        let needsDiscussion = try exchangeEvaluation(
            viewer: summary(handoffMethod: .mail, shippingFee: .owner),
            partner: summary(handoffMethod: .mail, shippingFee: .negotiate)
        )
        XCTAssertEqual(needsDiscussion.attentionKinds, [.shippingFeeNeedsDiscussion])
        XCTAssertTrue(needsDiscussion.signals.shippingFeeNeedsDiscussion)
    }

    func testBothExchangeChoosesRouteWithFewerConcerns() throws {
        let localWins = try exchangeEvaluation(
            viewer: summary(
                handoffMethod: .both,
                prefecture: "東京都",
                schedule: "6/28 18:00",
                shippingFee: .negotiate
            ),
            partner: summary(
                handoffMethod: .both,
                prefecture: "東京都",
                schedule: "6/28 18:00",
                shippingFee: .negotiate
            )
        )
        XCTAssertEqual(localWins.attentionKinds, [])
        XCTAssertTrue(localWins.signals.localExchangeSelected)
        XCTAssertFalse(localWins.signals.postalAcceptedByBoth)

        let mailWins = try exchangeEvaluation(
            viewer: summary(
                handoffMethod: .both,
                prefecture: "東京都",
                schedule: "6/28 18:00",
                shippingFee: .negotiate
            ),
            partner: summary(
                handoffMethod: .both,
                prefecture: "東京都",
                schedule: "6/29 18:00",
                shippingFee: .negotiate
            )
        )
        XCTAssertEqual(mailWins.attentionKinds, [.shippingFeeNeedsDiscussion])
        XCTAssertFalse(mailWins.signals.localExchangeSelected)
        XCTAssertTrue(mailWins.signals.postalAcceptedByBoth)
        XCTAssertTrue(mailWins.signals.localRouteAvailable)
        XCTAssertFalse(mailWins.signals.localRouteDateMatches)
        XCTAssertTrue(mailWins.signals.localRouteDateNeedsDiscussion)
    }

    func testReviewPointShowsLocalConditionConcernsEvenWhenMailRouteWins() throws {
        let evaluation = try exchangeEvaluation(
            viewer: summary(
                handoffMethod: .both,
                prefecture: "東京都",
                schedule: "6/28 18:00",
                shippingFee: .negotiate
            ),
            partner: summary(
                handoffMethod: .both,
                prefecture: "東京都",
                schedule: "6/29 18:00",
                shippingFee: .negotiate
            )
        )
        let pair = HomeMutualMatchProposalPair(
            id: "local-concern-mail-wins",
            receiverGoods: HomeDiscoveryFixtures.selectedYellow,
            senderGoods: HomeDiscoveryFixtures.offerGoods[0],
            receiverDisplayItem: .goods(HomeDiscoveryFixtures.selectedYellow),
            senderDisplayItem: .goods(HomeDiscoveryFixtures.offerGoods[0]),
            signals: HomeCandidateConditionSignals(
                goods: HomeGoodsConditionSignals(hasIndividualListingHit: true, hasWishHit: false),
                exchange: evaluation.signals
            )
        )
        let review = HomeMutualMatchConditionReviewPolicy.review(for: pair)
        let localPoint = try XCTUnwrap(
            HomeMutualMatchConditionReviewPointPolicy.points(for: pair, review: review)
                .first { $0.title == "現地交換条件" }
        )

        XCTAssertEqual(localPoint.tagTitle, "日程要相談")
        XCTAssertEqual(localPoint.partnerValue, "東京都 / 6/29 18:00")
        XCTAssertEqual(localPoint.viewerValue, "東京都 / 6/28 18:00")
        XCTAssertEqual(localPoint.status, .needsDecision)
    }

    func testPaymentConditionMatrixOnlyRunsWhenMoneyIsIncluded() {
        let skipped = HomeMutualMatchConditionPolicy.paymentEvaluation(
            viewerMethods: [],
            partnerMethods: [],
            requiresPayment: false
        )
        XCTAssertEqual(skipped.signals.status, .skipped)
        XCTAssertEqual(skipped.attentionKinds, [])

        let compatible = HomeMutualMatchConditionPolicy.paymentEvaluation(
            viewerMethods: ["bank_transfer", "paypay"],
            partnerMethods: ["paypay"],
            requiresPayment: true
        )
        XCTAssertEqual(compatible.signals.status, .compatible)
        XCTAssertEqual(compatible.attentionKinds, [])

        let mismatch = HomeMutualMatchConditionPolicy.paymentEvaluation(
            viewerMethods: ["bank_transfer"],
            partnerMethods: ["paypay"],
            requiresPayment: true
        )
        XCTAssertEqual(mismatch.signals.status, .methodMismatch)
        XCTAssertEqual(mismatch.attentionKinds, [.paymentMethodMismatch])

        let viewerUnset = HomeMutualMatchConditionPolicy.paymentEvaluation(
            viewerMethods: [],
            partnerMethods: ["paypay"],
            requiresPayment: true
        )
        XCTAssertEqual(viewerUnset.signals.status, .viewerUnset)
        XCTAssertEqual(viewerUnset.attentionKinds, [.viewerPaymentUnset])

        let partnerUnset = HomeMutualMatchConditionPolicy.paymentEvaluation(
            viewerMethods: ["paypay"],
            partnerMethods: [],
            requiresPayment: true
        )
        XCTAssertEqual(partnerUnset.signals.status, .partnerUnset)
        XCTAssertEqual(partnerUnset.attentionKinds, [.partnerPaymentUnset])

        let bothUnset = HomeMutualMatchConditionPolicy.paymentEvaluation(
            viewerMethods: [],
            partnerMethods: [],
            requiresPayment: true
        )
        XCTAssertEqual(bothUnset.signals.status, .unset)
        XCTAssertEqual(bothUnset.attentionKinds, [.paymentUnset])

        let otherOnly = HomeMutualMatchConditionPolicy.paymentEvaluation(
            viewerMethods: ["other"],
            partnerMethods: ["paypay"],
            requiresPayment: true
        )
        XCTAssertEqual(otherOnly.signals.status, .needsDiscussion)
        XCTAssertEqual(otherOnly.attentionKinds, [.paymentMethodNeedsDiscussion])
    }

    private func exchangeEvaluation(
        viewer: IndividualListingExchangeSummary,
        partner: IndividualListingExchangeSummary
    ) throws -> HomeMutualMatchExchangeEvaluation {
        try HomeMutualMatchConditionPolicy.exchangeEvaluation(
            viewerListing: listing(idTail: "101", note: viewer.storageLine),
            viewerUser: user(idTail: "201", primaryArea: viewer.localPrefecture),
            partnerListing: listing(idTail: "102", note: partner.storageLine),
            partnerUser: user(idTail: "202", primaryArea: partner.localPrefecture)
        )
    }

    private func summary(
        handoffMethod: IndividualListingHandoffDraft,
        prefecture: String = "東京都",
        placeMemo: String = "",
        schedule: String = IndividualListingExchangeSummary.defaultLocalSchedule,
        shippingFee: IndividualListingShippingFeeDraft = .owner
    ) -> IndividualListingExchangeSummary {
        IndividualListingExchangeSummary(
            handoffMethod: handoffMethod,
            localPrefecture: prefecture,
            localPlaceMemo: placeMemo,
            localSchedule: schedule,
            shippingFee: shippingFee,
            shippingDays: .twoToFourDays
        )
    }

    private func listing(idTail: String, note: String) throws -> SupabaseHomeListingRow {
        try decode(
            SupabaseHomeListingRow.self,
            [
                "id": "50000000-0000-0000-0000-000000000\(idTail)",
                "userId": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
                "haveIds": [],
                "haveQtys": [],
                "haveLogic": "or",
                "haveGroupId": nil,
                "haveGoodsTypeId": nil,
                "status": "active",
                "note": note,
                "createdAt": nil,
                "updatedAt": nil
            ]
        )
    }

    private func user(idTail: String, primaryArea: String) throws -> SupabaseHomeUserRow {
        try decode(
            SupabaseHomeUserRow.self,
            [
                "id": "60000000-0000-0000-0000-000000000\(idTail)",
                "handle": "user_\(idTail)",
                "displayName": "user_\(idTail)",
                "primaryArea": primaryArea,
                "avatarUrl": nil,
                "paymentMethods": [],
                "paymentNote": nil,
                "isTestAccount": nil
            ]
        )
    }

    private func decode<T: Decodable>(_ type: T.Type, _ payload: [String: Any?]) throws -> T {
        let data = try JSONSerialization.data(withJSONObject: payload.compactMapValues { $0 }, options: [])
        return try JSONDecoder().decode(T.self, from: data)
    }
}
