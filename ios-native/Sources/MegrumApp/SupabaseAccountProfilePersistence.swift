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

        do {
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
        } catch {
            let rows: [UserRow] = try await client.updateRows(
                in: "users",
                values: Self.legacyOwnProfileUpdatePayload(input: input, avatarUpdate: avatarUpdate),
                select: UserRow.legacySelect,
                queryItems: Self.viewerQueryItems(userID: userID)
            )
            return Self.mergedOwnProfile(
                storedProfile: rows.first?.profile,
                input: input,
                userID: userID,
                avatarURL: avatarUpdate.url
            )
        }
    }

    func completeAccountSetup(_ input: AccountSetupInput) async throws -> UserProfile {
        let rows = try await upsertAccountSetupProfile(input, accountStatus: .active)
        let profile = Self.mergedAccountSetupProfile(
            storedProfile: rows.first?.profile,
            input: input,
            userID: userID
        )
        let selections = Self.accountSetupSelections(from: input, userID: userID)
        if !selections.isEmpty {
            do {
                _ = try await oshiClient.replaceUserSelections(userID: userID, selections: selections)
            } catch {
                #if DEBUG
                MegrumAppLogger.general.debug("Account setup oshi save failed: \(String(describing: error), privacy: .public)")
                #endif
            }
        }

        return profile
    }

    private func upsertAccountSetupProfile(
        _ input: AccountSetupInput,
        accountStatus: AccountStatus
    ) async throws -> [UserRow] {
        do {
            return try await client.upsertRows(
                into: "users",
                values: [
                    Self.accountSetupUpsertPayload(
                        from: input,
                        userID: userID,
                        accountStatus: accountStatus
                    )
                ],
                select: Self.accountSetupProfileSelect,
                onConflict: "id"
            )
        } catch {
            return try await client.upsertRows(
                into: "users",
                values: [
                    Self.accountSetupLegacyUpsertPayload(
                        from: input,
                        userID: userID,
                        accountStatus: accountStatus
                    )
                ],
                select: Self.accountSetupProfileSelect,
                onConflict: "id"
            )
        }
    }

    func requestAccountDeletion(_ input: AccountDeletionRequestInput) async throws -> AccountDeletionRequestResult {
        let rows: [AccountDeletionRequestRow] = try await client.rpcRows(
            function: "request_account_deletion_for_viewer",
            payload: Self.accountDeletionPayload(from: input)
        )
        return AccountDeletionRequestResult(deletionScheduledAt: rows.first?.deletionScheduledAt)
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
}
