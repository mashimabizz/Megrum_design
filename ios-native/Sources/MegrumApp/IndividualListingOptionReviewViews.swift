import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct IndividualListingOptionReviewItem: Identifiable, Equatable {
    var id = UUID()
    var title: String
    var kind: String
    var detail: String
    var source: IndividualListingOptionReviewSource = .staged
    /// 保存時に選択肢として書き込む実データ。表示専用アイテムでは nil。
    var payload: IndividualListingOptionInput?

    var addedToastMessage: String {
        "\(title)（\(kind)：\(detail)）を追加しました"
    }
}

enum IndividualListingOptionReviewSource: Equatable {
    case staged
    case current
}

enum IndividualListingOptionReviewReducer {
    static func deleting(
        itemID: UUID,
        from items: [IndividualListingOptionReviewItem]
    ) -> [IndividualListingOptionReviewItem] {
        retitling(items.filter { $0.id != itemID })
    }

    static func retitling(_ items: [IndividualListingOptionReviewItem]) -> [IndividualListingOptionReviewItem] {
        items.enumerated().map { offset, item in
            var next = item
            next.title = "選択肢\(offset + 1)"
            next.source = .staged
            return next
        }
    }
}

struct IndividualListingOptionReviewSheet: View {
    var items: [IndividualListingOptionReviewItem]
    var onDelete: (IndividualListingOptionReviewItem) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if items.isEmpty {
                        Text("追加済みの選択肢はまだありません")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.muted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(18)
                            .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    } else {
                        ForEach(items) { item in
                            IndividualListingOptionReviewRow(
                                item: item,
                                onDelete: { onDelete(item) }
                            )
                        }
                    }
                }
                .padding(20)
            }
            .background(MegrumTheme.canvas.ignoresSafeArea())
            .navigationTitle("選択肢を確認")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                }
            }
        }
        #if os(iOS)
        .presentationDetents([.medium, .large])
        #endif
    }
}

private struct IndividualListingOptionReviewRow: View {
    var item: IndividualListingOptionReviewItem
    var onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(item.title)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Text(item.kind)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .padding(.horizontal, 9)
                    .frame(height: 24)
                    .background(MegrumTheme.lavender.opacity(0.10), in: Capsule())
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                        .frame(width: 28, height: 28)
                        .background(.black.opacity(0.05), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(item.title)を削除")
            }

            Text(item.detail)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.ink.opacity(0.76))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(MegrumTheme.ink.opacity(0.07), lineWidth: 1)
        }
    }
}

struct IndividualListingOptionAddedToast: View {
    var message: String

    var body: some View {
        Text(message)
            .font(.system(size: 13, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .lineLimit(2)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(MegrumTheme.ink.opacity(0.86), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: MegrumTheme.ink.opacity(0.22), radius: 18, y: 8)
            .padding(.horizontal, 28)
            .accessibilityLabel(message)
    }
}
