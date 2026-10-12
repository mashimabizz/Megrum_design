import MegrumDesign
import SwiftUI

/// 通信状態が悪くデータ取得できない時に、ホーム画面の先頭で状況を伝えるバナー（iter1226.465）。
///
/// 端末キャッシュを表示している旨と、再読み込みの導線を控えめに提示する。
/// タップまたは「再読み込み」で最新取得を再試行する。
struct HomeOfflineNoticeBanner: View {
    var isRetrying: Bool = false
    var onRetry: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(MegrumTheme.conditionPossible)
                .frame(width: 26, height: 26)
                .background(MegrumTheme.conditionPossible.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("オフライン表示中")
                    .font(.system(size: 13.5, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Text("通信状態が悪く最新のデータを取得できません。保存済みの内容を表示しています。")
                    .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 6)

            Button(action: onRetry) {
                Group {
                    if isRetrying {
                        ProgressView()
                            .controlSize(.small)
                            .tint(MegrumTheme.ink)
                    } else {
                        Text("再読み込み")
                            .font(.system(size: 11.5, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.ink)
                    }
                }
                .padding(.horizontal, 12)
                .frame(height: 30)
                .background(.white, in: Capsule())
                .overlay {
                    Capsule().strokeBorder(MegrumTheme.ink.opacity(0.10), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
            .disabled(isRetrying)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MegrumTheme.conditionPossible.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(MegrumTheme.conditionPossible.opacity(0.22), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("オフライン表示中。通信状態が悪く最新のデータを取得できません。保存済みの内容を表示しています。")
        .accessibilityHint("再読み込みで最新の取得を試みます")
    }
}
