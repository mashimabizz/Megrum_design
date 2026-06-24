import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct IndividualListingMemberPickerSheet: View {
    var groupName: String
    var characters: [OshiCharacter]
    var selectedIDs: Set<UUID>
    @Binding var excludesSelectedMembers: Bool
    var onToggle: (UUID) -> Void
    var onClose: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if characters.isEmpty {
                        Text("メンバー候補はまだありません")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(18)
                            .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    } else {
                        WrappingTagFlow(spacing: 6, rowSpacing: 7) {
                            ForEach(characters) { character in
                                memberButton(character)
                            }
                        }
                    }

                    if !selectedIDs.isEmpty {
                        Toggle(isOn: $excludesSelectedMembers) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("選んだメンバー以外で指定")
                                    .font(.system(size: 15, weight: .black, design: .rounded))
                                    .foregroundStyle(MegrumTheme.ink)
                                Text("例：モモ・サナ以外なら、その他メンバーを希望します。")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundStyle(MegrumTheme.muted)
                            }
                        }
                        .tint(MegrumTheme.lavender)
                        .padding(16)
                        .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
                .padding(20)
            }
            .background(MegrumTheme.canvas.ignoresSafeArea())
            .navigationTitle(groupName)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる", action: onClose)
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                }
            }
        }
    }

    private func memberButton(_ character: OshiCharacter) -> some View {
        let selected = selectedIDs.contains(character.id)
        return Button {
            onToggle(character.id)
        } label: {
            HStack(spacing: 7) {
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .black))
                }
                Text(character.name)
                    .lineLimit(1)
            }
            .font(.system(size: 14, weight: .black, design: .rounded))
            .foregroundStyle(selected ? .white : MegrumTheme.ink)
            .padding(.horizontal, 12)
            .frame(height: 38)
            .background(
                selected ? AnyShapeStyle(MegrumTheme.lavender) : AnyShapeStyle(.white.opacity(0.92)),
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .strokeBorder(selected ? MegrumTheme.lavender : MegrumTheme.ink.opacity(0.08), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}
