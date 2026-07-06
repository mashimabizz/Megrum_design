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

    func testSearchResultAdInsertionAddsNativeAdAsEveryFifthDisplaySlot() {
        let results = makeSearchResults(count: 12)
        let entries = SearchResultAdInsertion.entries(for: results, includesNativeAds: true)

        XCTAssertEqual(entries.count, 14)
        XCTAssertEqual(entries[0], .goods(index: 0, results[0]))
        XCTAssertEqual(entries[3], .goods(index: 3, results[3]))
        XCTAssertEqual(entries[4], .nativeAd(slotIndex: 1))
        XCTAssertEqual(entries[8], .goods(index: 7, results[7]))
        XCTAssertEqual(entries[9], .nativeAd(slotIndex: 2))
        XCTAssertEqual(entries.last, .goods(index: 11, results[11]))
        XCTAssertEqual(entries.compactMap(\.goodsResult).count, results.count)
    }

    func testSearchResultAdInsertionDropsNativeAdsWhenNotAllowed() {
        let results = makeSearchResults(count: 6)
        let entries = SearchResultAdInsertion.entries(for: results, includesNativeAds: false)

        XCTAssertEqual(entries, results.enumerated().map { .goods(index: $0.offset, $0.element) })
    }

    func testSearchResultAdInsertionDoesNotAppendTrailingAdAfterExactDisplayInterval() {
        let results = makeSearchResults(count: 8)
        let entries = SearchResultAdInsertion.entries(for: results, includesNativeAds: true)

        XCTAssertEqual(entries.count, 9)
        XCTAssertEqual(entries[4], .nativeAd(slotIndex: 1))
        XCTAssertEqual(entries.last, .goods(index: 7, results[7]))
    }

    func testSearchResultGridLayoutMakesNativeAdUseTwoColumns() {
        let results = makeSearchResults(count: 9)
        let entries = SearchResultAdInsertion.entries(for: results, includesNativeAds: true)
        let rows = SearchResultGridLayout.rows(for: entries)

        XCTAssertEqual(rows.map { $0.cells.map(\.columnSpan) }, [
            [1, 1, 1],
            [1, 2],
            [1, 1, 1],
            [1, 2],
            [1]
        ])
        XCTAssertEqual(rows[1].cells.last?.entry, .nativeAd(slotIndex: 1))
        XCTAssertEqual(rows[3].cells.last?.entry, .nativeAd(slotIndex: 2))
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

    func testSearchScreenPresentationStateManagesQueryAndInitialCriteria() {
        let groupID = UUID(uuidString: "00000000-0000-0000-0000-000000000501")!
        let memberID = UUID(uuidString: "00000000-0000-0000-0000-000000000502")!
        let goodsTypeID = UUID(uuidString: "00000000-0000-0000-0000-000000000503")!
        let now = Date(timeIntervalSinceReferenceDate: 2_000)
        let criteria = SearchInitialCriteria(
            query: "  トレカ  ",
            groupID: groupID,
            memberID: memberID,
            goodsTypeID: goodsTypeID,
            tagNames: ["会場限定", "会場限定", "2026 LIVE"]
        )
        var draft = SearchFilterDraft(selectedMeetupPrefecture: "大阪府")
        var state = SearchScreenPresentationState()

        XCTAssertFalse(state.hasSubmittedQuery)

        state.queryDraft = "ラキドロ"
        state.submitQuery()

        XCTAssertEqual(state.query, "ラキドロ")
        XCTAssertTrue(state.hasSubmittedQuery)

        state.showFilters()
        XCTAssertTrue(state.isShowingFilters)

        state.beginSuggestionApplication()
        XCTAssertTrue(state.isApplyingSuggestion)
        state.finishSuggestionApplication()
        XCTAssertFalse(state.isApplyingSuggestion)

        state.markWishSuggestionHorizontalScroll(now: now)
        XCTAssertTrue(state.isBackSwipeSuppressed(now: now.addingTimeInterval(0.4)))
        XCTAssertFalse(state.isBackSwipeSuppressed(now: now.addingTimeInterval(1.2)))

        XCTAssertTrue(state.applyInitialCriteriaIfNeeded(criteria, filterDraft: &draft))
        XCTAssertEqual(state.query, "トレカ")
        XCTAssertEqual(state.queryDraft, "トレカ")
        XCTAssertEqual(draft.selectedGroupID, groupID)
        XCTAssertEqual(draft.selectedMemberID, memberID)
        XCTAssertEqual(draft.selectedGoodsTypeID, goodsTypeID)
        XCTAssertEqual(draft.selectedGoodsTagNames, ["会場限定", "2026 LIVE"])
        XCTAssertEqual(draft.selectedMeetupPrefecture, "大阪府")

        state.clearQuery()
        XCTAssertEqual(state.query, "")
        XCTAssertEqual(state.queryDraft, "")
        XCTAssertFalse(state.applyInitialCriteriaIfNeeded(criteria, filterDraft: &draft))
        XCTAssertEqual(state.query, "")
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


    func testSearchFilterDraftKeepsTagsIndependentFromGroupSelection() {
        let meetupDate = Date(timeIntervalSinceReferenceDate: 42)
        let draft = SearchFilterDraft(
            selectedGroupIDs: [],
            selectedGoodsTagNames: ["会場限定", "東京2026"],
            selectedPaymentMethods: [.paypay],
            meetupDateDraft: meetupDate,
            wantsMyGoodsOnly: true
        )

        XCTAssertNil(draft.selectedGroupID)
        XCTAssertEqual(draft.selectedGoodsTagNames, ["会場限定", "東京2026"])
        XCTAssertEqual(draft.activeFilterCount, 4)

        let reset = draft.reset()
        XCTAssertTrue(reset.selectedGoodsTagNames.isEmpty)
        XCTAssertEqual(reset.meetupDateDraft, meetupDate)
    }

    func testSearchFilterSheetStateManagesPresentationAndDefaultConditions() {
        let meetupDateDraft = Date(timeIntervalSinceReferenceDate: 42)
        let selectedMemberID = UUID(uuidString: "30000000-0000-0000-0000-000000000011")!
        let group = NativePreviewData.oshiGroups[0]
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        var state = SearchFilterSheetState(
            draft: SearchFilterDraft(
                selectedMemberIDs: [selectedMemberID],
                selectedGoodsTagNames: ["会場限定"],
                meetupDateDraft: meetupDateDraft
            )
        )

        XCTAssertFalse(state.hasSelectedGroup)
        XCTAssertEqual(state.selectedTagSummary, "1件")

        state.showTagPicker()
        XCTAssertTrue(state.isShowingTagPicker)

        state.selectGroup(group)
        XCTAssertEqual(state.draft.selectedGroupIDs, [group.id])
        XCTAssertNil(state.draft.selectedMemberID)
        // もう一度選ぶと解除（複数選択トグル）
        state.selectGroup(group)
        XCTAssertTrue(state.draft.selectedGroupIDs.isEmpty)
        state.selectGroup(group)

        let firstDate = calendar.date(from: DateComponents(year: 2026, month: 7, day: 3, hour: 18))!
        let sameDate = calendar.date(from: DateComponents(year: 2026, month: 7, day: 3, hour: 21))!
        let secondDate = calendar.date(from: DateComponents(year: 2026, month: 7, day: 2, hour: 12))!
        state.addMeetupDate(firstDate, calendar: calendar)
        state.addMeetupDate(sameDate, calendar: calendar)
        state.addMeetupDate(secondDate, calendar: calendar)

        XCTAssertEqual(
            state.draft.selectedMeetupDates,
            [
                calendar.startOfDay(for: secondDate),
                calendar.startOfDay(for: firstDate)
            ]
        )

        state.removeMeetupDate(sameDate, calendar: calendar)
        XCTAssertEqual(state.draft.selectedMeetupDates, [calendar.startOfDay(for: secondDate)])

        state.resetDraft()
        XCTAssertEqual(state.draft.meetupDateDraft, meetupDateDraft)
        XCTAssertNil(state.draft.selectedGroupID)
        XCTAssertTrue(state.draft.selectedGoodsTagNames.isEmpty)
    }

    func testSearchGoodsTagSelectionStateFiltersAndDetectsDuplicateSearchText() {
        var state = SearchGoodsTagSelectionState(searchText: " ＃2026 ")

        XCTAssertEqual(state.normalizedSearchText, "2026")
        XCTAssertEqual(
            state.filteredCandidateNames(from: ["2026 LIVE", "会場限定", "2025 LIVE"]),
            ["2026 LIVE"]
        )
        XCTAssertTrue(state.canAddSearchText(selectedTags: ["会場限定"]))
        XCTAssertFalse(state.canAddSearchText(selectedTags: ["2026"]))
        XCTAssertTrue(state.containsTag("2026 live", in: ["2026 LIVE"]))

        state.clearSearch()
        XCTAssertTrue(state.searchText.isEmpty)
        XCTAssertEqual(
            state.filteredCandidateNames(from: ["2026 LIVE", "会場限定"]),
            ["2026 LIVE", "会場限定"]
        )
        XCTAssertFalse(state.canAddSearchText(selectedTags: []))
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
            selectedGroupNames: [NativePreviewData.oshiGroups[0].name],
            selectedMemberNames: [NativePreviewData.oshiCharacters[0].name],
            selectedGoodsTypeNames: [NativePreviewData.goodsTypes[0].name],
            selectedGoodsTagNames: ["2026 LIVE"],
            selectedPaymentMethods: [.paypay],
            selectedExchangeMethod: .hand,
            selectedMeetupDates: [Date(timeIntervalSinceReferenceDate: 100)],
            selectedMeetupPrefecture: "大阪府",
            meetupPlaceMemo: "京セラ",
            shippingFee: "送料相談",
            shippingWindow: "2〜4日以内",
            allowsOutOfConditionProposal: true,
            wantsMyGoodsOnly: true,
            wantsCashOK: true
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
        XCTAssertTrue(chips.contains(SearchActiveCriteriaChipItem(title: "あなたのグッズを求む相手", removal: .demandMatch)))
        XCTAssertTrue(chips.contains(SearchActiveCriteriaChipItem(title: "定価交換OK", removal: .cashMatch)))
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

    func testSearchResultGridPresentationStateTracksSheetsReportsAndDeferredProfile() {
        let result = makeSearchResults(count: 1)[0]
        let sheet = SearchResultHomePresentation.sheet(
            for: result,
            index: 0,
            goodsTypes: [],
            explicitSignals: [:]
        )
        let profileUserID = UUID(uuidString: "00000000-0000-0000-0000-00000000AA02")!
        var state = SearchResultGridPresentationState()

        state.showSheet(sheet)

        XCTAssertNotNil(state.selectedSheet)

        state.requestProfilePresentation(userID: profileUserID)

        XCTAssertNil(state.selectedSheet)
        XCTAssertEqual(state.pendingProfileUserID, profileUserID)
        XCTAssertEqual(state.consumePendingProfileUserID(), profileUserID)
        XCTAssertNil(state.consumePendingProfileUserID())

        state.showSheet(sheet)
        state.requestProposalPresentation()

        XCTAssertNil(state.selectedSheet)

        state.showReport(item: result.item)

        XCTAssertEqual(state.reportTargetItem?.id, result.item.id)

        state.clearReport()

        XCTAssertNil(state.reportTargetItem)
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
            title: "推し外シリーズ付き",
            tags: [GoodsTag(id: UUID(), name: "推し外")]
        )
        let partnerTaggedItem = GoodsItem(
            id: UUID(),
            ownerID: NativePreviewData.partnerID,
            groupID: NativePreviewData.groupID,
            goodsTypeID: NativePreviewData.cardGoodsTypeID,
            title: "相手のシリーズ付き",
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
        XCTAssertTrue(sections.contains { $0.title == "ほしいものから探す" })
        XCTAssertTrue(sections.contains { $0.title == "シリーズから探す" })
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
            selectedMemberIDs: [],
            selectedGoodsTypeIDs: [],
            selectedGoodsTagNames: [],
            selectedPaymentMethods: [.paypay],
            selectedExchangeMethod: nil,
            selectedMeetupPrefecture: "",
            wantsMyGoodsOnly: false,
            wantsCashOK: false,
            listings: NativePreviewData.listings
        )

        XCTAssertTrue(payPayResults.contains { $0.item.title == "ニンニン 制服" })
        // iter1226.300: ほしいもの一致トグルは需要マッチへ置換されたため、支払一致のみで残る
        XCTAssertTrue(payPayResults.contains { $0.item.title == "V トレカ" })

        let bankTransferResults = SearchResultFilterPolicy.filteredResults(
            partnerResults,
            selectedMemberIDs: [],
            selectedGoodsTypeIDs: [],
            selectedGoodsTagNames: [],
            selectedPaymentMethods: [.bankTransfer],
            selectedExchangeMethod: nil,
            selectedMeetupPrefecture: "",
            wantsMyGoodsOnly: false,
            wantsCashOK: false,
            listings: NativePreviewData.listings
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
            selectedMemberIDs: [],
            selectedGoodsTypeIDs: [],
            selectedGoodsTagNames: [],
            selectedPaymentMethods: [],
            selectedExchangeMethod: nil,
            selectedMeetupPrefecture: "",
            wantsMyGoodsOnly: true,
            wantsCashOK: false,
            listings: NativePreviewData.publicListings,
            viewerInventory: viewerInventory
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
            SearchResultFilterPolicy.sortedResults(results, sort: .demand).first?.item.title,
            "ニンニン 制服"
        )
    }

    private func makeSearchResults(count: Int) -> [SearchResultItem] {
        let ownerID = UUID(uuidString: "00000000-0000-0000-0000-00000000AA01")!
        return (0..<count).map { index in
            let suffix = String(format: "%012d", index + 1)
            let item = GoodsItem(
                id: UUID(uuidString: "00000000-0000-0000-0000-\(suffix)")!,
                ownerID: ownerID,
                title: "検索結果\(index + 1)"
            )
            return SearchResultItem(item: item, ownerUserID: ownerID, bucket: .possible)
        }
    }
}
