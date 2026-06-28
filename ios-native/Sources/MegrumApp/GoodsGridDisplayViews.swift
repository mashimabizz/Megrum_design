import MegrumCore
import MegrumDesign
import SwiftUI

struct GoodsReportSheet: View {
    var item: GoodsItem
    var onSubmit: (GoodsReportReason, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var reason: GoodsReportReason = .fakeItem
    @State private var note = ""

    var body: some View {
        Form {
            Section("対象") {
                Text(item.title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
            }

            Section("理由") {
                Picker("理由", selection: $reason) {
                    ForEach(GoodsReportReason.allCases) { reason in
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
            }
        }
    }
}

struct GoodsTagPill: View {
    var name: String
    var fontSize: CGFloat
    var horizontalPadding: CGFloat

    var body: some View {
        GoodsTagTextPill(text: "# \(name)", fontSize: fontSize, horizontalPadding: horizontalPadding)
    }
}

struct GoodsTagTextPill: View {
    var text: String
    var fontSize: CGFloat
    var horizontalPadding: CGFloat
    var verticalPadding: CGFloat = 7

    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: .heavy, design: .rounded))
            .lineLimit(1)
            .foregroundStyle(MegrumTheme.ink)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(.white.opacity(0.86), in: Capsule())
    }
}

struct GoodsQuantityBadge: View {
    var quantity: Int

    var body: some View {
        Text("×\(quantity)")
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(MegrumTheme.lavender, in: Capsule())
            .shadow(color: MegrumTheme.ink.opacity(0.16), radius: 5, y: 2)
            .accessibilityHidden(true)
    }
}
