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

    /// 候補のうち使用済みのユーザーID（小文字）を返す。自分の行は除外（現IDは「使える」扱い）。
    func takenAccountHandles(among handles: [String]) async throws -> Set<String> {
        let normalized = handles
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
        guard !normalized.isEmpty else {
            return []
        }
        struct HandleRow: Decodable {
            var handle: String
        }
        let rows: [HandleRow] = try await client.fetchRows(
            from: "users",
            select: "handle",
            queryItems: [
                URLQueryItem(name: "handle", value: "in.(\(normalized.joined(separator: ",")))"),
                URLQueryItem(name: "id", value: "neq.\(userID.uuidString)")
            ]
        )
        return Set(rows.map { $0.handle.lowercased() })
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
            // 旧スキーマ（birth_date等の列なし）だけレガシーへ。制約違反や重複を
            // ここで握りつぶすと生年月日などが黙って消えるため（iter1226.422）。
            guard Self.isSchemaMismatchError(error) else {
                throw error
            }
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
            // 旧スキーマ（birth_date/age列なし）だけレガシーへ。それ以外（重複・制約違反・通信）を
            // 黙ってフォールバックすると、生年月日が保存されないままセットアップが「成功」してしまう。
            guard Self.isSchemaMismatchError(error) else {
                throw error
            }
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

    /// PostgREST の「列が存在しない」系エラーか（PGRST204 / 42703。HTTP 400＋columnを含むメッセージ）。
    static func isSchemaMismatchError(_ error: Error) -> Bool {
        guard let restError = error as? SupabaseRESTError, restError.statusCode == 400 else {
            return false
        }
        let message = restError.serverMessage?.lowercased() ?? ""
        return message.contains("column") || message.contains("schema cache")
    }

    private func fetchViewerRows() async throws -> [UserRow] {
        do {
            return try await client.fetchRows(
                from: "users",
                select: UserRow.select,
                queryItems: Self.viewerQueryItems(userID: userID)
            )
        } catch {
            // レガシーselect（birth_date等なし）へのフォールバックは、列が存在しない
            // スキーマ不一致（400）の時だけにする。通信エラー等の一時失敗で
            // フォールバックすると、生年月日などがそのセッション中ずっと
            // 「未設定」表示になってしまう。
            guard (error as? SupabaseRESTError)?.statusCode == 400 else {
                throw error
            }
            return try await client.fetchRows(
                from: "users",
                select: UserRow.legacySelect,
                queryItems: Self.viewerQueryItems(userID: userID)
            )
        }
    }
}
