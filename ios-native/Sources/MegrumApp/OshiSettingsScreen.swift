import MegrumCore
import MegrumDesign
import SwiftUI

struct OshiSettingsScreen: View {
    @ObservedObject var appState: MegrumAppState
    var onClose: (() -> Void)?
    @Environment(\.dismiss) var dismiss
    @State var presentationState = OshiSettingsPresentationState()

    var body: some View {
        OshiSettingsMainContent(
            groups: presentationState.groups,
            isLoading: presentationState.isLoading || appState.isLoadingUserOshiSelections || appState.isLoadingOshiGroups,
            isSaving: presentationState.isSaving,
            errorMessage: presentationState.errorMessage,
            noticeMessage: presentationState.noticeMessage,
            expandedGroupKey: presentationState.expandedGroupKey,
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
        .sheet(isPresented: $presentationState.showsMasterSheet) {
            OshiMasterSelectSheet(
                genres: appState.oshiGenres,
                groups: appState.oshiGroups,
                selectedGroupIDs: Set(presentationState.groups.compactMap(\.groupID)),
                charactersByGroupID: presentationState.charactersByGroupID,
                onSearchCharacterGroups: { await appState.searchOshiCharacterGroupIDs(query: $0) },
                allowsMultipleSelection: true,
                onClose: { presentationState.showsMasterSheet = false },
                onRequest: { query in
                    presentationState.showsMasterSheet = false
                    presentationState.requestSheet = .oshi(initialName: query)
                },
                onSelect: addMasterGroupTapped,
                onRegisterSelected: addMasterGroupsTapped
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
        .sheet(item: $presentationState.requestSheet) { state in
            switch state {
            case .oshi:
                OshiRequestSheet(
                    state: state,
                    genres: appState.oshiGenres,
                    onClose: { presentationState.requestSheet = nil },
                    onSubmit: submitOshiRequestTapped
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
            case .member(let context):
                OshiMemberRequestSheet(
                    context: context,
                    onClose: { presentationState.requestSheet = nil },
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
