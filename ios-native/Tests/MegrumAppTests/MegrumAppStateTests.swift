import MegrumApp
import MegrumCore
import MegrumData
import XCTest

@MainActor
final class MegrumAppStateTests: XCTestCase {
    func testPreviewStateLoadsInitialSnapshot() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())

        await state.loadInitialData()

        XCTAssertEqual(state.viewer?.handle, "michilion")
        XCTAssertFalse(state.inventory.isEmpty)
        XCTAssertFalse(state.wishes.isEmpty)
        XCTAssertFalse(state.listings.isEmpty)
        XCTAssertFalse(state.proposals.isEmpty)
        XCTAssertFalse(state.grooms.isEmpty)
        XCTAssertFalse(state.threads.isEmpty)
        XCTAssertFalse(state.isLoading)
        XCTAssertNil(state.errorMessage)
    }

    func testAppStateCreatesPreviewIndividualListing() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())

        await state.loadInitialData()
        let initialCount = state.listings.count
        let created = await state.createIndividualListing(
            IndividualListingCreateInput(
                haveItems: [
                    ListingItemQuantity(itemID: state.inventory[0].id, quantity: 1)
                ],
                haveLogic: .all,
                wishItems: [
                    ListingItemQuantity(itemID: state.wishes[0].id, quantity: 1)
                ],
                wishLogic: .one,
                exchangeType: .any,
                note: " 交換条件メモ "
            )
        )

        XCTAssertTrue(created)
        XCTAssertEqual(state.listings.count, initialCount + 1)
        XCTAssertEqual(state.listings.first?.haves.first?.itemID, state.inventory[0].id)
        XCTAssertEqual(state.listings.first?.options.first?.wishes.first?.itemID, state.wishes[0].id)
        XCTAssertEqual(state.listings.first?.note, "交換条件メモ")
        XCTAssertFalse(state.isCreatingIndividualListing)
    }

    func testAppStateUpdatesPreviewIndividualListing() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())

        await state.loadInitialData()
        let listing = try! XCTUnwrap(state.listings.first)
        let updated = await state.updateIndividualListing(
            listingID: listing.id,
            primaryOptionID: listing.options.first?.id,
            input: IndividualListingCreateInput(
                haveItems: [
                    ListingItemQuantity(itemID: state.inventory[0].id, quantity: 2)
                ],
                wishItems: [
                    ListingItemQuantity(itemID: state.wishes[0].id, quantity: 1)
                ],
                note: " 更新しました "
            ),
            status: .paused
        )

        XCTAssertEqual(updated?.status, .paused)
        XCTAssertEqual(state.listings.first?.note, "更新しました")
        XCTAssertEqual(state.listings.first?.haves.first?.quantity, 2)
        XCTAssertNil(state.updatingIndividualListingID)
    }

    func testAppStateArchivesPreviewIndividualListingLocally() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())

        await state.loadInitialData()
        let listing = try! XCTUnwrap(state.listings.first)
        let initialCount = state.listings.count
        let archived = await state.archiveIndividualListing(listing.id)

        XCTAssertTrue(archived)
        XCTAssertEqual(state.listings.count, initialCount - 1)
        XCTAssertFalse(state.listings.contains { $0.id == listing.id })
        XCTAssertNil(state.updatingIndividualListingID)
    }

    func testAppStateCreatesPreviewScheduleForProposal() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())

        await state.loadInitialData()
        let proposal = try! XCTUnwrap(state.proposals.first)
        let initialCount = state.schedules(for: proposal.id).count
        let start = Date(timeIntervalSince1970: 1_780_160_000)

        let created = await state.createSchedule(
            PersonalScheduleCreateInput(
                title: " 物販列 ",
                placeName: " 北口 ",
                startAt: start,
                endAt: start.addingTimeInterval(3_600)
            ),
            for: proposal
        )

        XCTAssertTrue(created)
        XCTAssertEqual(state.schedules(for: proposal.id).count, initialCount + 1)
        XCTAssertEqual(state.schedules(for: proposal.id).last?.title, "物販列")
        XCTAssertEqual(state.schedules(for: proposal.id).last?.placeName, "北口")
        XCTAssertEqual(state.schedules(for: proposal.id).last?.userID, state.viewer?.id)
        XCTAssertFalse(state.isCreatingSchedule)
    }

    func testAppStateSendsPreviewLateNoticeWithMetadata() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())

        await state.loadInitialData()
        let proposal = try! XCTUnwrap(state.proposals.first)
        let initialCount = state.messages(for: proposal.id).count

        let sent = await state.sendLateNoticeMessage(
            proposalID: proposal.id,
            lateMinutes: 20,
            reason: " 電車遅延 ",
            note: " 北口へ向かっています "
        )

        let message = try! XCTUnwrap(state.messages(for: proposal.id).last)
        XCTAssertTrue(sent)
        XCTAssertEqual(state.messages(for: proposal.id).count, initialCount + 1)
        XCTAssertEqual(message.messageType, .system)
        XCTAssertEqual(message.body, "20分遅れる旨が通知されました\n理由：電車遅延\n北口へ向かっています")
        XCTAssertEqual(message.meta["action"], "late_notice")
        XCTAssertEqual(message.meta["late_minutes"], "20")
        XCTAssertEqual(message.meta["reason"], "電車遅延")
        XCTAssertNil(state.sendingMessageProposalID)
        XCTAssertNil(state.errorMessage)
    }

    func testAppStateSendsPreviewCancelRequestWithMetadata() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())

        await state.loadInitialData()
        let proposal = try! XCTUnwrap(state.proposals.first)
        let initialCount = state.messages(for: proposal.id).count

        let sent = await state.sendCancelRequestMessage(
            proposalID: proposal.id,
            reason: " 体調不良 ",
            note: nil
        )

        let message = try! XCTUnwrap(state.messages(for: proposal.id).last)
        XCTAssertTrue(sent)
        XCTAssertEqual(state.messages(for: proposal.id).count, initialCount + 1)
        XCTAssertEqual(message.messageType, .system)
        XCTAssertEqual(message.body, "取引キャンセルが申請されました\n理由：体調不良")
        XCTAssertEqual(message.meta["action"], "cancel_requested")
        XCTAssertEqual(message.meta["reason"], "体調不良")
        XCTAssertNil(state.sendingMessageProposalID)
        XCTAssertNil(state.errorMessage)
    }

    func testAppStateUpdatesPreviewOwnProfile() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())
        let birthDate = ProfileBirthDateCodec.date(from: "2002-04-12")

        await state.loadInitialData()
        let saved = await state.updateOwnProfile(
            OwnProfileUpdateInput(
                handle: " @Michi_New ",
                displayName: " みちりおん改 ",
                bio: " 交換よろしくお願いします ",
                gender: .noAnswer,
                prefecture: " 東京都 ",
                birthDate: birthDate,
                avatarURL: URL(string: "https://preview.megrum.jp/avatar.jpg")
            )
        )

        XCTAssertTrue(saved)
        XCTAssertEqual(state.viewer?.handle, "michi_new")
        XCTAssertEqual(state.viewer?.displayName, "みちりおん改")
        XCTAssertEqual(state.viewer?.bio, "交換よろしくお願いします")
        XCTAssertEqual(state.viewer?.gender, .female)
        XCTAssertEqual(state.viewer?.prefecture, "東京都")
        XCTAssertEqual(ProfileBirthDateCodec.string(from: state.viewer?.birthDate), "2002-04-12")
        XCTAssertEqual(state.viewer?.age, ProfileBirthDateCodec.age(from: birthDate))
        XCTAssertEqual(state.viewer?.avatarURL?.absoluteString, "https://preview.megrum.jp/avatar.jpg")
        XCTAssertFalse(state.isSavingOwnProfile)
        XCTAssertNil(state.errorMessage)
    }

    func testAppStateSavesPreviewPaymentSettings() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())

        await state.loadInitialData()
        let saved = await state.savePaymentSettings(
            UserPaymentSettings(
                userID: UUID(uuidString: "99999999-9999-9999-9999-999999999999")!,
                methods: [.other, .paypay],
                otherNote: "楽天ペイ相談可能"
            )
        )

        XCTAssertTrue(saved)
        XCTAssertEqual(state.paymentSettings?.methods, [.paypay, .other])
        XCTAssertEqual(state.paymentSettings?.otherNote, "楽天ペイ相談可能")
        XCTAssertEqual(state.viewer?.paymentMethods, [.paypay, .other])
        XCTAssertEqual(state.viewer?.paymentNote, "楽天ペイ相談可能")
        XCTAssertFalse(state.isSavingPaymentSettings)
        XCTAssertNil(state.errorMessage)
    }

    func testAppStateRequestsAccountDeletionThroughRepository() async {
        let repository = AccountDeletionRecordingRepository(proposals: [])
        let state = MegrumAppState(repository: repository)

        await state.loadInitialData()
        let requested = await state.requestAccountDeletion(
            AccountDeletionRequestInput(
                reasons: [.notUsing, .privacyConcern],
                note: "  少し休みます  "
            )
        )
        let recordedInputs = await repository.inputsSnapshot()

        XCTAssertTrue(requested)
        XCTAssertEqual(recordedInputs.count, 1)
        XCTAssertEqual(recordedInputs.first?.reasons, [.notUsing, .privacyConcern])
        XCTAssertEqual(recordedInputs.first?.note, "少し休みます")
        XCTAssertEqual(state.viewer?.accountStatus, .deletionRequested)
        XCTAssertFalse(state.isRequestingAccountDeletion)
        XCTAssertNil(state.errorMessage)
    }

    func testAppStateRejectsAccountDeletionWhenOngoingTradeExists() async {
        let viewerID = AccountDeletionRecordingRepository.viewerID
        let partnerID = AccountDeletionRecordingRepository.partnerID
        let repository = AccountDeletionRecordingRepository(
            proposals: [
                TradeProposal(
                    id: UUID(uuidString: "60000000-0000-0000-0000-000000000401")!,
                    senderID: viewerID,
                    receiverID: partnerID,
                    status: .agreed,
                    exchangeMethod: .hand,
                    senderGoodsIDs: [],
                    receiverGoodsIDs: []
                )
            ]
        )
        let state = MegrumAppState(repository: repository)

        await state.loadInitialData()
        let requested = await state.requestAccountDeletion(
            AccountDeletionRequestInput(reasons: [.tradeConcern])
        )
        let recordedInputs = await repository.inputsSnapshot()

        XCTAssertFalse(requested)
        XCTAssertTrue(recordedInputs.isEmpty)
        XCTAssertEqual(state.viewer?.accountStatus, .active)
        XCTAssertEqual(state.errorMessage, "現在進行中の取引があるため退会できません")
        XCTAssertFalse(state.isRequestingAccountDeletion)
    }

    func testAppStateRejectsInvalidOwnProfileHandle() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())

        await state.loadInitialData()
        let saved = await state.updateOwnProfile(
            OwnProfileUpdateInput(
                handle: "みち",
                displayName: "みちりおん",
                prefecture: "山形県"
            )
        )

        XCTAssertFalse(saved)
        XCTAssertEqual(state.viewer?.handle, "michilion")
        XCTAssertEqual(state.errorMessage, "ユーザーIDは半角英数字・_ の3〜20文字で入力してください")
    }

    func testAppStateLoadsPreviewPublicExchangeContent() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())
        let partnerID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

        await state.loadInitialData()
        await state.loadPublicExchangeContent(userID: partnerID)

        XCTAssertEqual(state.publicTradeGoodsByUserID[partnerID]?.first?.ownerID, partnerID)
        XCTAssertEqual(state.publicTradeGoodsByUserID[partnerID]?.count, 7)
        XCTAssertEqual(state.inventory.filter { $0.ownerID == partnerID }.count, 7)
        XCTAssertEqual(state.publicListingsByUserID[partnerID]?.first?.ownerID, partnerID)
        XCTAssertNil(state.loadingPublicExchangeUserID)
        XCTAssertNil(state.errorMessage)
    }

    func testFactoryFallsBackToPreviewWithoutSupabaseConfig() async {
        let state = MegrumAppStateFactory.make(environment: [:], infoDictionary: [:])

        await state.loadInitialData()

        XCTAssertEqual(state.viewer?.handle, "michilion")
        XCTAssertFalse(state.inventory.isEmpty)
    }

    func testFactoryFallsBackToPreviewWithUnresolvedSupabasePlaceholders() async {
        let state = MegrumAppStateFactory.make(
            environment: [:],
            infoDictionary: [
                "MegrumSupabaseURL": "$(MEGRUM_SUPABASE_URL)",
                "MegrumSupabasePublishableKey": "$(MEGRUM_SUPABASE_PUBLISHABLE_KEY)",
                "MegrumSupabaseViewerID": "$(MEGRUM_SUPABASE_VIEWER_ID)"
            ]
        )

        await state.loadInitialData()

        XCTAssertEqual(state.viewer?.handle, "michilion")
        XCTAssertFalse(state.inventory.isEmpty)
    }

    func testFactoryCanForceVisualQAPreviewRepositoryDespiteSupabaseConfig() async {
        let state = MegrumAppStateFactory.make(
            environment: [
                "MEGRUM_VISUAL_QA_PREVIEW_AUTH": "true",
                "MEGRUM_SUPABASE_URL": "https://example.supabase.co",
                "MEGRUM_SUPABASE_PUBLISHABLE_KEY": "sb_publishable_test",
                "MEGRUM_SUPABASE_VIEWER_ID": "00000000-0000-0000-0000-000000000000"
            ],
            infoDictionary: [:]
        )

        await state.loadInitialData()

        XCTAssertEqual(state.viewer?.handle, "michilion")
        XCTAssertFalse(state.inventory.isEmpty)
    }

    func testNativeInfoPlistDeclaresConfigurableURLScheme() throws {
        let plist = try Self.nativeInfoPlist()
        let urlTypes = try XCTUnwrap(plist["CFBundleURLTypes"] as? [[String: Any]])
        let schemes = urlTypes.flatMap { urlType in
            urlType["CFBundleURLSchemes"] as? [String] ?? []
        }

        XCTAssertEqual(schemes, ["$(MEGRUM_URL_SCHEME)"])
        XCTAssertEqual(plist["MegrumAuthEmailRedirectURL"] as? String, "$(MEGRUM_AUTH_EMAIL_REDIRECT_URL)")
    }

    func testNativeAuthXcconfigKeepsURLSchemeAndRedirectInSync() throws {
        for configPath in [
            "Config/MegrumNative.xcconfig",
            "Config/MegrumNative.local.xcconfig.example"
        ] {
            let entries = try Self.xcconfigEntries(relativePath: configPath)

            XCTAssertEqual(entries["MEGRUM_URL_SCHEME"], "megrum-preview", configPath)
            XCTAssertEqual(
                entries["MEGRUM_AUTH_EMAIL_REDIRECT_URL"],
                "https:/$()/megrum.jp/auth/callback?next=mobile&scheme=$(MEGRUM_URL_SCHEME)",
                configPath
            )
        }
    }

    func testAuthStateFactoryUsesConfiguredRedirectSchemeForOAuthCallback() {
        let state = MegrumAuthStateFactory.make(
            environment: [:],
            infoDictionary: [
                "MegrumSupabaseURL": "https://example.supabase.co",
                "MegrumSupabasePublishableKey": "sb_publishable_test",
                "MegrumSupabaseViewerID": "00000000-0000-0000-0000-000000000000",
                "MegrumAuthEmailRedirectURL": "https://megrum.jp/auth/callback?next=mobile&scheme=megrum-dev"
            ]
        )

        XCTAssertTrue(state.isConfigured)
        XCTAssertEqual(state.oauthCallbackScheme, "megrum-dev")
    }

    func testAppStateRefreshesPreviewMeguriFeed() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())

        await state.loadInitialData()
        await state.loadMeguriFeed(scope: .nearby3km)

        XCTAssertFalse(state.grooms.isEmpty)
        XCTAssertEqual(state.threads.map(\.audience), [.nearby3km])
        XCTAssertFalse(state.isLoadingMeguri)

        await state.loadMeguriFeed(scope: .samePrefecture)

        XCTAssertTrue(state.threads.isEmpty)
        XCTAssertTrue(state.threads.allSatisfy { $0.audience == .samePrefecture })
    }

    func testAppStateRefreshesPreviewMeguriFeedWithPrefectureOverride() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())

        await state.loadInitialData()
        await state.loadMeguriFeed(prefecture: "大阪府", scope: .samePrefecture)

        XCTAssertTrue(state.threads.isEmpty)

        await state.loadMeguriFeed(prefecture: "東京都", scope: .samePrefecture)

        XCTAssertTrue(state.threads.contains { $0.prefecture == "東京都" })
    }

    func testAppStateLoadsAndSendsPreviewBoardReplies() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())
        let threadID = UUID(uuidString: "00000000-0000-0000-0000-000000000601")!

        await state.loadInitialData()
        await state.loadBoardReplies(threadID: threadID)

        let initialCount = state.boardReplies(for: threadID).count
        XCTAssertGreaterThan(initialCount, 0)

        let sent = await state.sendBoardReply(threadID: threadID, body: " いま向かいます ")

        XCTAssertTrue(sent)
        XCTAssertEqual(state.boardReplies(for: threadID).count, initialCount + 1)
        XCTAssertEqual(state.boardReplies(for: threadID).last?.body, "いま向かいます")
        XCTAssertFalse(state.isLoadingMeguri)
        XCTAssertNil(state.sendingBoardReplyThreadID)
    }

    func testAppStateCreatesPreviewBoardThread() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())
        await state.loadInitialData()
        let initialCount = state.threads.count

        let created = await state.createBoardThread(
            title: " 終演後の混雑 ",
            body: " 北口はまだゆっくり進めます ",
            scope: .nearby3km,
            latitude: 35.681236,
            longitude: 139.767125,
            thumbnailUpload: GoodsPhotoUpload(data: Data([0xff, 0xd8, 0xff]), contentType: "image/jpeg")
        )

        XCTAssertTrue(created)
        XCTAssertEqual(state.threads.count, initialCount + 1)
        XCTAssertEqual(state.threads.first?.title, "終演後の混雑")
        XCTAssertEqual(state.threads.first?.body, "北口はまだゆっくり進めます")
        XCTAssertEqual(state.threads.first?.audience, .nearby3km)
        XCTAssertNotNil(state.threads.first?.thumbnailURL)
        XCTAssertFalse(state.isCreatingBoardThread)

        let record = await state.createBoardThreadRecord(
            title: " 退場口 ",
            body: " 西側が空いています ",
            scope: .nearby3km,
            latitude: 35.681236,
            longitude: 139.767125
        )

        XCTAssertEqual(record?.title, "退場口")
        XCTAssertEqual(state.threads.first?.id, record?.id)
    }

    func testAppStateCreatesNearbyBoardThreadWithoutViewerPrefecture() async {
        let state = MegrumAppState(repository: NoPrefectureBoardCreationRepository())
        await state.loadInitialData()

        let record = await state.createBoardThreadRecord(
            title: " 近くの様子 ",
            body: " 入口付近に集まっています ",
            scope: .nearby3km,
            latitude: 35.681236,
            longitude: 139.767125,
            prefecture: nil
        )

        XCTAssertEqual(record?.title, "近くの様子")
        XCTAssertEqual(record?.latitude, 35.681236)
        XCTAssertEqual(record?.longitude, 139.767125)
        XCTAssertNil(record?.prefecture)
        XCTAssertNil(state.errorMessage)
    }

    func testAppStateCreatesPreviewGroomPost() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())
        await state.loadInitialData()
        let initialCount = state.grooms.count

        let created = await state.createGroomPost(
            imageData: Data([0xff, 0xd8, 0xff]),
            imageContentType: "image/jpeg",
            latitude: 35.681236,
            longitude: 139.767125
        )

        XCTAssertTrue(created)
        XCTAssertEqual(state.grooms.count, initialCount + 1)
        XCTAssertEqual(state.grooms.first?.authorID, state.viewer?.id)
        XCTAssertFalse(state.isCreatingGroomPost)
    }

    func testAppStateMarksPreviewGroomViewedAndLiked() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())
        let postID = UUID(uuidString: "00000000-0000-0000-0000-000000000501")!

        await state.loadInitialData()
        await state.markGroomViewed(postID)
        await state.setGroomLiked(postID, isLiked: true)

        XCTAssertTrue(state.isGroomLiked(postID))
        XCTAssertNil(state.errorMessage)

        await state.setGroomLiked(postID, isLiked: false)

        XCTAssertFalse(state.isGroomLiked(postID))
        XCTAssertNil(state.errorMessage)
    }

    func testAppStateSendsPreviewGroomReply() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())
        let postID = UUID(uuidString: "00000000-0000-0000-0000-000000000501")!
        let recipientID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

        await state.loadInitialData()

        let sent = await state.sendGroomReply(
            postID: postID,
            recipientID: recipientID,
            body: " かわいいです ",
            groomImageURL: URL(string: "https://example.com/groom-a.jpg")
        )

        XCTAssertTrue(sent)
        XCTAssertEqual(state.groomReplies(for: postID).last?.body, "かわいいです")
        XCTAssertEqual(state.groomReplies(for: postID).last?.recipientID, recipientID)
        XCTAssertNil(state.sendingGroomReplyPostID)
        XCTAssertNil(state.errorMessage)
    }

    func testAppStateLoadsOwnGroomArchiveWithEngagement() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())

        await state.loadInitialData()
        await state.loadGroomArchive()

        XCTAssertFalse(state.ownGroomArchive.isEmpty)
        XCTAssertTrue(state.ownGroomArchive.allSatisfy { $0.authorID == state.viewer?.id })
        XCTAssertEqual(
            state.ownGroomArchive.map(\.id),
            GroomArchiveOrdering.sorted(state.ownGroomArchive).map(\.id)
        )

        let firstArchivedPostID = try! XCTUnwrap(state.ownGroomArchive.first?.id)
        XCTAssertFalse(state.groomReactions(for: firstArchivedPostID).isEmpty)
        XCTAssertFalse(state.groomReplies(for: firstArchivedPostID).isEmpty)
        XCTAssertNil(state.errorMessage)
        XCTAssertFalse(state.isLoadingGroomArchive)
    }

    func testAppStateLoadsAndSendsPreviewMeguriMessages() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())
        let recipientID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

        await state.loadInitialData()
        await state.loadMeguriMessages()

        XCTAssertEqual(state.meguriMessages.first?.body, "グルーム見ました。会場付近ですか？")

        let sent = await state.sendMeguriMessage(
            recipientID: recipientID,
            body: " 近くにいます "
        )

        XCTAssertTrue(sent)
        XCTAssertEqual(state.meguriMessages.last?.body, "近くにいます")
        XCTAssertEqual(state.meguriMessages(with: recipientID).last?.recipientID, recipientID)
        XCTAssertNil(state.sendingMeguriMessageRecipientID)
        XCTAssertNil(state.errorMessage)
    }

    func testAppStateMarksPreviewMeguriMessagesRead() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())
        let peerID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

        await state.loadInitialData()
        await state.loadMeguriMessages()

        XCTAssertNil(state.meguriMessages(with: peerID).first?.readAt)

        await state.markMeguriMessagesRead(peerID: peerID)

        XCTAssertNotNil(state.meguriMessages(with: peerID).first?.readAt)
        XCTAssertNil(state.errorMessage)
    }

    func testAppStateCreatesPreviewBoardThreadWithPrefectureOverride() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())
        await state.loadInitialData()

        let created = await state.createBoardThread(
            title: "大阪の交換場所",
            body: "駅側の広場が見やすいです",
            scope: .samePrefecture,
            prefecture: "大阪府"
        )

        XCTAssertTrue(created)
        XCTAssertEqual(state.threads.first?.audience, .samePrefecture)
        XCTAssertEqual(state.threads.first?.prefecture, "大阪府")
    }

    func testAppStateRequiresLocationForNearbyBoardThread() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())
        await state.loadInitialData()

        let created = await state.createBoardThread(
            title: "物販列どのくらい？",
            body: "北口側です",
            scope: .nearby3km
        )

        XCTAssertFalse(created)
        XCTAssertEqual(state.errorMessage, "現在地と都道府県を確認してから投稿してください")
    }

    func testAppStateCanReplaceRepositoryAfterAuthChanges() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())
        let nextViewer = UserProfile(
            id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
            handle: "signed_in",
            displayName: "Signed In"
        )

        await state.replaceRepository(SingleSnapshotRepository(viewer: nextViewer))

        XCTAssertEqual(state.viewer?.handle, "signed_in")
        XCTAssertTrue(state.inventory.isEmpty)
    }

    func testAppStateCompletesAccountSetupThroughRepository() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())
        let groupID = UUID(uuidString: "00000000-0000-0000-0000-000000000011")!
        let birthDate = ProfileBirthDateCodec.date(from: "2000-02-03")

        let completed = await state.completeAccountSetup(
            handle: "michirion",
            displayName: "みちりおん",
            prefecture: "山形県",
            birthDate: birthDate,
            gender: .female,
            oshiSelections: [
                AccountSetupOshiInput(groupID: groupID, characterID: nil, kind: .box)
            ]
        )

        XCTAssertTrue(completed)
        XCTAssertEqual(state.viewer?.handle, "michirion")
        XCTAssertEqual(state.viewer?.displayName, "みちりおん")
        XCTAssertEqual(state.viewer?.prefecture, "山形県")
        XCTAssertEqual(ProfileBirthDateCodec.string(from: state.viewer?.birthDate), "2000-02-03")
        XCTAssertEqual(state.viewer?.gender, .female)
        XCTAssertEqual(state.viewer?.accountStatus, .active)
        XCTAssertEqual(state.userOshiSelections.first?.groupID, groupID)
        XCTAssertEqual(state.userOshiSelections.first?.kind, .box)
        XCTAssertFalse(state.isSavingAccountSetup)
    }

    func testAppStateFallsBackWhenAccountSetupInputOmitsNameAndHandle() async {
        let state = MegrumAppState(repository: PlaceholderAccountSetupRepository())
        await state.loadInitialData()
        let groupID = UUID(uuidString: "00000000-0000-0000-0000-000000000021")!

        let completed = await state.completeAccountSetup(
            handle: "",
            displayName: "",
            prefecture: "東京都",
            birthDate: ProfileBirthDateCodec.date(from: "2001-05-06"),
            gender: .female,
            oshiSelections: [
                AccountSetupOshiInput(groupID: groupID, characterID: nil, kind: .box)
            ]
        )

        XCTAssertTrue(completed)
        XCTAssertEqual(state.viewer?.handle, "megrum_700000000000")
        XCTAssertEqual(state.viewer?.displayName, "Megrumユーザー")
        XCTAssertEqual(state.viewer?.accountStatus, .active)
    }

    func testPreviewRepositorySavesOshiSelectionsWithDisplayOrderPriority() async throws {
        let repository = PreviewMegrumRepository()
        let firstGroupID = UUID(uuidString: "00000000-0000-0000-0000-000000000111")!
        let secondGroupID = UUID(uuidString: "00000000-0000-0000-0000-000000000112")!

        let selections = try await repository.saveUserOshiSelections([
            AccountSetupOshiInput(groupID: firstGroupID, characterID: nil, kind: .box, priority: 99),
            AccountSetupOshiInput(groupID: secondGroupID, characterID: nil, kind: .box, priority: 99)
        ])

        XCTAssertEqual(selections.map(\.groupID), [firstGroupID, secondGroupID])
        XCTAssertEqual(selections.map(\.priority), [1, 2])
        XCTAssertEqual(Set(selections.map(\.userID)).count, 1)
    }

    func testAppStateRequiresOshiSelectionForAccountSetup() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())

        let completed = await state.completeAccountSetup(
            handle: "michirion",
            displayName: "みちりおん",
            prefecture: "山形県",
            birthDate: ProfileBirthDateCodec.date(from: "2000-02-03"),
            gender: .female
        )

        XCTAssertFalse(completed)
        XCTAssertEqual(state.errorMessage, "推しを選択してください")
    }

    func testAppStateLoadsPreviewOshiGroupsAndCharacters() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())

        await state.loadOshiGroups(searchText: "aespa")
        await state.loadOshiCharacters(group: state.oshiGroups.first)

        XCTAssertEqual(state.oshiGroups.first?.name, "aespa")
        XCTAssertEqual(state.oshiCharacters.first?.name, "カリナ")
    }

    func testAppStateLoadsPreviewUserOshiSelections() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())

        await state.loadUserOshiSelections()

        XCTAssertEqual(state.userOshiSelections.first?.kind, .specific)
        XCTAssertEqual(state.userOshiSelections.first?.groupName, "aespa")
        XCTAssertEqual(state.userOshiSelections.first?.characterName, "カリナ")
        XCTAssertFalse(state.isLoadingUserOshiSelections)
    }

    func testAppStateLoadsPreviewGoodsTypes() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())

        await state.loadGoodsTypes()

        XCTAssertEqual(state.goodsTypes.first?.name, "トレカ")
        XCTAssertFalse(state.isLoadingGoodsTypes)
    }

    func testAppStateCreatesPreviewInventoryAndWishEntries() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())
        await state.loadInitialData()
        await state.loadOshiGroups()
        await state.loadGoodsTypes()

        let groupID = try! XCTUnwrap(state.oshiGroups.first?.id)
        let goodsTypeID = try! XCTUnwrap(state.goodsTypes.first?.id)
        let inventoryCount = state.inventory.count
        let wishCount = state.wishes.count

        let createdInventory = await state.createGoodsEntry(
            GoodsEntryInput(
                kind: .inventory,
                title: " 新しい在庫 ",
                groupID: groupID,
                goodsTypeID: goodsTypeID,
                quantity: 2
            )
        )
        let createdWish = await state.createGoodsEntry(
            GoodsEntryInput(
                kind: .wish,
                title: "新しいWish",
                groupID: groupID,
                goodsTypeID: goodsTypeID,
                photoURLs: ["https://example.com/copied-wish.jpg"]
            )
        )

        XCTAssertTrue(createdInventory)
        XCTAssertTrue(createdWish)
        XCTAssertEqual(state.inventory.count, inventoryCount + 1)
        XCTAssertEqual(state.inventory.first?.title, "新しい在庫")
        XCTAssertEqual(state.inventory.first?.quantity, 2)
        XCTAssertEqual(state.wishes.count, wishCount + 1)
        XCTAssertEqual(state.wishes.first?.title, "新しいWish")
        XCTAssertEqual(state.wishes.first?.imageURL?.absoluteString, "https://example.com/copied-wish.jpg")
        XCTAssertFalse(state.isCreatingGoodsEntry)
    }

    func testAppStateUpdatesPreviewGoodsEntryLocally() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())
        await state.loadInitialData()
        await state.loadOshiGroups()
        await state.loadGoodsTypes()
        await state.loadOshiCharacters(group: state.oshiGroups.first)

        let item = try! XCTUnwrap(state.inventory.first)
        let groupID = try! XCTUnwrap(state.oshiGroups.first?.id)
        let memberID = try! XCTUnwrap(state.oshiCharacters.first?.id)
        let goodsTypeID = try! XCTUnwrap(state.goodsTypes.first?.id)

        let updated = await state.updateGoodsEntry(
            itemID: item.id,
            kind: .inventory,
            input: GoodsEntryUpdateInput(
                title: "  更新トレカ  ",
                groupID: groupID,
                memberID: memberID,
                goodsTypeID: goodsTypeID,
                quantity: 3,
                status: .keep
            )
        )

        XCTAssertTrue(updated)
        XCTAssertEqual(state.inventory.first?.id, item.id)
        XCTAssertEqual(state.inventory.first?.title, "更新トレカ")
        XCTAssertEqual(state.inventory.first?.memberID, memberID)
        XCTAssertEqual(state.inventory.first?.quantity, 3)
        XCTAssertNil(state.mutatingGoodsItemID)
        XCTAssertNil(state.errorMessage)
    }

    func testAppStateSearchesPreviewGoods() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())
        await state.loadInitialData()

        await state.searchGoods(query: "トレカ")

        XCTAssertEqual(state.searchResults.first?.item.title, "サナ 2026 LIVE")
        XCTAssertEqual(state.searchResults.first?.bucket, .possible)
        XCTAssertFalse(state.isSearchingGoods)
        XCTAssertNil(state.errorMessage)
    }

    func testAppStateSearchesPreviewGoodsByMember() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())
        await state.loadInitialData()
        await state.searchGoods(query: "")
        guard let memberID = state.searchResults.compactMap({ $0.item.memberID }).first else {
            XCTFail("Preview search data should include at least one member-backed goods item.")
            return
        }

        await state.searchGoods(query: "", memberID: memberID)

        XCTAssertFalse(state.searchResults.isEmpty)
        XCTAssertTrue(state.searchResults.allSatisfy { $0.item.memberID == memberID })
        XCTAssertFalse(state.isSearchingGoods)
        XCTAssertNil(state.errorMessage)
    }

    func testAppStateArchivesAndDeletesPreviewGoodsLocally() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())
        await state.loadInitialData()
        let inventoryID = try! XCTUnwrap(state.inventory.first?.id)
        let wishID = try! XCTUnwrap(state.wishes.first?.id)
        let inventoryCount = state.inventory.count
        let wishCount = state.wishes.count

        let archived = await state.archiveGoodsItem(inventoryID)
        let deleted = await state.deleteGoodsItem(wishID)

        XCTAssertTrue(archived)
        XCTAssertTrue(deleted)
        XCTAssertEqual(state.inventory.count, inventoryCount - 1)
        XCTAssertFalse(state.inventory.contains { $0.id == inventoryID })
        XCTAssertEqual(state.wishes.count, wishCount - 1)
        XCTAssertFalse(state.wishes.contains { $0.id == wishID })
        XCTAssertNil(state.mutatingGoodsItemID)
        XCTAssertNil(state.errorMessage)
    }

    func testAppStateReportsPreviewGoods() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())
        await state.loadInitialData()
        await state.searchGoods(query: "トレカ")
        let item = try! XCTUnwrap(state.searchResults.first?.item)

        let reported = await state.reportGoods(
            itemID: item.id,
            reportedUserID: item.ownerID,
            reason: .fakeItem,
            note: " 説明と違います "
        )

        XCTAssertTrue(reported)
        XCTAssertNil(state.reportingGoodsItemID)
        XCTAssertNil(state.errorMessage)
    }

    func testAppStateRejectsReportingOwnGoods() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())
        await state.loadInitialData()
        let item = try! XCTUnwrap(state.inventory.first)

        let reported = await state.reportGoods(
            itemID: item.id,
            reportedUserID: item.ownerID,
            reason: .other,
            note: ""
        )

        XCTAssertFalse(reported)
        XCTAssertNil(state.reportingGoodsItemID)
        XCTAssertEqual(state.errorMessage, "自分のグッズは通報できません")
    }

    func testAppStateCreatesPreviewProposal() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())
        await state.loadInitialData()

        let senderGoodsID = try! XCTUnwrap(state.inventory.first?.id)
        let receiverGoodsID = UUID(uuidString: "99999999-9999-9999-9999-999999999999")!
        let receiverID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

        let created = await state.createProposal(
            ProposalCreateInput(
                receiverID: receiverID,
                senderGoodsIDs: [senderGoodsID],
                receiverGoodsIDs: [receiverGoodsID],
                exchangeMethod: .mail,
                conditionTags: ["即日発送"],
                message: "よろしくお願いします"
            )
        )

        XCTAssertTrue(created)
        XCTAssertEqual(state.proposals.first?.receiverID, receiverID)
        XCTAssertEqual(state.proposals.first?.receiverGoodsIDs, [receiverGoodsID])
        XCTAssertEqual(state.proposals.first?.conditionTags, ["即日発送"])
        XCTAssertFalse(state.isCreatingProposal)
    }

    func testAppStateCreatesPreviewCounterProposal() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())
        let incomingProposalID = UUID(uuidString: "00000000-0000-0000-0000-000000000403")!

        await state.loadInitialData()
        let incoming = try! XCTUnwrap(state.proposals.first(where: { $0.id == incomingProposalID }))
        let viewerID = try! XCTUnwrap(state.viewer?.id)
        let input = try! XCTUnwrap(
            incoming.counterProposalInput(
                from: viewerID,
                exchangeMethod: .mail,
                conditionTags: ["同日発送"],
                message: "郵送なら進められます"
            )
        )

        let created = await state.createProposal(input)

        XCTAssertTrue(created)
        XCTAssertEqual(state.proposals.first?.receiverID, incoming.senderID)
        XCTAssertEqual(state.proposals.first?.senderGoodsIDs, incoming.receiverGoodsIDs)
        XCTAssertEqual(state.proposals.first?.receiverGoodsIDs, incoming.senderGoodsIDs)
        XCTAssertEqual(state.proposals.first?.exchangeMethod, .mail)
        XCTAssertEqual(state.proposals.first?.conditionTags, ["同日発送"])
        XCTAssertEqual(state.proposals.first?.status, .negotiating)
        XCTAssertEqual(state.proposals.first?.agreedBySender, true)
        XCTAssertFalse(state.isCreatingProposal)
    }

    func testAppStateLoadsPreviewTradeSchedules() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())
        let proposalID = UUID(uuidString: "00000000-0000-0000-0000-000000000402")!

        await state.loadInitialData()
        let proposal = try! XCTUnwrap(state.proposals.first { $0.id == proposalID })
        let start = Calendar.current.startOfDay(for: .now)
        let end = Calendar.current.date(byAdding: .day, value: 5, to: start)!

        await state.loadSchedules(for: proposal, startAt: start, endAt: end)

        XCTAssertFalse(state.schedules(for: proposalID).isEmpty)
        XCTAssertTrue(state.schedules(for: proposalID).contains { $0.placeName != nil })
        XCTAssertNil(state.loadingSchedulesProposalID)
        XCTAssertNil(state.errorMessage)
    }

    func testAppStateAgreesPreviewIncomingProposal() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())
        let incomingProposalID = UUID(uuidString: "00000000-0000-0000-0000-000000000403")!

        await state.loadInitialData()

        let accepted = await state.agreeProposal(
            proposalID: incomingProposalID,
            acceptedExchangeMethod: .mail
        )
        let updated = state.proposals.first(where: { $0.id == incomingProposalID })

        XCTAssertTrue(accepted)
        XCTAssertEqual(updated?.status, .agreed)
        XCTAssertEqual(updated?.exchangeMethod, .mail)
        XCTAssertEqual(updated?.agreedBySender, true)
        XCTAssertEqual(updated?.agreedByReceiver, true)
        XCTAssertNil(state.respondingProposalID)
        XCTAssertNil(state.errorMessage)
    }

    func testAppStateRejectsPreviewIncomingProposal() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())
        let incomingProposalID = UUID(uuidString: "00000000-0000-0000-0000-000000000403")!

        await state.loadInitialData()

        let rejected = await state.rejectProposal(proposalID: incomingProposalID)
        let updated = state.proposals.first(where: { $0.id == incomingProposalID })

        XCTAssertTrue(rejected)
        XCTAssertEqual(updated?.status, .rejected)
        XCTAssertNil(state.respondingProposalID)
        XCTAssertNil(state.errorMessage)
    }

    func testAppStateLoadsAndSendsPreviewMessages() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())
        await state.loadInitialData()
        let proposalID = try! XCTUnwrap(state.proposals.first?.id)

        await state.loadMessages(proposalID: proposalID)
        let initialCount = state.messages(for: proposalID).count

        let sent = await state.sendMessage(proposalID: proposalID, body: " 了解しました ")

        XCTAssertTrue(sent)
        XCTAssertEqual(state.messages(for: proposalID).count, initialCount + 1)
        XCTAssertEqual(state.messages(for: proposalID).last?.body, "了解しました")
        XCTAssertFalse(state.isCreatingProposal)
        XCTAssertNil(state.sendingMessageProposalID)
    }

    func testAppStateLoadsPartnerReadStateAndMarksCurrentReadPosition() async {
        let repository = TradeReadStateRecordingRepository()
        let state = MegrumAppState(repository: repository)
        await state.loadInitialData()

        await state.loadMessages(proposalID: TradeReadStateRecordingRepository.proposalID)

        XCTAssertEqual(
            state.partnerLastReadAt(for: TradeReadStateRecordingRepository.proposalID),
            TradeReadStateRecordingRepository.partnerLastReadAt
        )

        let marks = await repository.marksSnapshot()
        XCTAssertEqual(marks.count, 1)
        XCTAssertEqual(marks.first?.proposalID, TradeReadStateRecordingRepository.proposalID)
        XCTAssertEqual(marks.first?.userID, TradeReadStateRecordingRepository.viewerID)
        XCTAssertEqual(marks.first?.lastReadAt, TradeReadStateRecordingRepository.latestMessageAt)
    }

    func testAppStateSendsPreviewOutfitPhotoMessage() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())
        await state.loadInitialData()
        let proposalID = try! XCTUnwrap(state.proposals.first?.id)

        await state.loadMessages(proposalID: proposalID)
        let initialCount = state.messages(for: proposalID).count

        let sent = await state.sendPhotoMessage(
            proposalID: proposalID,
            imageData: Data([0xff, 0xd8, 0xff]),
            imageContentType: "image/jpeg",
            messageType: .outfitPhoto
        )

        XCTAssertTrue(sent)
        XCTAssertEqual(state.messages(for: proposalID).count, initialCount + 1)
        XCTAssertEqual(state.messages(for: proposalID).last?.messageType, .outfitPhoto)
        let photoURL = try! XCTUnwrap(state.messages(for: proposalID).last?.photoURL)
        XCTAssertTrue(photoURL.isFileURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: photoURL.path))
        XCTAssertNil(state.sendingMessageProposalID)
        XCTAssertNil(state.errorMessage)
    }

    func testAppStateSendsPreviewChatPhotoMessage() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())
        await state.loadInitialData()
        let proposalID = try! XCTUnwrap(state.proposals.first?.id)

        await state.loadMessages(proposalID: proposalID)
        let initialCount = state.messages(for: proposalID).count

        let sent = await state.sendPhotoMessage(
            proposalID: proposalID,
            imageData: Data([0xff, 0xd8, 0xff]),
            imageContentType: "image/jpeg",
            messageType: .photo
        )

        XCTAssertTrue(sent)
        XCTAssertEqual(state.messages(for: proposalID).count, initialCount + 1)
        XCTAssertEqual(state.messages(for: proposalID).last?.messageType, .photo)
        let photoURL = try! XCTUnwrap(state.messages(for: proposalID).last?.photoURL)
        XCTAssertTrue(photoURL.isFileURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: photoURL.path))
        XCTAssertNil(state.sendingMessageProposalID)
        XCTAssertNil(state.errorMessage)
    }

    func testAppStateAddsEvidenceApprovesAndSubmitsPreviewEvaluation() async {
        await PreviewMegrumRepository.resetTradePhotoLocalStoreForTesting()
        let state = MegrumAppState(repository: PreviewMegrumRepository())
        await state.loadInitialData()
        let proposalID = try! XCTUnwrap(state.proposals.first(where: { $0.status == .agreed })?.id)

        let added = await state.addTradeEvidence(
            proposalID: proposalID,
            imageData: Data([0xff, 0xd8, 0xff]),
            imageContentType: "image/jpeg"
        )

        XCTAssertTrue(added)
        let proposal = try! XCTUnwrap(state.proposals.first(where: { $0.id == proposalID }))
        let evidencePhotoURL = try! XCTUnwrap(proposal.evidencePhotoURL)
        XCTAssertTrue(evidencePhotoURL.isFileURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: evidencePhotoURL.path))
        let evidencePhotos = state.evidencePhotos(for: proposal)
        XCTAssertEqual(evidencePhotos.count, 1)
        XCTAssertFalse(evidencePhotos.isEmpty)
        XCTAssertTrue(evidencePhotos.contains { $0.photoURL == evidencePhotoURL })
        XCTAssertTrue(
            state.messages(for: proposalID).contains { message in
                message.messageType == .system
                    && message.meta["action"] == "evidence_added"
                    && message.body?.hasSuffix("が取引証跡をアップロードしました") == true
            }
        )
        XCTAssertNil(state.addingEvidenceProposalID)
        let evidencePhotoID = try! XCTUnwrap(evidencePhotos.first?.id)

        let approved = await state.approveTradeEvidence(proposalID: proposalID, photoID: evidencePhotoID)

        XCTAssertTrue(approved)
        XCTAssertTrue(state.proposals.first(where: { $0.id == proposalID })?.approvedByReceiver ?? false)
        XCTAssertNil(state.approvingEvidenceProposalID)

        let submitted = await state.submitTradeEvaluation(
            proposalID: proposalID,
            stars: 5,
            comment: "ありがとうございました"
        )

        XCTAssertTrue(submitted)
        XCTAssertTrue(
            state.messages(for: proposalID).contains { message in
                message.messageType == .system
                    && message.meta["action"] == "evaluation_submitted"
                    && message.meta["stars"] == "5"
            }
        )
        XCTAssertNil(state.submittingEvaluationProposalID)
        XCTAssertNil(state.errorMessage)
    }

    func testAppStateDeletesEvidencePhotoImmediatelyAndKeepsItDeletedAfterReload() async {
        await PreviewMegrumRepository.resetTradePhotoLocalStoreForTesting()
        let state = MegrumAppState(repository: PreviewMegrumRepository())
        await state.loadInitialData()
        let proposalID = try! XCTUnwrap(state.proposals.first(where: { $0.status == .agreed })?.id)

        let added = await state.addTradeEvidence(
            proposalID: proposalID,
            imageData: Data([0xff, 0xd8, 0xff]),
            imageContentType: "image/jpeg"
        )

        XCTAssertTrue(added)
        let proposalAfterAdd = try! XCTUnwrap(state.proposals.first(where: { $0.id == proposalID }))
        let evidencePhotosAfterAdd = state.evidencePhotos(for: proposalAfterAdd)
        XCTAssertEqual(evidencePhotosAfterAdd.count, 1)
        let evidencePhoto = try! XCTUnwrap(evidencePhotosAfterAdd.first)

        let deleted = await state.deleteTradeEvidencePhoto(proposalID: proposalID, photoID: evidencePhoto.id)

        XCTAssertTrue(deleted)
        let proposalAfterDelete = try! XCTUnwrap(state.proposals.first(where: { $0.id == proposalID }))
        XCTAssertTrue(state.evidencePhotos(for: proposalAfterDelete).isEmpty)
        XCTAssertFalse(state.evidencePhotos(for: proposalAfterDelete).contains { $0.id == evidencePhoto.id })
        XCTAssertNil(state.deletingEvidencePhotoID)

        await state.loadTradeEvidencePhotos(proposal: proposalAfterDelete, reportsFailure: false)

        XCTAssertTrue(state.evidencePhotos(for: proposalAfterDelete).isEmpty)
        XCTAssertFalse(state.evidencePhotos(for: proposalAfterDelete).contains { $0.id == evidencePhoto.id })
        XCTAssertNil(state.errorMessage)
    }

    func testAppStateFilesPreviewTradeDispute() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())
        await state.loadInitialData()
        let proposalID = try! XCTUnwrap(state.proposals.first?.id)

        let filed = await state.fileTradeDispute(
            proposalID: proposalID,
            category: .wrong,
            factMemo: "  状態が説明と違いました  "
        )

        XCTAssertTrue(filed)
        XCTAssertNil(state.filingDisputeProposalID)
        XCTAssertNil(state.errorMessage)
    }

    func testAppStateValidatesTradeDisputeMemo() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())
        await state.loadInitialData()
        let proposalID = try! XCTUnwrap(state.proposals.first?.id)

        let filed = await state.fileTradeDispute(
            proposalID: proposalID,
            category: .other,
            factMemo: " "
        )

        XCTAssertFalse(filed)
        XCTAssertEqual(state.errorMessage, "申告内容を入力してください")
        XCTAssertNil(state.filingDisputeProposalID)
    }

    func testAppStateValidatesGoodsEntryTitle() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())
        let created = await state.createGoodsEntry(
            GoodsEntryInput(
                kind: .inventory,
                title: " ",
                groupID: NativePreviewIDs.groupID,
                goodsTypeID: NativePreviewIDs.cardGoodsTypeID
            )
        )

        XCTAssertFalse(created)
        XCTAssertEqual(state.errorMessage, "グッズ名を入力してください")
    }

    func testAppStateLoadsAndSavesPreviewMailingAddress() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())

        await state.loadMailingAddress()

        XCTAssertEqual(state.mailingAddress?.postalCode, "1000001")

        let saved = await state.saveMailingAddress(
            MailingAddress(
                userID: NativePreviewIDs.viewerID,
                recipientName: "みちりおん",
                postalCode: "1500001",
                prefecture: "東京都",
                city: "渋谷区",
                line1: "神宮前1-1"
            )
        )

        XCTAssertTrue(saved)
        XCTAssertEqual(state.mailingAddress?.postalCode, "1500001")
    }

    func testAppStateValidatesMailingAddressBeforeSaving() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())

        let saved = await state.saveMailingAddress(
            MailingAddress(
                userID: NativePreviewIDs.viewerID,
                recipientName: "",
                postalCode: "1500001",
                prefecture: "東京都",
                city: "渋谷区",
                line1: "神宮前1-1"
            )
        )

        XCTAssertFalse(saved)
        XCTAssertEqual(state.errorMessage, "宛名・郵便番号・都道府県・市区町村・番地を入力してください")
    }

    func testAppStateLooksUpPostalCodeInPreviewRepository() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())

        let address = await state.lookupPostalCode("100-0001")

        XCTAssertEqual(address?.prefecture, "東京都")
        XCTAssertEqual(address?.city, "千代田区")
        XCTAssertEqual(address?.line1Suggestion, "千代田")
        XCTAssertFalse(state.isLookingUpPostalCode)
        XCTAssertNil(state.errorMessage)
    }

    func testAppStateLoadsAndUnblocksPreviewBlockedUsers() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())

        await state.loadBlockedUsers()

        XCTAssertEqual(state.blockedUsers.first?.handle, "blocked_sample")

        let userID = try! XCTUnwrap(state.blockedUsers.first?.userID)
        let unblocked = await state.unblockUser(userID)

        XCTAssertTrue(unblocked)
        XCTAssertTrue(state.blockedUsers.isEmpty)
        XCTAssertNil(state.unblockingUserID)
    }

    func testAppStateLoadsAndMarksPreviewNotificationsRead() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())

        await state.loadNotifications()

        XCTAssertEqual(state.unreadNotificationCount, 2)

        let notificationID = try! XCTUnwrap(state.notifications.first?.id)
        await state.markNotificationRead(notificationID)

        XCTAssertEqual(state.unreadNotificationCount, 1)

        await state.markAllNotificationsRead()

        XCTAssertEqual(state.unreadNotificationCount, 0)
        XCTAssertFalse(state.isMarkingNotificationsRead)
    }

    func testNotificationLinkPathsRouteToNativeTabs() {
        XCTAssertEqual(MegrumTab(notificationLinkPath: "/proposals/preview"), .trades)
        XCTAssertEqual(MegrumTab(notificationLinkPath: "/trades/preview"), .trades)
        XCTAssertEqual(MegrumTab(notificationLinkPath: "/meguri-board-thread?id=thread-1"), .meguri)
        XCTAssertEqual(MegrumTab(notificationLinkPath: "/goods/preview"), .inventory)
        XCTAssertEqual(MegrumTab(notificationLinkPath: "/wish/preview"), .wish)
    }

    func testAppStateLoadsAndTogglesPreviewPushNotificationSetting() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())

        await state.loadPushNotificationSetting()

        XCTAssertTrue(state.pushNotificationsEnabled)
        XCTAssertFalse(state.isLoadingPushNotificationSetting)

        let saved = await state.setPushNotificationsEnabled(false)

        XCTAssertTrue(saved)
        XCTAssertFalse(state.pushNotificationsEnabled)
        XCTAssertFalse(state.isSavingPushNotificationSetting)
        XCTAssertNil(state.errorMessage)
    }

    func testAppStateRegistersNativePushDeviceTokenThroughRepository() async {
        let repository = PushDeviceRecordingRepository()
        let state = MegrumAppState(repository: repository)

        let registered = await state.registerNativePushDeviceToken(" apns-device-token ", appVersion: "0.1.0")

        XCTAssertTrue(registered)
        XCTAssertFalse(state.isRegisteringNativePushDevice)
        XCTAssertNil(state.errorMessage)

        let registrations = await repository.registrationsSnapshot()
        XCTAssertEqual(registrations.first?.token, "apns-device-token")
        XCTAssertEqual(registrations.first?.appVersion, "0.1.0")
    }

    func testAppStateRevokesRegisteredNativePushDeviceTokenThroughRepository() async {
        let repository = PushDeviceRecordingRepository()
        let state = MegrumAppState(repository: repository)
        let revokedAt = Date(timeIntervalSince1970: 1_779_900_000)

        _ = await state.registerNativePushDeviceToken(" apns-device-token ", appVersion: "0.1.0")
        let revoked = await state.revokeRegisteredNativePushDeviceToken(revokedAt: revokedAt)

        XCTAssertTrue(revoked)
        XCTAssertFalse(state.isRevokingNativePushDevice)
        XCTAssertNil(state.errorMessage)

        let revocations = await repository.revocationsSnapshot()
        XCTAssertEqual(revocations.first?.token, "apns-device-token")
        XCTAssertEqual(revocations.first?.revokedAt, revokedAt)
    }

    func testAuthStateSignsInThroughRepository() async {
        let state = MegrumAuthState(repository: StubAuthRepository())

        await state.signIn(email: "michi@example.com", password: "password123")

        XCTAssertEqual(state.session?.user.email, "michi@example.com")
        XCTAssertTrue(state.isAuthenticated)
        XCTAssertFalse(state.isLoading)
        XCTAssertNil(state.errorMessage)
    }

    func testAuthStateValidatesSignInEmail() async {
        let state = MegrumAuthState(repository: StubAuthRepository())

        await state.signIn(email: "michi", password: "password123")

        XCTAssertNil(state.session)
        XCTAssertFalse(state.isAuthenticated)
        XCTAssertEqual(state.errorMessage, MegrumAuthInputValidator.invalidEmailMessage)
    }

    func testAuthStateSignsInWithAppleThroughRepository() async {
        let state = MegrumAuthState(repository: AppleAuthRepository())

        await state.signInWithApple(idToken: " apple_id_token ", nonce: " raw_nonce ", fullName: " みちりおん ")

        XCTAssertEqual(state.session?.user.email, "apple@example.com")
        XCTAssertTrue(state.isAuthenticated)
        XCTAssertFalse(state.isLoading)
        XCTAssertNil(state.errorMessage)
    }

    func testAuthStateBuildsGoogleOAuthAuthorizeURLThroughRepository() throws {
        let state = MegrumAuthState(repository: GoogleOAuthAuthRepository())

        let url = try state.googleOAuthAuthorizeURL()

        XCTAssertEqual(url.absoluteString, "https://example.supabase.co/auth/v1/authorize?provider=google&redirect_to=megrum-preview://auth/callback&scopes=email%20profile")
        XCTAssertEqual(state.oauthCallbackScheme, "megrum-preview")
    }

    func testAuthStateSendsPasswordResetThroughRepository() async {
        let repository = PasswordResetAuthRepository()
        let state = MegrumAuthState(repository: repository)

        let sent = await state.sendPasswordReset(email: " michi@example.com ")

        XCTAssertTrue(sent)
        XCTAssertNil(state.session)
        XCTAssertEqual(state.passwordResetMessage, "再設定メールを送信しました。受信メールを確認してください")
        XCTAssertFalse(state.isLoading)
        XCTAssertNil(state.errorMessage)

        let emails = await repository.emailsSnapshot()
        XCTAssertEqual(emails, ["michi@example.com"])
    }

    func testAuthStateRestoresSessionFromStore() async {
        let store = InMemoryAuthSessionStore()
        let firstState = MegrumAuthState(repository: StubAuthRepository(), sessionStore: store)

        await firstState.signIn(email: "michi@example.com", password: "password123")
        let restoredState = MegrumAuthState(repository: StubAuthRepository(), sessionStore: store)

        XCTAssertEqual(restoredState.session?.user.email, "michi@example.com")
        XCTAssertTrue(restoredState.isAuthenticated)
    }

    func testAuthStateRestoresSessionFromRedirectURL() async throws {
        let state = MegrumAuthState(repository: RedirectAuthRepository())
        let url = try XCTUnwrap(URL(string: "megrum-preview://auth/callback#access_token=redirect_access_token"))

        let handled = await state.handleOpenURL(url)

        XCTAssertTrue(handled)
        XCTAssertEqual(state.session?.accessToken, "redirect_access_token")
        XCTAssertEqual(state.session?.user.email, "redirect@example.com")
        XCTAssertTrue(state.isAuthenticated)
    }

    func testAuthStateTrimsSignUpInputThroughRepository() async {
        let repository = SignUpRecordingAuthRepository()
        let state = MegrumAuthState(repository: repository)

        await state.signUp(email: " michi@example.com ", password: "password123", handle: " michi_1 ")

        XCTAssertEqual(state.session?.user.email, "michi@example.com")
        XCTAssertNil(state.errorMessage)

        let inputs = await repository.inputsSnapshot()
        XCTAssertEqual(inputs.first?.email, "michi@example.com")
        XCTAssertEqual(inputs.first?.handle, "michi_1")
    }

    func testAuthStateValidatesSignUpPasswordLength() async {
        let state = MegrumAuthState(repository: StubAuthRepository())

        await state.signUp(email: "michi@example.com", password: "short", handle: "michi1")

        XCTAssertNil(state.session)
        XCTAssertEqual(state.errorMessage, "パスワードは8文字以上で入力してください")
    }

    func testAuthStateValidatesSignUpHandle() async {
        let state = MegrumAuthState(repository: StubAuthRepository())

        await state.signUp(email: "michi@example.com", password: "password123", handle: "みち")

        XCTAssertNil(state.session)
        XCTAssertEqual(state.errorMessage, "ユーザーIDは3〜24文字の英数字と_で入力してください")
    }

    func testAuthStateValidatesPasswordResetEmail() async {
        let state = MegrumAuthState(repository: StubAuthRepository())

        let sent = await state.sendPasswordReset(email: " ")

        XCTAssertFalse(sent)
        XCTAssertNil(state.session)
        XCTAssertEqual(state.errorMessage, "有効なメールアドレスを入力してください")
        XCTAssertNil(state.passwordResetMessage)
    }

    func testAppStateLoadsPreviewPublicProfileAndEvaluations() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())
        let partnerID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

        await state.loadPublicUserProfile(userID: partnerID)
        await state.loadUserEvaluations(userID: partnerID)

        XCTAssertEqual(state.publicProfilesByUserID[partnerID]?.profile.handle, "michi1")
        XCTAssertEqual(state.publicProfilesByUserID[partnerID]?.evaluationCount, 2)
        XCTAssertEqual(state.userEvaluationsByUserID[partnerID]?.first?.stars, 5)
    }

    func testAppStateRefreshHomeDiscoveryReloadsSnapshotAndHomeCandidates() async {
        let repository = HomeDiscoveryRefreshRepository()
        let state = MegrumAppState(repository: repository)

        await state.loadInitialData()
        XCTAssertEqual(state.viewer?.displayName, "初回ユーザー")
        XCTAssertEqual(state.homeMatchedItems.map(\.title), ["初回候補"])

        await state.refreshHomeDiscovery()

        XCTAssertEqual(state.viewer?.displayName, "更新後ユーザー")
        XCTAssertEqual(state.homeMatchedItems.map(\.title), ["更新候補"])
        XCTAssertNil(state.errorMessage)

        let counts = await repository.countsSnapshot()
        XCTAssertEqual(counts.snapshotLoads, 2)
        XCTAssertEqual(counts.homeCandidateLoads, 2)
    }

    private static func nativeInfoPlist() throws -> [String: Any] {
        let data = try Data(contentsOf: iosNativeRoot.appendingPathComponent("App/Info.plist"))
        let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        return try XCTUnwrap(plist as? [String: Any])
    }

    private static func xcconfigEntries(relativePath: String) throws -> [String: String] {
        let contents = try String(contentsOf: iosNativeRoot.appendingPathComponent(relativePath), encoding: .utf8)
        return contents.split(whereSeparator: \.isNewline).reduce(into: [:]) { entries, line in
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            guard !trimmedLine.isEmpty, !trimmedLine.hasPrefix("//"), !trimmedLine.hasPrefix("#") else {
                return
            }
            let parts = trimmedLine.split(separator: "=", maxSplits: 1).map {
                $0.trimmingCharacters(in: .whitespaces)
            }
            guard parts.count == 2 else {
                return
            }
            entries[parts[0]] = parts[1]
        }
    }

    private static var iosNativeRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}

private actor HomeDiscoveryRefreshRepository: MegrumRepository {
    private let viewerID = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
    private let partnerID = UUID(uuidString: "66666666-7777-8888-9999-000000000000")!
    private var snapshotLoads = 0
    private var homeCandidateLoads = 0

    func loadInitialSnapshot() async throws -> MegrumAppSnapshot {
        snapshotLoads += 1
        let displayName = snapshotLoads == 1 ? "初回ユーザー" : "更新後ユーザー"
        return MegrumAppSnapshot(
            viewer: UserProfile(
                id: viewerID,
                handle: "michilion",
                displayName: displayName
            ),
            inventory: [
                GoodsItem(
                    id: UUID(uuidString: "11111111-2222-3333-4444-555555555556")!,
                    ownerID: viewerID,
                    title: "自分の譲るもの",
                    quantity: 1
                )
            ],
            wishes: [],
            listings: [],
            proposals: [],
            grooms: [],
            threads: []
        )
    }

    func loadHomeCandidateSections() async throws -> HomeCandidateSections {
        homeCandidateLoads += 1
        let title = homeCandidateLoads == 1 ? "初回候補" : "更新候補"
        return HomeCandidateSections(
            matchedItems: [
                GoodsItem(
                    id: UUID(uuidString: "66666666-7777-8888-9999-000000000001")!,
                    ownerID: partnerID,
                    title: title,
                    quantity: 1
                )
            ],
            possibleItems: []
        )
    }

    func countsSnapshot() -> (snapshotLoads: Int, homeCandidateLoads: Int) {
        (snapshotLoads, homeCandidateLoads)
    }
}

private struct StubAuthRepository: MegrumAuthRepository {
    var isConfigured: Bool { true }

    func signIn(email: String, password: String) async throws -> AuthSession {
        AuthSession(
            accessToken: "stub_access_token",
            user: AuthUser(
                id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                email: email
            )
        )
    }

    func signUp(_ input: AuthSignUpInput) async throws -> AuthSession {
        AuthSession(
            accessToken: "stub_access_token",
            user: AuthUser(
                id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
                email: input.email
            )
        )
    }

    func signOut(session: AuthSession) async throws {}
}

private actor SignUpRecordingAuthRepository: MegrumAuthRepository {
    private var inputs: [AuthSignUpInput] = []

    nonisolated var isConfigured: Bool { true }

    func signIn(email: String, password: String) async throws -> AuthSession {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func signUp(_ input: AuthSignUpInput) async throws -> AuthSession {
        inputs.append(input)
        return AuthSession(
            accessToken: "signup_access_token",
            user: AuthUser(
                id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
                email: input.email
            )
        )
    }

    func signOut(session: AuthSession) async throws {}

    func inputsSnapshot() -> [AuthSignUpInput] {
        inputs
    }
}

private actor PasswordResetAuthRepository: MegrumAuthRepository {
    private var emails: [String] = []

    nonisolated var isConfigured: Bool { true }

    func signIn(email: String, password: String) async throws -> AuthSession {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func signUp(_ input: AuthSignUpInput) async throws -> AuthSession {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func sendPasswordReset(email: String) async throws {
        emails.append(email)
    }

    func signOut(session: AuthSession) async throws {}

    func emailsSnapshot() -> [String] {
        emails
    }
}

private struct RedirectAuthRepository: MegrumAuthRepository {
    var isConfigured: Bool { true }

    func signIn(email: String, password: String) async throws -> AuthSession {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func signUp(_ input: AuthSignUpInput) async throws -> AuthSession {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func signOut(session: AuthSession) async throws {}

    func restoreSession(fromRedirectURL url: URL) async throws -> AuthSession? {
        guard let payload = SupabaseAuthRedirectParser.parse(url) else {
            return nil
        }
        return AuthSession(
            accessToken: payload.accessToken,
            refreshToken: payload.refreshToken,
            expiresIn: payload.expiresIn,
            expiresAt: payload.expiresAt,
            tokenType: payload.tokenType,
            user: AuthUser(
                id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
                email: "redirect@example.com"
            )
        )
    }
}

private struct ProposalReadMark: Equatable, Sendable {
    var proposalID: UUID
    var userID: UUID
    var lastReadAt: Date
}

private actor TradeReadStateRecordingRepository: MegrumRepository {
    static let viewerID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    static let partnerID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    static let proposalID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
    static let partnerLastReadAt = Date(timeIntervalSince1970: 1_800_000_120)
    static let latestMessageAt = Date(timeIntervalSince1970: 1_800_000_060)

    private var marks: [ProposalReadMark] = []

    func loadInitialSnapshot() async throws -> MegrumAppSnapshot {
        MegrumAppSnapshot(
            viewer: UserProfile(
                id: Self.viewerID,
                handle: "michilion",
                displayName: "みちりおん"
            ),
            inventory: [],
            wishes: [],
            proposals: [
                TradeProposal(
                    id: Self.proposalID,
                    senderID: Self.viewerID,
                    receiverID: Self.partnerID,
                    status: .negotiating,
                    exchangeMethod: .hand,
                    senderGoodsIDs: [],
                    receiverGoodsIDs: [],
                    createdAt: Date(timeIntervalSince1970: 1_800_000_000)
                )
            ],
            grooms: [],
            threads: []
        )
    }

    func loadMessages(proposalID: UUID, limit: Int) async throws -> [TradeMessage] {
        [
            TradeMessage(
                id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
                proposalID: proposalID,
                senderID: Self.partnerID,
                messageType: .text,
                body: "確認お願いします",
                createdAt: Date(timeIntervalSince1970: 1_800_000_030)
            ),
            TradeMessage(
                id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
                proposalID: proposalID,
                senderID: Self.viewerID,
                messageType: .text,
                body: "了解しました",
                createdAt: Self.latestMessageAt
            )
        ]
    }

    func loadProposalReadState(proposalID: UUID, userID: UUID) async throws -> ProposalReadState? {
        ProposalReadState(
            proposalID: proposalID,
            userID: userID,
            lastReadAt: Self.partnerLastReadAt,
            updatedAt: Self.partnerLastReadAt
        )
    }

    func markProposalMessagesRead(proposalID: UUID, userID: UUID, lastReadAt: Date) async throws -> ProposalReadState? {
        marks.append(ProposalReadMark(proposalID: proposalID, userID: userID, lastReadAt: lastReadAt))
        return ProposalReadState(
            proposalID: proposalID,
            userID: userID,
            lastReadAt: lastReadAt,
            updatedAt: lastReadAt
        )
    }

    func marksSnapshot() -> [ProposalReadMark] {
        marks
    }
}

private struct AppleAuthRepository: MegrumAuthRepository {
    var isConfigured: Bool { true }

    func signIn(email: String, password: String) async throws -> AuthSession {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func signInWithApple(idToken: String, nonce: String, fullName: String?) async throws -> AuthSession {
        XCTAssertEqual(idToken, "apple_id_token")
        XCTAssertEqual(nonce, "raw_nonce")
        XCTAssertEqual(fullName, "みちりおん")
        return AuthSession(
            accessToken: "apple_access_token",
            user: AuthUser(
                id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
                email: "apple@example.com"
            )
        )
    }

    func signUp(_ input: AuthSignUpInput) async throws -> AuthSession {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func signOut(session: AuthSession) async throws {}
}

private struct GoogleOAuthAuthRepository: MegrumAuthRepository {
    var isConfigured: Bool { true }
    var oauthCallbackScheme: String? { "megrum-preview" }

    func signIn(email: String, password: String) async throws -> AuthSession {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func googleOAuthAuthorizeURL() throws -> URL {
        URL(string: "https://example.supabase.co/auth/v1/authorize?provider=google&redirect_to=megrum-preview://auth/callback&scopes=email%20profile")!
    }

    func signUp(_ input: AuthSignUpInput) async throws -> AuthSession {
        throw MegrumRepositoryError.unsupportedMutation
    }

    func signOut(session: AuthSession) async throws {}
}

private struct SingleSnapshotRepository: MegrumRepository {
    var viewer: UserProfile

    func loadInitialSnapshot() async throws -> MegrumAppSnapshot {
        MegrumAppSnapshot(
            viewer: viewer,
            inventory: [],
            wishes: [],
            proposals: [],
            grooms: [],
            threads: []
        )
    }
}

private struct PlaceholderAccountSetupRepository: MegrumRepository {
    private let viewerID = UUID(uuidString: "70000000-0000-0000-0000-000000000001")!

    func loadInitialSnapshot() async throws -> MegrumAppSnapshot {
        MegrumAppSnapshot(
            viewer: UserProfile(
                id: viewerID,
                handle: "megrum",
                displayName: "Megrum",
                accountStatus: .onboarding
            ),
            inventory: [],
            wishes: [],
            proposals: [],
            grooms: [],
            threads: []
        )
    }

    func completeAccountSetup(_ input: AccountSetupInput) async throws -> UserProfile {
        UserProfile(
            id: viewerID,
            handle: input.handle,
            displayName: input.displayName,
            gender: input.gender,
            prefecture: input.prefecture,
            birthDate: input.birthDate,
            age: ProfileBirthDateCodec.age(from: input.birthDate),
            accountStatus: .active
        )
    }
}

private actor AccountDeletionRecordingRepository: MegrumRepository {
    static let viewerID = UUID(uuidString: "60000000-0000-0000-0000-000000000001")!
    static let partnerID = UUID(uuidString: "60000000-0000-0000-0000-000000000002")!

    private let proposals: [TradeProposal]
    private var inputs: [AccountDeletionRequestInput] = []

    init(proposals: [TradeProposal]) {
        self.proposals = proposals
    }

    func loadInitialSnapshot() async throws -> MegrumAppSnapshot {
        MegrumAppSnapshot(
            viewer: UserProfile(
                id: Self.viewerID,
                handle: "michilion",
                displayName: "みちりおん",
                accountStatus: .active
            ),
            inventory: [],
            wishes: [],
            proposals: proposals,
            grooms: [],
            threads: []
        )
    }

    func requestAccountDeletion(_ input: AccountDeletionRequestInput) async throws -> AccountDeletionRequestResult {
        inputs.append(input.normalized)
        return AccountDeletionRequestResult(
            deletionScheduledAt: Date(timeIntervalSince1970: 1_801_000_000)
        )
    }

    func inputsSnapshot() -> [AccountDeletionRequestInput] {
        inputs
    }
}

private struct NoPrefectureBoardCreationRepository: MegrumRepository {
    private let viewerID = UUID(uuidString: "55555555-5555-5555-5555-555555555555")!

    func loadInitialSnapshot() async throws -> MegrumAppSnapshot {
        MegrumAppSnapshot(
            viewer: UserProfile(
                id: viewerID,
                handle: "no_prefecture",
                displayName: "都道府県なし"
            ),
            inventory: [],
            wishes: [],
            proposals: [],
            grooms: [],
            threads: []
        )
    }

    func createBoardThread(_ input: BoardThreadCreateInput) async throws -> BoardThread {
        BoardThread(
            id: UUID(uuidString: "55555555-5555-5555-5555-555555555556")!,
            authorID: input.authorID,
            title: input.title.trimmingCharacters(in: .whitespacesAndNewlines),
            body: input.body.trimmingCharacters(in: .whitespacesAndNewlines),
            audience: input.audience,
            latitude: input.latitude,
            longitude: input.longitude,
            prefecture: input.prefecture
        )
    }
}

private actor PushDeviceRecordingRepository: MegrumRepository {
    private var registrations: [PushDeviceRegistration] = []
    private var revocations: [PushDeviceRevocation] = []

    func loadInitialSnapshot() async throws -> MegrumAppSnapshot {
        MegrumAppSnapshot(
            viewer: UserProfile(
                id: NativePreviewIDs.viewerID,
                handle: "michilion",
                displayName: "みちりおん"
            ),
            inventory: [],
            wishes: [],
            proposals: [],
            grooms: [],
            threads: []
        )
    }

    func registerNativePushDeviceToken(_ token: String, appVersion: String?) async throws {
        registrations.append(PushDeviceRegistration(token: token, appVersion: appVersion))
    }

    func revokeNativePushDeviceToken(_ token: String, revokedAt: Date) async throws {
        revocations.append(PushDeviceRevocation(token: token, revokedAt: revokedAt))
    }

    func registrationsSnapshot() -> [PushDeviceRegistration] {
        registrations
    }

    func revocationsSnapshot() -> [PushDeviceRevocation] {
        revocations
    }
}

private struct PushDeviceRegistration: Equatable, Sendable {
    var token: String
    var appVersion: String?
}

private struct PushDeviceRevocation: Equatable, Sendable {
    var token: String
    var revokedAt: Date
}

private enum NativePreviewIDs {
    static let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    static let groupID = UUID(uuidString: "00000000-0000-0000-0000-000000000011")!
    static let cardGoodsTypeID = UUID(uuidString: "00000000-0000-0000-0000-000000000021")!
}
