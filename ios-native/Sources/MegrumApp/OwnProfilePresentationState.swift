struct OwnProfilePresentationState: Equatable {
    var localDraft: OwnProfileEditDraft?
    var editDraft = OwnProfileEditDraft.empty
    var isProfileEditorPresented = false
    var isSchedulePresented = false
    var showsProfileCompletion = false
    var selectedProfileTab: ProfileVisualTab = .goods

    mutating func clearLocalDraft() {
        localDraft = nil
    }

    mutating func openSchedule() {
        isSchedulePresented = true
    }

    mutating func closeSchedule() {
        isSchedulePresented = false
    }

    mutating func openProfileEditor(summary: OwnProfileSummary) {
        editDraft = OwnProfileEditDraft(summary: summary)
        isProfileEditorPresented = true
    }

    mutating func markProfileSaved() {
        localDraft = nil
        showsProfileCompletion = true
    }
}
