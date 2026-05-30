import Combine
import Foundation
import MegrumCore

public struct MegrumAppSnapshot: Sendable {
    public var viewer: UserProfile
    public var inventory: [GoodsItem]
    public var wishes: [WishItem]
    public var proposals: [TradeProposal]
    public var grooms: [GroomPost]
    public var threads: [BoardThread]

    public init(
        viewer: UserProfile,
        inventory: [GoodsItem],
        wishes: [WishItem],
        proposals: [TradeProposal],
        grooms: [GroomPost],
        threads: [BoardThread]
    ) {
        self.viewer = viewer
        self.inventory = inventory
        self.wishes = wishes
        self.proposals = proposals
        self.grooms = grooms
        self.threads = threads
    }
}

public struct AccountSetupInput: Equatable, Sendable {
    public var displayName: String
    public var prefecture: String?

    public init(displayName: String, prefecture: String? = nil) {
        self.displayName = displayName
        self.prefecture = prefecture
    }
}

public enum MegrumRepositoryError: Error, Equatable, Sendable {
    case unsupportedMutation
}

public protocol MegrumRepository: Sendable {
    func loadInitialSnapshot() async throws -> MegrumAppSnapshot
    func completeAccountSetup(_ input: AccountSetupInput) async throws -> UserProfile
}

public extension MegrumRepository {
    func completeAccountSetup(_ input: AccountSetupInput) async throws -> UserProfile {
        throw MegrumRepositoryError.unsupportedMutation
    }
}

public struct PreviewMegrumRepository: MegrumRepository {
    public init() {}

    public func loadInitialSnapshot() async throws -> MegrumAppSnapshot {
        MegrumAppSnapshot(
            viewer: NativePreviewData.viewer,
            inventory: NativePreviewData.inventory,
            wishes: NativePreviewData.wishes,
            proposals: NativePreviewData.proposals,
            grooms: NativePreviewData.grooms,
            threads: NativePreviewData.threads
        )
    }

    public func completeAccountSetup(_ input: AccountSetupInput) async throws -> UserProfile {
        UserProfile(
            id: NativePreviewData.viewer.id,
            handle: NativePreviewData.viewer.handle,
            displayName: input.displayName,
            avatarURL: NativePreviewData.viewer.avatarURL,
            prefecture: input.prefecture,
            accountStatus: .active
        )
    }
}

@MainActor
public final class MegrumAppState: ObservableObject {
    @Published public private(set) var viewer: UserProfile?
    @Published public private(set) var inventory: [GoodsItem] = []
    @Published public private(set) var wishes: [WishItem] = []
    @Published public private(set) var proposals: [TradeProposal] = []
    @Published public private(set) var grooms: [GroomPost] = []
    @Published public private(set) var threads: [BoardThread] = []
    @Published public private(set) var isLoading = false
    @Published public private(set) var isSavingAccountSetup = false
    @Published public private(set) var errorMessage: String?

    private var repository: any MegrumRepository

    public init(repository: any MegrumRepository = PreviewMegrumRepository()) {
        self.repository = repository
    }

    public func loadInitialData() async {
        guard !isLoading else {
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            apply(try await repository.loadInitialSnapshot())
        } catch {
            errorMessage = "データを読み込めませんでした"
        }

        isLoading = false
    }

    public func refresh() async {
        await loadInitialData()
    }

    public func replaceRepository(_ repository: any MegrumRepository) async {
        self.repository = repository
        await loadInitialData()
    }

    public func completeAccountSetup(displayName: String, prefecture: String?) async -> Bool {
        guard !isSavingAccountSetup else {
            return false
        }
        let trimmedDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDisplayName.isEmpty else {
            errorMessage = "表示名を入力してください"
            return false
        }

        isSavingAccountSetup = true
        errorMessage = nil

        do {
            viewer = try await repository.completeAccountSetup(
                AccountSetupInput(
                    displayName: trimmedDisplayName,
                    prefecture: prefecture?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank
                )
            )
            isSavingAccountSetup = false
            return true
        } catch {
            errorMessage = "プロフィールを保存できませんでした"
            isSavingAccountSetup = false
            return false
        }
    }

    private func apply(_ snapshot: MegrumAppSnapshot) {
        viewer = snapshot.viewer
        inventory = snapshot.inventory
        wishes = snapshot.wishes
        proposals = snapshot.proposals
        grooms = snapshot.grooms
        threads = snapshot.threads
    }
}

private extension String {
    var nilIfBlank: String? {
        isEmpty ? nil : self
    }
}
