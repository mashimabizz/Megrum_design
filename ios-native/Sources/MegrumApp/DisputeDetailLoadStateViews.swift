import MegrumDesign
import SwiftUI

struct DisputeDetailLoadingStateView: View {
    var body: some View {
        List {
            Section {
                HStack {
                    Spacer()
                    ProgressView("読み込み中")
                    Spacer()
                }
                .padding(.vertical, 32)
            }
        }
        .scrollContentBackground(.hidden)
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .disputeDetailListStyle()
    }
}

struct DisputeDetailEmptyStateView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.bubble")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(MegrumTheme.muted)
                    Text("申告が見つかりません")
                        .font(.headline)
                        .foregroundStyle(MegrumTheme.ink)
                    Text("取引チャットや通知から、もう一度開いてください。")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(MegrumTheme.muted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            }
        }
        .scrollContentBackground(.hidden)
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .disputeDetailListStyle()
    }
}

struct DisputeDetailErrorStateView: View {
    var message: String
    var onRetry: () -> Void

    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(MegrumTheme.muted)
                    Text("読み込めませんでした")
                        .font(.headline)
                        .foregroundStyle(MegrumTheme.ink)
                    Text(message)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(MegrumTheme.muted)
                    Button {
                        onRetry()
                    } label: {
                        Label("再読み込み", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            }
        }
        .scrollContentBackground(.hidden)
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .disputeDetailListStyle()
    }
}

private extension View {
    @ViewBuilder
    func disputeDetailListStyle() -> some View {
        #if os(iOS)
        self.listStyle(.insetGrouped)
        #else
        self
        #endif
    }
}
