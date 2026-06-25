import MegrumCore
import MegrumDesign
import SwiftUI

struct OshiSettingsScreen: View {
    @ObservedObject var appState: MegrumAppState
    @Environment(\.dismiss) var dismiss
    @State var groups: [OshiSettingsGroupDraft] = []
    @State var charactersByGroupID: [UUID: [OshiCharacter]] = [:]
    @State var expandedGroupKey: String?
    @State var isSaving = false
    @State var isLoading = false
    @State var noticeMessage: String?
    @State var errorMessage: String?
    @State var showsMasterSheet = false
    @State var requestSheet: OshiRequestSheetState?

    var body: some View {
        OshiSettingsMainContent(
            groups: groups,
            isLoading: isLoading || appState.isLoadingUserOshiSelections || appState.isLoadingOshiGroups,
            isSaving: isSaving,
            errorMessage: errorMessage,
            noticeMessage: noticeMessage,
            expandedGroupKey: expandedGroupKey,
            availableCharacters: availableCharacters(for:),
            onBack: closeScreen,
            onShowMasterSheet: showMasterSheet,
            onToggleExpanded: toggleExpandedGroup,
            onRemoveGroup: removeGroupTapped,
            onRemoveMember: removeMemberTapped(_:from:),
            onAddMember: addMemberTapped(_:to:),
            onRequestMember: requestMemberTapped
        )
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .megrumHiddenNavigationBar()
        .sheet(isPresented: $showsMasterSheet) {
            OshiMasterSelectSheet(
                genres: appState.oshiGenres,
                groups: appState.oshiGroups,
                selectedGroupIDs: Set(groups.compactMap(\.groupID)),
                charactersByGroupID: charactersByGroupID,
                allowsMultipleSelection: true,
                onClose: { showsMasterSheet = false },
                onRequest: { query in
                    showsMasterSheet = false
                    requestSheet = .oshi(initialName: query)
                },
                onSelect: addMasterGroupTapped,
                onRegisterSelected: addMasterGroupsTapped
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
        .sheet(item: $requestSheet) { state in
            switch state {
            case .oshi:
                OshiRequestSheet(
                    state: state,
                    genres: appState.oshiGenres,
                    onClose: { requestSheet = nil },
                    onSubmit: submitOshiRequestTapped
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
            case .member(let context):
                OshiMemberRequestSheet(
                    context: context,
                    onClose: { requestSheet = nil },
                    onSubmit: { submitMemberRequestTapped($0, context: context) }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
        .task {
            await prepare()
        }
    }
}
