import MegrumCore
import MegrumDesign
import SwiftUI

struct PublicProfileModerationTarget: Identifiable, Equatable {
    var id: UUID { userID }
    var userID: UUID
    var displayName: String
}

struct UserReportSheet: View {
    var target: PublicProfileModerationTarget
    var isSubmitting: Bool
    var onSubmit: (UserReportReason, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var reason: UserReportReason = .harassment
    @State private var note = ""

    var body: some View {
        Form {
            Section("対象") {
                Text(target.displayName)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
            }

            Section("理由") {
                Picker("理由", selection: $reason) {
                    ForEach(UserReportReason.allCases) { reason in
                        Text(reason.displayName).tag(reason)
                    }
                }
            }

            Section("補足") {
                TextEditor(text: $note)
                    .frame(minHeight: 120)
            }
        }
        .navigationTitle("通報")
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("キャンセル") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("送信") {
                    onSubmit(reason, note)
                    dismiss()
                }
                .disabled(isSubmitting)
            }
        }
    }
}
