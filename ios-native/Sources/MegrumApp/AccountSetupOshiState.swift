import Foundation
import MegrumCore

struct AccountSetupOshiState {
    var isSelectingMembers = false
    var searchText = ""
    var selectedGenreID: UUID?
    var selectedGroups: [OshiGroup] = []
    var selectedDrafts: [OnboardingOshiDraft] = []
    var charactersByGroupID: [UUID: [OshiCharacter]] = [:]
    var isLoadingSelectedMembers = false
    var requestSheet: OshiRequestSheetState?
    var memberRequestContext: OshiMemberRequestContext?
}
