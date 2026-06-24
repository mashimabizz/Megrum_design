import Foundation
import MegrumCore

@MainActor
extension MegrumAppState {
    public func loadOshiGroups(searchText: String? = nil) async {
        guard !isLoadingOshiGroups else {
            return
        }

        isLoadingOshiGroups = true
        errorMessage = nil
        do {
            async let groups = repository.loadOshiGroups(searchText: searchText, limit: 500)
            async let genres = repository.loadOshiGenres(limit: 100)
            oshiGroups = try await groups
            oshiGenres = try await genres
        } catch {
            errorMessage = "推しグループを読み込めませんでした"
        }
        isLoadingOshiGroups = false
    }

    public func loadOshiCharacters(group: OshiGroup?) async {
        guard !isLoadingOshiCharacters else {
            return
        }
        guard let group else {
            oshiCharacters = []
            return
        }

        isLoadingOshiCharacters = true
        errorMessage = nil
        do {
            oshiCharacters = try await repository.loadOshiCharacters(groupID: group.id, limit: 1_000)
        } catch {
            errorMessage = "推しメンバーを読み込めませんでした"
        }
        isLoadingOshiCharacters = false
    }

    public func loadMemberFaceProfiles(memberIDs: [UUID]) async -> [MemberFaceProfile] {
        let uniqueIDs = Array(Set(memberIDs))
        guard !uniqueIDs.isEmpty else {
            return []
        }

        do {
            return try await repository.loadMemberFaceProfiles(
                memberIDs: uniqueIDs,
                limit: max(40, uniqueIDs.count * 20)
            )
        } catch {
            #if DEBUG
            MegrumAppLogger.general.debug("Member face profiles could not be loaded: \(String(describing: error), privacy: .public)")
            #endif
            return []
        }
    }

    public func loadUserOshiSelections() async {
        guard !isLoadingUserOshiSelections else {
            return
        }

        isLoadingUserOshiSelections = true
        errorMessage = nil
        do {
            userOshiSelections = try await repository.loadUserOshiSelections()
        } catch {
            errorMessage = "推し設定を読み込めませんでした"
        }
        isLoadingUserOshiSelections = false
    }

    public func saveOshiSelections(_ oshiSelections: [AccountSetupOshiInput]) async -> Bool {
        do {
            userOshiSelections = try await repository.saveUserOshiSelections(oshiSelections)
            errorMessage = nil
            return true
        } catch {
            errorMessage = "推し設定を保存できませんでした"
            return false
        }
    }

    public func createOshiRequest(_ input: OshiRequestCreateInput) async -> UUID? {
        do {
            errorMessage = nil
            return try await repository.createOshiRequest(input)
        } catch {
            errorMessage = "推し追加リクエストを送信できませんでした"
            return nil
        }
    }

    public func createCharacterRequest(_ input: CharacterRequestCreateInput) async -> UUID? {
        do {
            errorMessage = nil
            return try await repository.createCharacterRequest(input)
        } catch {
            errorMessage = "メンバー追加リクエストを送信できませんでした"
            return nil
        }
    }
}
