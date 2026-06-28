import MegrumCore
import MegrumDesign
import SwiftUI

@MainActor
struct MeguriProfileSettingsSheet: View {
    @ObservedObject var appState: MegrumAppState
    @Environment(\.dismiss) private var dismiss
    @State private var displayName = ""
    @State private var selectedAvatarID = BoardAnonymousAvatarOption.options[0].id
    @State private var localAlertMessage: String?

    private var currentProfile: MeguriProfile? {
        appState.meguriProfile
    }

    private var lockMessage: String? {
        guard let lockedUntil = currentProfile?.lockedUntil() else {
            return nil
        }
        return "次回は\(lockedUntil.formatted(date: .numeric, time: .omitted))以降に変更できます。"
    }

    private var canSave: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !appState.isSavingMeguriProfile
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                headerSection
                nameSection
                avatarSection
                lockSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .navigationTitle("めぐりプロフィール")
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    save()
                } label: {
                    if appState.isSavingMeguriProfile {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("保存")
                    }
                }
                .disabled(!canSave)
            }
        }
        .task {
            await appState.loadMeguriProfile(reportsFailure: false)
            hydrateDraft()
        }
        .onChange(of: appState.meguriProfile) { _, _ in
            hydrateDraftIfNeeded()
        }
        .alert("保存できませんでした", isPresented: Binding(
            get: { localAlertMessage != nil },
            set: { if !$0 { localAlertMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(localAlertMessage ?? "")
        }
    }

    private var headerSection: some View {
        VStack(alignment: .center, spacing: 10) {
            MeguriProfileAvatarView(
                avatarID: selectedAvatarID,
                avatarURL: appState.viewer?.avatarURL,
                fallback: displayName.nilIfBlank ?? "め",
                size: 76
            )

            Text("めぐりプロフィール")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
        }
        .frame(maxWidth: .infinity)
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("名前")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            nameField

            Text("全ユーザーで同じ名前は使えません。変更できるのは1ヶ月に1回です。")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var nameField: some View {
        #if os(iOS)
        TextField("例：まくはり民", text: $displayName)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .padding(15)
            .background(
                Color.white.opacity(0.92),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
        #else
        TextField("例：まくはり民", text: $displayName)
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .padding(15)
            .background(
                Color.white.opacity(0.92),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
        #endif
    }

    private var avatarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("アイコン")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            LazyVGrid(columns: avatarColumns, spacing: 14) {
                ForEach(BoardAnonymousAvatarOption.options) { option in
                    avatarButton(option)
                }
            }
        }
    }

    private var avatarColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
    }

    private func avatarButton(_ option: BoardAnonymousAvatarOption) -> some View {
        Button {
            selectedAvatarID = option.id
        } label: {
            VStack(spacing: 8) {
                BoardAnonymousAvatar(
                    option: option,
                    isSelected: selectedAvatarID == option.id,
                    size: 48
                )
                Text(option.title)
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                .white.opacity(0.72),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(option.title)を選択")
    }

    @ViewBuilder
    private var lockSection: some View {
        if let lockMessage {
            Label(lockMessage, systemImage: "lock.fill")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.pink)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    MegrumTheme.pink.opacity(0.08),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
        }
    }

    private func hydrateDraftIfNeeded() {
        guard displayName.isBlank else {
            return
        }
        hydrateDraft()
    }

    private func hydrateDraft() {
        displayName = currentProfile?.displayName
            ?? appState.viewer?.displayName
            ?? ""
        selectedAvatarID = currentProfile?.avatarID.nilIfBlank
            ?? BoardAnonymousAvatarOption.options[0].id
    }

    private func save() {
        Task {
            let saved = await appState.saveMeguriProfile(
                displayName: displayName,
                avatarID: selectedAvatarID
            )
            if saved {
                dismiss()
            } else {
                localAlertMessage = appState.errorMessage ?? "めぐりプロフィールを保存できませんでした"
            }
        }
    }
}
