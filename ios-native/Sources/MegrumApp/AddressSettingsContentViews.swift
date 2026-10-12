import MegrumDesign
import SwiftUI

/// 住所設定の説明キャプション（iter1226.407）：
/// 34ptの巨大タイトルは navigationTitle と重複していたため廃止し、説明文のみ残す。
struct AddressSettingsHeader: View {
    var body: some View {
        Text("取引で必要になる住所を、本人だけが編集できます。相手には双方の合意後にのみ表示されます。")
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(MegrumTheme.muted)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct AddressSettingsSaveButton: View {
    var title: String
    var isSaving: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isSaving {
                    ProgressView()
                        .tint(.white)
                }
                Text(title)
            }
        }
        .buttonStyle(.megrumPrimary)
        .disabled(isSaving)
        .accessibilityHint("入力した住所を保存します")
    }
}

struct AddressSettingsErrorBanner: View {
    var message: String

    var body: some View {
        Text(message)
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundStyle(MegrumTheme.conditionExact)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(MegrumTheme.conditionExact.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
            .accessibilityLabel(message)
    }
}
