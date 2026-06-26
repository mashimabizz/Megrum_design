@testable import MegrumApp
import MegrumCore
import XCTest

final class SearchScreenTests: XCTestCase {
    func testSearchFooterUsesGroupedGlassSpacing() {
        XCTAssertEqual(SearchLayoutMetrics.footerGlassGroupSpacing, 12)
        XCTAssertGreaterThan(SearchFilterBadgeLayering.badgeZIndex, SearchFilterBadgeLayering.surfaceZIndex)
    }

    func testSearchCriteriaRequiresQueryOrFilter() {
        XCTAssertFalse(SearchCriteriaResolver.hasCriteria(query: "", activeFilterCount: 0))
        XCTAssertFalse(SearchCriteriaResolver.hasCriteria(query: " \n ", activeFilterCount: 0))
        XCTAssertTrue(SearchCriteriaResolver.hasCriteria(query: "トレカ", activeFilterCount: 0))
        XCTAssertTrue(SearchCriteriaResolver.hasCriteria(query: "", activeFilterCount: 1))
    }

    func testSearchBackSwipeDismissesOnlyForClearRightSwipe() {
        XCTAssertTrue(
            SearchBackSwipeResolver.shouldDismiss(
                translation: CGSize(width: 90, height: 8),
                predictedEndTranslationWidth: 104
            )
        )
        XCTAssertTrue(
            SearchBackSwipeResolver.shouldDismiss(
                translation: CGSize(width: 42, height: 4),
                predictedEndTranslationWidth: 130
            )
        )
        XCTAssertFalse(
            SearchBackSwipeResolver.shouldDismiss(
                translation: CGSize(width: -120, height: 4),
                predictedEndTranslationWidth: -150
            )
        )
        XCTAssertFalse(
            SearchBackSwipeResolver.shouldDismiss(
                translation: CGSize(width: 80, height: 90),
                predictedEndTranslationWidth: 140
            )
        )
        XCTAssertFalse(
            SearchBackSwipeResolver.shouldDismiss(
                translation: CGSize(width: 90, height: 8),
                predictedEndTranslationWidth: 104,
                isSuppressedByNestedHorizontalScroll: true
            )
        )
    }

    func testSearchBackSwipeSuppressionTracksNestedHorizontalScroll() {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)

        XCTAssertTrue(SearchBackSwipeResolver.isNestedHorizontalScroll(translation: CGSize(width: 90, height: 8)))
        XCTAssertTrue(SearchBackSwipeResolver.isNestedHorizontalScroll(translation: CGSize(width: -90, height: 8)))
        XCTAssertFalse(SearchBackSwipeResolver.isNestedHorizontalScroll(translation: CGSize(width: 18, height: 90)))
        XCTAssertFalse(SearchBackSwipeResolver.isSuppressedByNestedHorizontalScroll(lastNestedHorizontalScrollDate: nil, now: now))
        XCTAssertTrue(
            SearchBackSwipeResolver.isSuppressedByNestedHorizontalScroll(
                lastNestedHorizontalScrollDate: now.addingTimeInterval(-0.4),
                now: now
            )
        )
        XCTAssertFalse(
            SearchBackSwipeResolver.isSuppressedByNestedHorizontalScroll(
                lastNestedHorizontalScrollDate: now.addingTimeInterval(-1.2),
                now: now
            )
        )
    }

    func testSearchQueryResolverUsesGoodsTypeOrTagInsteadOfTitleOnlyQuery() {
        let goodsTypeID = SearchQueryResolver.matchingGoodsTypeID(
            query: "トレカ",
            goodsTypes: NativePreviewData.goodsTypes
        )
        XCTAssertEqual(goodsTypeID, NativePreviewData.cardGoodsTypeID)
        XCTAssertEqual(
            SearchQueryResolver.backendQuery(
                query: "トレカ",
                matchedGoodsTypeID: goodsTypeID,
                matchedTagName: nil
            ),
            ""
        )

        let tagName = SearchQueryResolver.matchingTagName(
            query: "2026 LIVE",
            tagNames: NativePreviewData.tags.map(\.name)
        )
        XCTAssertEqual(tagName, "2026 LIVE")
        XCTAssertEqual(
            SearchQueryResolver.backendQuery(
                query: "2026 LIVE",
                matchedGoodsTypeID: nil,
                matchedTagName: tagName
            ),
            ""
        )

        XCTAssertEqual(
            SearchQueryResolver.backendQuery(
                query: "サナ",
                matchedGoodsTypeID: nil,
                matchedTagName: nil
            ),
            "サナ"
        )
    }

    func testSearchSuggestionTagPolicyAllowsOnlySharedTagCandidates() {
        let tagNames = SearchSuggestionTagPolicy.allowedRequestedTagNames(
            ["相手だけ", "トレカ", "推し外"],
            candidateTagNames: ["トレカ", "会場限定"],
            limit: 3
        )

        XCTAssertEqual(tagNames, ["トレカ"])
    }

    func testConditionMatchFilterSummaryUsesUserFacingMatchLabels() {
        let filters = SearchConditionMatchFilters(
            matchesWish: true,
            matchesIndividualListing: true,
            matchesExchangeCondition: true,
            matchesPaymentCondition: true
        )

        XCTAssertEqual(filters.activeCount, 4)
        XCTAssertEqual(filters.summaryTitles, ["グッズ○", "グッズ◎", "交換条件一致", "支払条件一致"])
        XCTAssertEqual(SearchFilterPresentation.individualListingMatchTitle, "相手の個別募集に合う")
    }

    func testSearchFilterDraftKeepsTagsIndependentFromGroupSelection() {
        let meetupDate = Date(timeIntervalSinceReferenceDate: 42)
        let draft = SearchFilterDraft(
            selectedGroupID: nil,
            selectedGoodsTagNames: ["会場限定", "東京2026"],
            selectedPaymentMethods: [.paypay],
            meetupDateDraft: meetupDate,
            conditionMatches: SearchConditionMatchFilters(matchesIndividualListing: true)
        )

        XCTAssertNil(draft.selectedGroupID)
        XCTAssertEqual(draft.selectedGoodsTagNames, ["会場限定", "東京2026"])
        XCTAssertEqual(draft.activeFilterCount, 4)

        let reset = draft.reset()
        XCTAssertTrue(reset.selectedGoodsTagNames.isEmpty)
        XCTAssertEqual(reset.meetupDateDraft, meetupDate)
    }

    func testSearchFilterUsesCurrentShippingFeeChoices() {
        XCTAssertEqual(
            IndividualListingShippingFeeDraft.selectableCases.map(\.title),
            ["自己負担", "要相談"]
        )
    }

    func testActiveCriteriaChipsCarryRemovableFilterIdentity() {
        let chips = SearchActiveCriteriaChipBuilder.chips(
            query: " BTS ",
            selectedGroup: NativePreviewData.oshiGroups.first,
            selectedMember: NativePreviewData.oshiCharacters.first,
            selectedGoodsType: NativePreviewData.goodsTypes.first,
            selectedGoodsTagNames: ["2026 LIVE"],
            selectedPaymentMethods: [.paypay],
            selectedExchangeMethod: .hand,
            selectedMeetupDates: [Date(timeIntervalSinceReferenceDate: 100)],
            selectedMeetupPrefecture: "大阪府",
            meetupPlaceMemo: "京セラ",
            shippingFee: "送料相談",
            shippingWindow: "2〜4日以内",
            allowsOutOfConditionProposal: true,
            conditionMatches: SearchConditionMatchFilters(
                matchesWish: true,
                matchesIndividualListing: true,
                matchesExchangeCondition: true,
                matchesPaymentCondition: true
            )
        )

        XCTAssertTrue(chips.contains(SearchActiveCriteriaChipItem(title: "BTS", removal: .query)))
        XCTAssertTrue(chips.contains { $0.removal == .group })
        XCTAssertTrue(chips.contains { $0.removal == .member })
        XCTAssertTrue(chips.contains { $0.removal == .goodsType })
        XCTAssertTrue(chips.contains(SearchActiveCriteriaChipItem(title: "2026 LIVE", removal: .goodsTag("2026 LIVE"))))
        XCTAssertTrue(chips.contains(SearchActiveCriteriaChipItem(title: "PayPay", removal: .paymentMethod(.paypay))))
        XCTAssertTrue(chips.contains(SearchActiveCriteriaChipItem(title: "現地交換", removal: .exchangeMethod)))
        XCTAssertTrue(chips.contains(SearchActiveCriteriaChipItem(title: "日付1件", removal: .meetupDates)))
        XCTAssertTrue(chips.contains(SearchActiveCriteriaChipItem(title: "大阪府", removal: .meetupPrefecture)))
        XCTAssertTrue(chips.contains(SearchActiveCriteriaChipItem(title: "京セラ", removal: .meetupPlaceMemo)))
        XCTAssertTrue(chips.contains(SearchActiveCriteriaChipItem(title: "送料相談", removal: .shippingFee)))
        XCTAssertTrue(chips.contains(SearchActiveCriteriaChipItem(title: "2〜4日以内", removal: .shippingWindow)))
        XCTAssertTrue(chips.contains(SearchActiveCriteriaChipItem(title: "条件外打診可", removal: .allowsOutOfConditionProposal)))
        XCTAssertTrue(chips.contains(SearchActiveCriteriaChipItem(title: "グッズ○", removal: .conditionMatch(.wish))))
        XCTAssertTrue(chips.contains(SearchActiveCriteriaChipItem(title: "グッズ◎", removal: .conditionMatch(.individualListing))))
        XCTAssertTrue(chips.contains(SearchActiveCriteriaChipItem(title: "交換条件一致", removal: .conditionMatch(.exchangeCondition))))
        XCTAssertTrue(chips.contains(SearchActiveCriteriaChipItem(title: "支払条件一致", removal: .conditionMatch(.paymentCondition))))
    }

    func testSearchResultHomePresentationUsesHomeConditionSignalsAndSheets() {
        let item = NativePreviewData.inventory.first { $0.ownerID == NativePreviewData.partnerID }!
        let result = SearchResultItem(item: item, ownerUserID: item.ownerID, bucket: .possible)
        let explicitSignals = [
            item.id: HomeCandidateConditionSignalDefaults.matched(index: 0)
        ]

        let signals = SearchResultHomePresentation.signals(
            for: result,
            index: 0,
            explicitSignals: explicitSignals
        )
        XCTAssertEqual(HomeDiscoveryMatchPolicy.goodsCondition(for: signals.goods), .direct)

        let sheet = SearchResultHomePresentation.sheet(
            for: result,
            index: 0,
            goodsTypes: NativePreviewData.goodsTypes,
            explicitSignals: explicitSignals
        )
        switch sheet {
        case .goodsHit(let payload):
            XCTAssertEqual(payload.goods.id, item.id)
            XCTAssertEqual(payload.goods.imageURL, item.imageURL)
        default:
            XCTFail("個別募集でHitする検索結果はホームと同じgoodsHitシートへつなぐ")
        }
    }

    func testSearchSuggestionBuilderUsesOshiWishAndTagSources() {
        let nonOshiGroupID = UUID(uuidString: "00000000-0000-0000-0000-00000000a111")!
        let wishWithoutExplicitTags = WishItem(
            id: UUID(),
            ownerID: NativePreviewData.viewerID,
            groupID: NativePreviewData.groupID,
            goodsTypeID: NativePreviewData.photoGoodsTypeID,
            title: "カリナ 生写真",
            tags: []
        )
        let memberOnlyTaggedWish = WishItem(
            id: UUID(),
            ownerID: NativePreviewData.viewerID,
            memberID: NativePreviewData.memberID,
            goodsTypeID: NativePreviewData.cardGoodsTypeID,
            title: "カリナ メンバーだけ",
            tags: [GoodsTag(id: UUID(), name: "L2だけ")]
        )
        let nonOshiTaggedWish = WishItem(
            id: UUID(),
            ownerID: NativePreviewData.viewerID,
            groupID: nonOshiGroupID,
            goodsTypeID: NativePreviewData.cardGoodsTypeID,
            title: "推し外 Wish",
            tags: [GoodsTag(id: UUID(), name: "推し外Wish")]
        )
        let nonOshiTaggedItem = GoodsItem(
            id: UUID(),
            ownerID: NativePreviewData.viewerID,
            groupID: nonOshiGroupID,
            goodsTypeID: NativePreviewData.cardGoodsTypeID,
            title: "推し外タグ付き",
            tags: [GoodsTag(id: UUID(), name: "推し外")]
        )
        let partnerTaggedItem = GoodsItem(
            id: UUID(),
            ownerID: NativePreviewData.partnerID,
            groupID: NativePreviewData.groupID,
            goodsTypeID: NativePreviewData.cardGoodsTypeID,
            title: "相手のタグ付き",
            tags: [GoodsTag(id: UUID(), name: "相手だけ")]
        )

        let sections = SearchSuggestionBuilder.sections(
            userOshiSelections: [
                UserOshiSelection(
                    id: UUID(),
                    userID: NativePreviewData.viewerID,
                    groupID: NativePreviewData.groupID,
                    characterID: NativePreviewData.memberID,
                    kind: .specific,
                    priority: 1,
                    groupName: "aespa",
                    characterName: "カリナ"
                )
            ],
            oshiGroups: NativePreviewData.oshiGroups,
            oshiCharacters: NativePreviewData.oshiCharacters,
            wishes: NativePreviewData.wishes + [wishWithoutExplicitTags, memberOnlyTaggedWish, nonOshiTaggedWish],
            inventory: NativePreviewData.inventory + [partnerTaggedItem, nonOshiTaggedItem],
            viewer: NativePreviewData.viewer
        )

        XCTAssertTrue(sections.contains { $0.title == "推しから探す" })
        XCTAssertTrue(sections.contains { $0.title == "Wishから探す" })
        XCTAssertTrue(sections.contains { $0.title == "タグから探す" })
        XCTAssertFalse(sections.contains { $0.title == "よく使う条件" })
        let items = sections.flatMap { $0.items }
        XCTAssertTrue(items.contains { $0.title == "aespa" })
        XCTAssertTrue(items.contains { $0.title == "カリナ" })
        XCTAssertTrue(items.contains { $0.title == "スア ラキドロ" })
        XCTAssertTrue(items.contains { $0.title == "トレカ" })
        XCTAssertFalse(items.contains { $0.title == "生写真" })
        XCTAssertFalse(items.contains { $0.title == "L2だけ" })
        XCTAssertFalse(items.contains { $0.title == "推し外Wish" })
        XCTAssertFalse(items.contains { $0.title == "推し外" })
        XCTAssertFalse(items.contains { $0.title == "相手だけ" })
        XCTAssertTrue(items.contains { $0.title == "トレカ" && $0.action == .tag("トレカ") })
        XCTAssertFalse(items.contains { $0.title == "トレカ" && $0.action == .goodsType(NativePreviewData.cardGoodsTypeID) })

        let allAllowedTags = SearchSuggestionBuilder.tagCandidateNames(
            userOshiSelections: [
                UserOshiSelection(
                    id: UUID(),
                    userID: NativePreviewData.viewerID,
                    groupID: NativePreviewData.groupID,
                    characterID: NativePreviewData.memberID,
                    kind: .specific,
                    priority: 1,
                    groupName: "aespa",
                    characterName: "カリナ"
                )
            ],
            wishes: NativePreviewData.wishes + [nonOshiTaggedWish],
            inventory: NativePreviewData.inventory + [partnerTaggedItem, nonOshiTaggedItem],
            viewerID: NativePreviewData.viewerID
        )
        XCTAssertTrue(allAllowedTags.contains("トレカ"))
        XCTAssertFalse(allAllowedTags.contains("相手だけ"))
        XCTAssertFalse(allAllowedTags.contains("推し外"))
        XCTAssertFalse(allAllowedTags.contains("推し外Wish"))

        let selectedOshiGroupTags = SearchSuggestionBuilder.tagCandidateNames(
            userOshiSelections: [
                UserOshiSelection(
                    id: UUID(),
                    userID: NativePreviewData.viewerID,
                    groupID: NativePreviewData.groupID,
                    characterID: NativePreviewData.memberID,
                    kind: .specific,
                    priority: 1,
                    groupName: "aespa",
                    characterName: "カリナ"
                )
            ],
            wishes: NativePreviewData.wishes + [nonOshiTaggedWish],
            inventory: NativePreviewData.inventory + [partnerTaggedItem, nonOshiTaggedItem],
            viewerID: NativePreviewData.viewerID,
            limitingToGroupID: NativePreviewData.groupID
        )
        XCTAssertTrue(selectedOshiGroupTags.contains("トレカ"))

        let selectedNonOshiGroupTags = SearchSuggestionBuilder.tagCandidateNames(
            userOshiSelections: [
                UserOshiSelection(
                    id: UUID(),
                    userID: NativePreviewData.viewerID,
                    groupID: NativePreviewData.groupID,
                    characterID: NativePreviewData.memberID,
                    kind: .specific,
                    priority: 1,
                    groupName: "aespa",
                    characterName: "カリナ"
                )
            ],
            wishes: NativePreviewData.wishes + [nonOshiTaggedWish],
            inventory: NativePreviewData.inventory + [partnerTaggedItem, nonOshiTaggedItem],
            viewerID: NativePreviewData.viewerID,
            limitingToGroupID: nonOshiGroupID
        )
        XCTAssertTrue(selectedNonOshiGroupTags.isEmpty)
    }

    func testSearchResultFilterPolicyFiltersPaymentAndWishConditions() {
        let partnerResults = NativePreviewData.inventory
            .filter { $0.ownerID == NativePreviewData.partnerID }
            .map { SearchResultItem(item: $0, ownerUserID: $0.ownerID, bucket: .possible) }

        let payPayResults = SearchResultFilterPolicy.filteredResults(
            partnerResults,
            selectedMemberID: nil,
            selectedGoodsTypeID: nil,
            selectedGoodsTagNames: [],
            selectedPaymentMethods: [.paypay],
            selectedExchangeMethod: nil,
            selectedMeetupPrefecture: "",
            conditionMatches: SearchConditionMatchFilters(matchesWish: true),
            wishes: NativePreviewData.wishes,
            listings: NativePreviewData.listings,
            viewer: NativePreviewData.viewer
        )

        XCTAssertTrue(payPayResults.contains { $0.item.title == "ニンニン 制服" })
        XCTAssertFalse(payPayResults.contains { $0.item.title == "V トレカ" })

        let bankTransferResults = SearchResultFilterPolicy.filteredResults(
            partnerResults,
            selectedMemberID: nil,
            selectedGoodsTypeID: nil,
            selectedGoodsTagNames: [],
            selectedPaymentMethods: [.bankTransfer],
            selectedExchangeMethod: nil,
            selectedMeetupPrefecture: "",
            conditionMatches: SearchConditionMatchFilters(),
            wishes: NativePreviewData.wishes,
            listings: NativePreviewData.listings,
            viewer: NativePreviewData.viewer
        )

        XCTAssertTrue(bankTransferResults.isEmpty)
    }

    func testIndividualListingConditionUsesPartnerListingAndViewerInventoryLikeHomeGoodsDirect() {
        let viewerInventory = NativePreviewData.inventory.filter { $0.ownerID == NativePreviewData.viewerID }
        let partnerResults = NativePreviewData.inventory
            .filter { $0.ownerID == NativePreviewData.partnerID }
            .map { SearchResultItem(item: $0, ownerUserID: $0.ownerID, bucket: .possible) }

        let directlyMatchingItem = NativePreviewData.inventory[2]
        let unrelatedPartnerItem = NativePreviewData.inventory.first { $0.title == "V トレカ" }!

        XCTAssertTrue(
            SearchResultFilterPolicy.itemMatchesPartnerIndividualListings(
                directlyMatchingItem,
                listings: NativePreviewData.publicListings,
                viewerInventory: viewerInventory
            )
        )
        XCTAssertFalse(
            SearchResultFilterPolicy.itemMatchesPartnerIndividualListings(
                unrelatedPartnerItem,
                listings: NativePreviewData.publicListings,
                viewerInventory: viewerInventory
            )
        )
        XCTAssertFalse(
            SearchResultFilterPolicy.itemMatchesPartnerIndividualListings(
                directlyMatchingItem,
                listings: NativePreviewData.listings,
                viewerInventory: viewerInventory
            )
        )

        let filtered = SearchResultFilterPolicy.filteredResults(
            partnerResults,
            selectedMemberID: nil,
            selectedGoodsTypeID: nil,
            selectedGoodsTagNames: [],
            selectedPaymentMethods: [],
            selectedExchangeMethod: nil,
            selectedMeetupPrefecture: "",
            conditionMatches: SearchConditionMatchFilters(matchesIndividualListing: true),
            wishes: NativePreviewData.wishes,
            listings: NativePreviewData.publicListings,
            viewerInventory: viewerInventory,
            viewer: NativePreviewData.viewer
        )

        XCTAssertTrue(filtered.contains { $0.item.title == "サナ 2026 LIVE" })
        XCTAssertTrue(filtered.contains { $0.item.title == "ニンニン 制服" })
        XCTAssertFalse(filtered.contains { $0.item.title == "V トレカ" })
    }

    func testSearchResultSortPrioritizesMegrumPlusOwners() {
        var standardItem = NativePreviewData.inventory.first { $0.title == "V トレカ" }!
        standardItem.ownerHasMegrumPlus = false
        var plusItem = NativePreviewData.inventory.first { $0.title == "ニンニン 制服" }!
        plusItem.ownerHasMegrumPlus = true
        let results = [
            SearchResultItem(item: standardItem, ownerUserID: standardItem.ownerID, bucket: .possible),
            SearchResultItem(item: plusItem, ownerUserID: plusItem.ownerID, bucket: .possible)
        ]

        XCTAssertEqual(
            SearchResultFilterPolicy.sortedResults(results, sort: .newest).map(\.item.title),
            ["ニンニン 制服", "V トレカ"]
        )
        XCTAssertEqual(
            SearchResultFilterPolicy.sortedResults(results, sort: .title).first?.item.title,
            "ニンニン 制服"
        )
    }
}
