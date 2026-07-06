import MegrumCore
import SwiftUI

struct AccountSetupStepContent: View {
    var step: AccountSetupStep
    var isSelectingOshiMembers: Bool
    var selectedMemberTargets: [OnboardingOshiMemberTarget]
    @Binding var selectedOshiDrafts: [OnboardingOshiDraft]
    var charactersByGroupID: [UUID: [OshiCharacter]]
    var isLoadingSelectedMembers: Bool
    var isLoadingOshiCharacters: Bool
    var groups: [OshiGroup]
    var categoryOptions: [OshiCategoryOption]
    @Binding var selectedGenreID: UUID?
    @Binding var oshiSearchText: String
    @Binding var selectedOshiGroups: [OshiGroup]
    var isLoadingOshiGroups: Bool
    @Binding var selectedPrefecture: String
    @Binding var prefectureSearchText: String
    @Binding var displayName: String
    @Binding var handle: String
    @Binding var birthDate: Date
    @Binding var gender: UserGender?
    var isSaving: Bool
    var setupErrorMessage: String?
    var appErrorMessage: String?
    @FocusState.Binding var focusedField: AccountSetupFocusedField?
    var onClearError: () -> Void
    var onRequestOshi: (String) -> Void
    var onRequestMember: (OshiMemberRequestContext) -> Void

    private var combinedErrorMessage: String? {
        setupErrorMessage ?? appErrorMessage
    }

    var body: some View {
        switch step {
        case .welcome:
            AccountSetupWelcomeStep()
        case .oshi:
            oshiStep
        case .area:
            AccountSetupAreaStep(
                selectedPrefecture: $selectedPrefecture,
                searchText: $prefectureSearchText,
                errorMessage: setupErrorMessage,
                focusedField: $focusedField,
                onClearError: onClearError
            )
        case .displayName:
            AccountSetupTextInputStep(
                label: "表示名",
                placeholder: "例)めぐるむ",
                text: $displayName,
                focusedField: $focusedField,
                focusCase: .displayName,
                footnote: "本名や個人が特定できる情報は避けてください。あとから変更できます。",
                errorMessage: setupErrorMessage,
                onClearError: onClearError
            )
        case .handle:
            AccountSetupTextInputStep(
                label: "ユーザーID",
                placeholder: "megrum_id",
                text: $handle,
                focusedField: $focusedField,
                focusCase: .handle,
                leadingText: "@",
                isHandleField: true,
                footnote: "半角英数字と _ の3〜20文字で設定してください。ユーザーIDは登録後に変更できません。",
                errorMessage: setupErrorMessage,
                onClearError: onClearError
            )
        case .birthDate:
            AccountSetupBirthDateStep(
                birthDate: $birthDate,
                errorMessage: setupErrorMessage,
                onClearError: onClearError
            )
        case .gender:
            AccountSetupGenderStep(
                gender: $gender,
                errorMessage: setupErrorMessage,
                onClearError: onClearError
            )
        case .completion:
            AccountSetupCompletionStep(
                displayName: displayName,
                handle: handle,
                prefecture: selectedPrefecture,
                birthDate: birthDate,
                gender: gender,
                selectedOshiDrafts: selectedOshiDrafts,
                isSaving: isSaving,
                errorMessage: combinedErrorMessage
            )
        }
    }

    @ViewBuilder
    private var oshiStep: some View {
        if isSelectingOshiMembers {
            AccountSetupOshiMemberStep(
                targets: selectedMemberTargets,
                selectedOshiDrafts: $selectedOshiDrafts,
                charactersByGroupID: charactersByGroupID,
                isLoading: isLoadingSelectedMembers || isLoadingOshiCharacters,
                errorMessage: combinedErrorMessage,
                onClearError: onClearError,
                onRequestMember: onRequestMember
            )
        } else {
            AccountSetupOshiMasterStep(
                groups: groups,
                categoryOptions: categoryOptions,
                selectedGenreID: $selectedGenreID,
                searchText: $oshiSearchText,
                selectedGroups: $selectedOshiGroups,
                requestedDrafts: selectedOshiDrafts.filter { $0.oshiRequestID != nil },
                isLoading: isLoadingOshiGroups,
                errorMessage: combinedErrorMessage,
                focusedField: $focusedField,
                onClearError: onClearError,
                onRequestOshi: onRequestOshi
            )
        }
    }
}
