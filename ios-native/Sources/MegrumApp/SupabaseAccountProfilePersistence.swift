import Foundation
import MegrumCore
import MegrumData

struct SupabaseAccountProfilePersistence: Sendable {
    struct ResolvedAvatarUpdate: Equatable, Sendable {
        var url: URL?
        var shouldEncode: Bool
    }

    private let client: SupabaseRESTClient
    private let oshiClient: SupabaseOshiClient
    private let profilePhotoStorage: SupabaseProfilePhotoStorage
    private let userID: UUID

    init(
        client: SupabaseRESTClient,
        oshiClient: SupabaseOshiClient,
        profilePhotoStorage: SupabaseProfilePhotoStorage,
        userID: UUID
    ) {
        self.client = client
        self.oshiClient = oshiClient
        self.profilePhotoStorage = profilePhotoStorage
        self.userID = userID
    }

    func loadViewer() async throws -> UserProfile {
        let rows = try await fetchViewerRows()
        return rows.first?.profile ?? Self.fallbackViewerProfile(userID: userID)
    }

    func updateOwnProfile(_ input: OwnProfileUpdateInput) async throws -> UserProfile {
        let uploadedAvatarURL = try await profilePhotoStorage.uploadIfNeeded(input.avatarUpload, userID: userID)
        let avatarUpdate = Self.resolvedAvatarUpdate(input: input, uploadedAvatarURL: uploadedAvatarURL)

        let rows: [UserRow] = try await client.updateRows(
            in: "users",
            values: Self.ownProfileUpdatePayload(input: input, avatarUpdate: avatarUpdate),
            select: UserRow.select,
            queryItems: Self.viewerQueryItems(userID: userID)
        )
        return rows.first?.profile ?? Self.fallbackOwnProfile(
            input: input,
            userID: userID,
            avatarURL: avatarUpdate.url
        )
    }

    func completeAccountSetup(_ input: AccountSetupInput) async throws -> UserProfile {
        let selections = Self.accountSetupSelections(from: input, userID: userID)
        if !selections.isEmpty {
            _ = try await oshiClient.replaceUserSelections(userID: userID, selections: selections)
        }

        let rows: [UserRow] = try await client.updateRows(
            in: "users",
            values: Self.accountSetupUpdatePayload(from: input),
            select: UserRow.select,
            queryItems: Self.viewerQueryItems(userID: userID)
        )
        return rows.first?.profile ?? Self.fallbackAccountSetupProfile(input: input, userID: userID)
    }

    private func fetchViewerRows() async throws -> [UserRow] {
        do {
            return try await client.fetchRows(
                from: "users",
                select: UserRow.select,
                queryItems: Self.viewerQueryItems(userID: userID)
            )
        } catch {
            return try await client.fetchRows(
                from: "users",
                select: UserRow.legacySelect,
                queryItems: Self.viewerQueryItems(userID: userID)
            )
        }
    }

    static func viewerQueryItems(userID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "id", value: "eq.\(userID.uuidString.lowercased())"),
            URLQueryItem(name: "limit", value: "1")
        ]
    }

    static func fallbackViewerProfile(userID: UUID) -> UserProfile {
        UserProfile(
            id: userID,
            handle: "megrum",
            displayName: "Megrum",
            prefecture: nil,
            accountStatus: .onboarding
        )
    }

    static func resolvedAvatarUpdate(
        input: OwnProfileUpdateInput,
        uploadedAvatarURL: URL?
    ) -> ResolvedAvatarUpdate {
        ResolvedAvatarUpdate(
            url: uploadedAvatarURL ?? (input.clearsAvatar ? nil : input.avatarURL),
            shouldEncode: input.avatarUpload != nil || input.clearsAvatar || input.avatarURL != nil
        )
    }

    static func ownProfileUpdatePayload(
        input: OwnProfileUpdateInput,
        avatarUpdate: ResolvedAvatarUpdate
    ) -> UserOwnProfileUpdatePayload {
        UserOwnProfileUpdatePayload(
            handle: input.handle,
            displayName: input.displayName,
            avatarUrl: avatarUpdate.url,
            shouldEncodeAvatarUrl: avatarUpdate.shouldEncode,
            gender: input.gender,
            primaryArea: input.prefecture,
            paymentMethods: input.paymentMethods
        )
    }

    static func fallbackOwnProfile(
        input: OwnProfileUpdateInput,
        userID: UUID,
        avatarURL: URL?
    ) -> UserProfile {
        UserProfile(
            id: userID,
            handle: input.handle,
            displayName: input.displayName,
            avatarURL: avatarURL,
            gender: input.gender,
            prefecture: input.prefecture,
            paymentMethods: input.paymentMethods,
            accountStatus: .active
        )
    }

    static func accountSetupSelections(
        from input: AccountSetupInput,
        userID: UUID
    ) -> [UserOshiSelection] {
        UserOshiSelectionPersistenceMapper.selections(
            from: input.oshiSelections,
            userID: userID
        )
    }

    static func accountSetupUpdatePayload(from input: AccountSetupInput) -> UserProfileUpdatePayload {
        UserProfileUpdatePayload(
            displayName: input.displayName,
            primaryArea: input.prefecture,
            accountStatus: AccountStatus.active.rawValue
        )
    }

    static func fallbackAccountSetupProfile(
        input: AccountSetupInput,
        userID: UUID
    ) -> UserProfile {
        UserProfile(
            id: userID,
            handle: "megrum",
            displayName: input.displayName,
            prefecture: input.prefecture,
            accountStatus: .active
        )
    }
}
