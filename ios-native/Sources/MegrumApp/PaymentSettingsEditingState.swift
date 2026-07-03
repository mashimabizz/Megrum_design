import Foundation
import MegrumCore

struct PaymentSettingsEditingState: Equatable, Sendable {
    private(set) var draft: PaymentSettingsDraft
    private(set) var validationMessage: String?
    private(set) var hasUserEditedDraft: Bool

    init(
        draft: PaymentSettingsDraft = .empty,
        validationMessage: String? = nil,
        hasUserEditedDraft: Bool = false
    ) {
        self.draft = draft
        self.validationMessage = validationMessage
        self.hasUserEditedDraft = hasUserEditedDraft
    }

    mutating func applyCurrentValues(
        settings: UserPaymentSettings?,
        viewer: UserProfile?,
        force: Bool = false
    ) {
        guard force || !hasUserEditedDraft else {
            return
        }
        draft = PaymentSettingsDraft(settings: settings, viewer: viewer)
        validationMessage = nil
    }

    mutating func toggleMethod(_ method: UserPaymentMethod) {
        draft.set(method, isSelected: !draft.contains(method))
        markEdited()
    }

    mutating func updateOtherNote(_ value: String) {
        draft.otherNote = PaymentSettingsDraft.limitedOtherNote(value)
        markEdited()
    }

    mutating func updateText(_ keyPath: WritableKeyPath<PaymentSettingsDraft, String>, value: String) {
        draft[keyPath: keyPath] = value
        markEdited()
    }

    mutating func settingsForSave(viewerID: UUID?) -> UserPaymentSettings? {
        let normalized = draft.normalized
        if let message = normalized.validationMessage {
            validationMessage = message
            return nil
        }
        guard let userID = viewerID else {
            validationMessage = "プロフィールを読み込めませんでした"
            return nil
        }
        return normalized.settings(userID: userID)
    }

    mutating func markSaveSucceeded() {
        hasUserEditedDraft = false
    }

    private mutating func markEdited() {
        hasUserEditedDraft = true
        validationMessage = nil
    }
}
