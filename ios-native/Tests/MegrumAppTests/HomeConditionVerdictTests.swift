import XCTest
import MegrumCore
@testable import MegrumApp

final class HomeConditionVerdictTests: XCTestCase {
    // MARK: - お金

    func testCompatibleBankTransferBoldsSharedBank() {
        let payment = HomePaymentConditionSignals(
            hasCompatiblePaymentMethod: true,
            status: .compatible,
            viewerMethods: [.bankTransfer],
            partnerMethods: [.bankTransfer],
            partnerBankNames: ["みずほ銀行", "楽天銀行"],
            viewerBankNames: ["みずほ"] // 表記ゆれでもマスタ経由で一致
        )
        let line = paymentLine(payment)

        XCTAssertEqual(line?.badge, .ok)
        XCTAssertEqual(line?.plainText, "銀行振込（みずほ銀行・楽天銀行）がお互い共通")

        let mizuho = line?.segments.first { $0.text == "みずほ銀行" }
        let rakuten = line?.segments.first { $0.text == "楽天銀行" }
        XCTAssertEqual(mizuho?.bold, true, "自分と同じ銀行は太字")
        XCTAssertEqual(rakuten?.bold, false, "共通しない銀行は太字にしない")
    }

    func testViewerUnsetSurfacesPartnerMethods() {
        let payment = HomePaymentConditionSignals(
            hasCompatiblePaymentMethod: false,
            status: .viewerUnset,
            viewerMethods: [],
            partnerMethods: [.paypay, .bankTransfer],
            partnerBankNames: ["みずほ銀行"],
            viewerBankNames: []
        )
        let line = paymentLine(payment)

        XCTAssertEqual(line?.badge, .needsTalk)
        // 方法は UserPaymentMethod.allCases 順（銀行振込→PayPay）で正準化される。
        XCTAssertEqual(line?.plainText, "相手は 銀行振込（みずほ銀行）・PayPay でOK")
        XCTAssertEqual(line?.subtitle, "あなたの支払い方法を決めれば打診できます")
    }

    func testMethodMismatchUsesCheckBadge() {
        let payment = HomePaymentConditionSignals(
            hasCompatiblePaymentMethod: false,
            status: .methodMismatch,
            viewerMethods: [.paypay],
            partnerMethods: [.cashExchange]
        )
        let line = paymentLine(payment)

        XCTAssertEqual(line?.badge, .check)
        XCTAssertEqual(line?.plainText, "相手は 現金の手渡し のみ")
    }

    func testSkippedPaymentHidesLine() {
        let verdict = HomeConditionVerdictPolicy.make(from: signals(payment: .none))
        XCTAssertNil(verdict.lines.first { $0.kind == .payment })
    }

    // MARK: - 郵送

    func testMailSelfBearIsOkWithShippingDays() {
        let exchange = HomeExchangeConditionSignals(
            postalAcceptedByBoth: true,
            localExchangeSelected: false,
            prefectureMatches: false,
            dateMatches: false,
            partnerShippingFeeTitle: "自己負担",
            partnerShippingDaysTitle: "2〜4日以内"
        )
        let line = HomeConditionVerdictPolicy.make(from: signals(exchange: exchange))
            .lines.first { $0.kind == .mail }

        XCTAssertEqual(line?.badge, .ok)
        XCTAssertEqual(line?.plainText, "郵送でもOK")
        XCTAssertEqual(line?.subtitle, "互いに送料を負担 ・ 2〜4日以内に発送")
    }

    func testMailNegotiateIsNeedsTalk() {
        let exchange = HomeExchangeConditionSignals(
            postalAcceptedByBoth: true,
            localExchangeSelected: false,
            prefectureMatches: false,
            dateMatches: false,
            shippingFeeNeedsDiscussion: true,
            partnerShippingFeeTitle: "要相談",
            partnerShippingDaysTitle: "2〜4日以内"
        )
        let line = HomeConditionVerdictPolicy.make(from: signals(exchange: exchange))
            .lines.first { $0.kind == .mail }

        XCTAssertEqual(line?.badge, .needsTalk)
        XCTAssertEqual(line?.subtitle, "送料は取引成立までに決める ・ 2〜4日以内に発送")
    }

    func testMailUnknownFeeDefaultsToNeedsTalk() {
        let exchange = HomeExchangeConditionSignals(
            postalAcceptedByBoth: true,
            localExchangeSelected: false,
            prefectureMatches: false,
            dateMatches: false
        )
        let line = HomeConditionVerdictPolicy.make(from: signals(exchange: exchange))
            .lines.first { $0.kind == .mail }

        XCTAssertEqual(line?.badge, .needsTalk, "送料が不明な時は安全側で要相談")
        XCTAssertEqual(line?.subtitle, "送料は取引成立までに決める")
    }

    // MARK: - 現地

    func testLocalConfirmedWithMultipleDatesUsesHokaWording() {
        let calendar = Calendar.current
        let keys = Set([5, 12, 19].compactMap { offset -> String? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: Date()) else {
                return nil
            }
            return HomeExchangeDateKey.key(for: date)
        })
        let exchange = HomeExchangeConditionSignals(
            postalAcceptedByBoth: false,
            localExchangeSelected: true,
            prefectureMatches: true,
            dateMatches: true,
            partnerLocalPrefectures: ["大阪府"],
            matchedLocalDateKeys: keys
        )
        let line = HomeConditionVerdictPolicy.make(from: signals(exchange: exchange))
            .lines.first { $0.kind == .local }

        XCTAssertEqual(line?.badge, .ok)
        XCTAssertEqual(line?.showsCalendarButton, true, "重なっていてもカレンダー導線は出す")
        XCTAssertTrue(line?.plainText.hasPrefix("大阪府で") ?? false)
        XCTAssertTrue(line?.plainText.contains("ほか2日に会える") ?? false, line?.plainText ?? "nil")
    }

    // MARK: - 打診メッセージ自動生成

    func testSuggestedMessageListsUndecidedItems() {
        let exchange = HomeExchangeConditionSignals(
            postalAcceptedByBoth: false,
            localExchangeSelected: true,
            prefectureMatches: false,
            dateMatches: false,
            prefectureUnset: true
        )
        let payment = HomePaymentConditionSignals(
            hasCompatiblePaymentMethod: false,
            status: .viewerUnset,
            viewerMethods: [],
            partnerMethods: [.paypay]
        )
        let verdict = HomeConditionVerdictPolicy.make(from: signals(exchange: exchange, payment: payment))
        let message = ProposalSuggestedMessageBuilder.make(from: verdict)

        XCTAssertNotNil(message)
        XCTAssertTrue(message?.contains("会う日程・場所") ?? false, message ?? "nil")
        XCTAssertTrue(message?.contains("お支払い方法") ?? false, message ?? "nil")
        XCTAssertTrue(message?.contains("取引成立までに相談") ?? false, message ?? "nil")
    }

    func testSuggestedMessageNilWhenAllDecided() {
        let calendar = Calendar.current
        let futureKey = calendar.date(byAdding: .day, value: 5, to: Date())
            .map { HomeExchangeDateKey.key(for: $0) } ?? ""
        let exchange = HomeExchangeConditionSignals(
            postalAcceptedByBoth: true,
            localExchangeSelected: true,
            prefectureMatches: true,
            dateMatches: true,
            partnerShippingFeeTitle: "自己負担",
            partnerLocalPrefectures: ["大阪府"],
            matchedLocalDateKeys: [futureKey]
        )
        let payment = HomePaymentConditionSignals(
            hasCompatiblePaymentMethod: true,
            status: .compatible,
            viewerMethods: [.paypay],
            partnerMethods: [.paypay]
        )
        let verdict = HomeConditionVerdictPolicy.make(from: signals(exchange: exchange, payment: payment))

        XCTAssertNil(ProposalSuggestedMessageBuilder.make(from: verdict))
    }

    // MARK: - Helpers

    private func paymentLine(_ payment: HomePaymentConditionSignals) -> ConditionVerdictLine? {
        HomeConditionVerdictPolicy.make(from: signals(payment: payment))
            .lines.first { $0.kind == .payment }
    }

    private func signals(
        exchange: HomeExchangeConditionSignals = HomeExchangeConditionSignals(
            postalAcceptedByBoth: false,
            localExchangeSelected: false,
            prefectureMatches: false,
            dateMatches: false
        ),
        payment: HomePaymentConditionSignals = .none
    ) -> HomeCandidateConditionSignals {
        HomeCandidateConditionSignals(
            goods: HomeGoodsConditionSignals(hasIndividualListingHit: true, hasWishHit: false),
            exchange: exchange,
            payment: payment
        )
    }
}
