import MegrumCore

enum OshiSettingsPresentationText {
    static func groupSummary(for group: OshiSettingsGroupDraft) -> String? {
        guard !group.members.isEmpty else {
            return nil
        }
        return "推しメンバー \(group.members.count)人"
    }

    static func selectedMemberTitle(_ member: OshiSettingsMemberDraft) -> String {
        member.pending ? "\(member.name)（承認待ち）" : member.name
    }

    static func availableMemberTitle(_ character: OshiCharacter) -> String {
        character.name
    }

    static func memberToggleTitle(isExpanded: Bool) -> String {
        isExpanded ? "閉じる" : "追加"
    }

    static func masterRegisterButtonTitle(selectionCount: Int) -> String {
        selectionCount == 1 ? "推しを登録" : "\(selectionCount)件の推しを登録"
    }

    static func masterSelectionCountTitle(selectionCount: Int) -> String {
        "\(selectionCount)件選択中"
    }

    static let memberRequestTagTitle = "追加リクエスト"
    static let memberRequestSheetTitle = "メンバー追加リクエスト"
    static let memberRequestPlaceholder = "メンバー名・キャラ名"
    static let memberRequestSubmitSuccess = "メンバー追加リクエストを送信し、仮登録しました。"

    static let removeGroupConfirmationTitle = "本当に削除しますか？"
    static let removeGroupConfirmationMessage = "この推しを推し設定から削除します。"
    static let removeGroupConfirmationAction = "削除する"
}
