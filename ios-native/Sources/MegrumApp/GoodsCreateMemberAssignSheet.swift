import MegrumCore
import MegrumDesign
import SwiftUI

/// マイグッズ登録・詳細ステップの「メンバー登録」シート（iter1226.436）。
/// 以前は confirmationDialog だったが、メンバーが多いと下の2〜3件が
/// 初期表示されない描画バグがあったため、標準の List シートで全件表示する。
struct GoodsCreateMemberAssignSheet: View {
    var memberOptions: [OshiCharacter]
    var selectedCount: Int
    var onAssignMember: (UUID?) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(memberOptions) { member in
                        Button {
                            MegrumHaptics.buttonTap()
                            onAssignMember(member.id)
                            dismiss()
                        } label: {
                            HStack {
                                Text(member.name)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(MegrumTheme.ink)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(MegrumTheme.muted)
                            }
                        }
                    }
                } footer: {
                    Text("\(selectedCount)件の画像に同じメンバーを割り当てます。")
                }

                Section {
                    Button(role: .destructive) {
                        onAssignMember(nil)
                        dismiss()
                    } label: {
                        Text("メンバー未設定に戻す")
                    }
                }
            }
            .navigationTitle("メンバーを登録")
            .megrumInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}
