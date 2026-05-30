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
        XCTAssertFalse(state.proposals.isEmpty)
        XCTAssertFalse(state.grooms.isEmpty)
        XCTAssertFalse(state.threads.isEmpty)
        XCTAssertFalse(state.isLoading)
        XCTAssertNil(state.errorMessage)
    }

    func testFactoryFallsBackToPreviewWithoutSupabaseConfig() async {
        let state = MegrumAppStateFactory.make(environment: [:], infoDictionary: [:])

        await state.loadInitialData()

        XCTAssertEqual(state.viewer?.handle, "michilion")
        XCTAssertFalse(state.inventory.isEmpty)
    }

    func testAppStateRefreshesPreviewMeguriFeed() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())

        await state.loadInitialData()
        await state.loadMeguriFeed(scope: .nearby3km)

        XCTAssertFalse(state.grooms.isEmpty)
        XCTAssertEqual(state.threads.map(\.audience), [.nearby3km])
        XCTAssertFalse(state.isLoadingMeguri)

        await state.loadMeguriFeed(scope: .samePrefecture)

        XCTAssertTrue(state.threads.contains { $0.audience == .samePrefecture })
        XCTAssertTrue(state.threads.contains { $0.audience == .nearby3km })
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
            longitude: 139.767125
        )

        XCTAssertTrue(created)
        XCTAssertEqual(state.threads.count, initialCount + 1)
        XCTAssertEqual(state.threads.first?.title, "終演後の混雑")
        XCTAssertEqual(state.threads.first?.body, "北口はまだゆっくり進めます")
        XCTAssertEqual(state.threads.first?.audience, .nearby3km)
        XCTAssertFalse(state.isCreatingBoardThread)
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

        let completed = await state.completeAccountSetup(
            displayName: "みちりおん",
            prefecture: "山形県",
            oshiSelections: [
                AccountSetupOshiInput(groupID: groupID, characterID: nil, kind: .box)
            ]
        )

        XCTAssertTrue(completed)
        XCTAssertEqual(state.viewer?.displayName, "みちりおん")
        XCTAssertEqual(state.viewer?.prefecture, "山形県")
        XCTAssertEqual(state.viewer?.accountStatus, .active)
        XCTAssertFalse(state.isSavingAccountSetup)
    }

    func testAppStateRequiresOshiSelectionForAccountSetup() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())

        let completed = await state.completeAccountSetup(displayName: "みちりおん", prefecture: "山形県")

        XCTAssertFalse(completed)
        XCTAssertEqual(state.errorMessage, "推しを選択してください")
    }

    func testAppStateLoadsPreviewOshiGroupsAndCharacters() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())

        await state.loadOshiGroups(searchText: "TWICE")
        await state.loadOshiCharacters(group: state.oshiGroups.first)

        XCTAssertEqual(state.oshiGroups.first?.name, "TWICE")
        XCTAssertEqual(state.oshiCharacters.first?.name, "SANA")
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
                goodsTypeID: goodsTypeID
            )
        )

        XCTAssertTrue(createdInventory)
        XCTAssertTrue(createdWish)
        XCTAssertEqual(state.inventory.count, inventoryCount + 1)
        XCTAssertEqual(state.inventory.first?.title, "新しい在庫")
        XCTAssertEqual(state.inventory.first?.quantity, 2)
        XCTAssertEqual(state.wishes.count, wishCount + 1)
        XCTAssertEqual(state.wishes.first?.title, "新しいWish")
        XCTAssertFalse(state.isCreatingGoodsEntry)
    }

    func testAppStateSearchesPreviewGoods() async {
        let state = MegrumAppState(repository: PreviewMegrumRepository())
        await state.loadInitialData()

        await state.searchGoods(query: "ランダム")

        XCTAssertEqual(state.searchResults.first?.item.title, "ランダムトレカ B")
        XCTAssertEqual(state.searchResults.first?.bucket, .possible)
        XCTAssertFalse(state.isSearchingGoods)
        XCTAssertNil(state.errorMessage)
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

    func testAuthStateSignsInThroughRepository() async {
        let state = MegrumAuthState(repository: StubAuthRepository())

        await state.signIn(email: "michi@example.com", password: "password123")

        XCTAssertEqual(state.session?.user.email, "michi@example.com")
        XCTAssertTrue(state.isAuthenticated)
        XCTAssertFalse(state.isLoading)
        XCTAssertNil(state.errorMessage)
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

    func testAuthStateValidatesSignUpPasswordLength() async {
        let state = MegrumAuthState(repository: StubAuthRepository())

        await state.signUp(email: "michi@example.com", password: "short", handle: "michi1")

        XCTAssertNil(state.session)
        XCTAssertEqual(state.errorMessage, "メールアドレスと8文字以上のパスワードを入力してください")
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

private enum NativePreviewIDs {
    static let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    static let groupID = UUID(uuidString: "00000000-0000-0000-0000-000000000011")!
    static let cardGoodsTypeID = UUID(uuidString: "00000000-0000-0000-0000-000000000021")!
}
