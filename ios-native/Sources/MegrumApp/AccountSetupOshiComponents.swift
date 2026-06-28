import MegrumCore
import MegrumDesign
import SwiftUI

struct AccountSetupOshiHeader: View {
    var isLoading: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("推しを選ぶ")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Text("グループやメンバーを複数選べます")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
            }
            Spacer()
            if isLoading {
                ProgressView()
                    .controlSize(.small)
            }
        }
    }
}

struct AccountSetupOshiChip: View {
    var title: String
    var systemImage: String
    var isSelected: Bool
    var accessibilityHint: String
    var action: () -> Void

    var body: some View {
        Button {
            MegrumHaptics.performSelectionChanged(action)
        } label: {
            Label {
                Text(title)
            } icon: {
                Image(systemName: systemImage)
            }
            .font(.system(size: 15, weight: .black, design: .rounded))
            .lineLimit(1)
            .padding(.horizontal, 14)
            .frame(height: 42)
            .background(fillColor, in: Capsule())
            .foregroundStyle(foregroundColor)
            .overlay(
                Capsule()
                    .strokeBorder(borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityLabel(title)
        .accessibilityValue(isSelected ? "選択済み" : "未選択")
        .accessibilityHint(accessibilityHint)
    }

    private var fillColor: Color {
        isSelected ? MegrumTheme.lavender : Color.white.opacity(0.88)
    }

    private var foregroundColor: Color {
        isSelected ? Color.white : MegrumTheme.ink
    }

    private var borderColor: Color {
        isSelected ? Color.white.opacity(0.35) : MegrumTheme.lavender.opacity(0.18)
    }
}

struct AccountSetupSelectedOshiSummary: View {
    @Binding var selectedOshiDrafts: [OnboardingOshiDraft]
    var onClearInputError: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("選択中")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            if selectedOshiDrafts.isEmpty {
                Text("まだ選択されていません")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 16))
            } else {
                AccountSetupSelectedOshiDraftScroller(
                    selectedOshiDrafts: selectedOshiDrafts,
                    onRemoveDraft: removeDraft
                )
            }
        }
    }

    private func removeDraft(_ draft: OnboardingOshiDraft) {
        onClearInputError()
        selectedOshiDrafts.removeAll { $0.id == draft.id }
    }
}

private struct AccountSetupSelectedOshiDraftScroller: View {
    var selectedOshiDrafts: [OnboardingOshiDraft]
    var onRemoveDraft: (OnboardingOshiDraft) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(selectedOshiDrafts) { draft in
                    Button {
                        MegrumHaptics.performSelectionChanged {
                            onRemoveDraft(draft)
                        }
                    } label: {
                        AccountSetupSelectedOshiDraftChip(displayName: draft.displayName)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(draft.displayName)を選択から外す")
                }
            }
            .padding(.vertical, 2)
        }
    }
}

private struct AccountSetupSelectedOshiDraftChip: View {
    var displayName: String

    var body: some View {
        Label(displayName, systemImage: "xmark.circle.fill")
            .font(.system(size: 13, weight: .black, design: .rounded))
            .lineLimit(1)
            .padding(.horizontal, 12)
            .frame(height: 34)
            .background(MegrumTheme.lavender.opacity(0.14), in: Capsule())
            .foregroundStyle(MegrumTheme.lavender)
    }
}

struct AccountSetupSelectedGroupChip: View {
    var title: String
    var foregroundColor: Color
    var backgroundColor: Color

    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .black, design: .rounded))
            .lineLimit(1)
            .padding(.horizontal, 12)
            .frame(height: 34)
            .background(backgroundColor, in: Capsule())
            .foregroundStyle(foregroundColor)
    }
}

struct AccountSetupWholeGroupButton: View {
    var activeGroup: OshiGroup
    var isSelected: Bool
    var onToggle: () -> Void

    var body: some View {
        Button {
            MegrumHaptics.performSelectionChanged(onToggle)
        } label: {
            HStack {
                Text("グループ全体")
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(isSelected ? MegrumTheme.lavender.opacity(0.16) : Color.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 16))
        .foregroundStyle(isSelected ? MegrumTheme.lavender : MegrumTheme.ink)
        .accessibilityLabel("\(activeGroup.name) 全体")
        .accessibilityValue(isSelected ? "選択済み" : "未選択")
        .accessibilityHint("タップするとグループ全体の選択を切り替えます")
    }
}

struct AccountSetupOshiCharacterScroller: View {
    var activeGroup: OshiGroup
    var oshiCharacters: [OshiCharacter]
    var selectedOshiDrafts: [OnboardingOshiDraft]
    var onToggleCharacter: (OshiCharacter, OshiGroup) -> Void
    var onRequestMember: (() -> Void)? = nil

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(oshiCharacters) { character in
                    let isSelected = OnboardingOshiSelectionLogic.isCharacterSelected(character, in: selectedOshiDrafts)
                    AccountSetupOshiChip(
                        title: character.name,
                        systemImage: isSelected ? "checkmark.circle.fill" : "person.crop.circle",
                        isSelected: isSelected,
                        accessibilityHint: isSelected ? "タップするとこのメンバーを選択から外します" : "タップするとこのメンバーを推しに追加します"
                    ) {
                        onToggleCharacter(character, activeGroup)
                    }
                }

                if let onRequestMember {
                    OshiMemberRequestTag(action: onRequestMember)
                }
            }
            .padding(.vertical, 2)
        }
    }
}
