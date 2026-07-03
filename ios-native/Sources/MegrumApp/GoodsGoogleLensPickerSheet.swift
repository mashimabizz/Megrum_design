import MegrumDesign
import SwiftUI

struct GoodsGoogleLensPickerSheet: View {
    var items: [GoodsGoogleLensSearchItem]
    var onSelect: (GoodsGoogleLensSearchItem.ID) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var pendingExternalSearchItemID: GoodsGoogleLensSearchItem.ID?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(GoodsGoogleLensSearchDisclosure.message)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(MegrumTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                } footer: {
                    Text(GoodsGoogleLensSearchDisclosure.footer)
                }

                ForEach(items) { item in
                    Button {
                        pendingExternalSearchItemID = item.id
                    } label: {
                        HStack(spacing: 12) {
                            preview(for: item)
                                .frame(width: 58, height: 58)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.subheadline.weight(.black))
                                    .foregroundStyle(MegrumTheme.ink)
                                    .lineLimit(2)
                                if let detailText = item.detailText {
                                    Text(detailText)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(MegrumTheme.muted)
                                        .lineLimit(1)
                                }
                            }
                            Spacer(minLength: 8)
                            Image(systemName: "safari")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(MegrumTheme.lavender)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.plain)
            .navigationTitle("画像検索するグッズ")
            .megrumInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .alert(
                GoodsGoogleLensSearchDisclosure.title,
                isPresented: isShowingExternalSearchDisclosure
            ) {
                Button("キャンセル", role: .cancel) {
                    pendingExternalSearchItemID = nil
                }
                Button(GoodsGoogleLensSearchDisclosure.confirmButtonTitle) {
                    guard let pendingExternalSearchItemID else {
                        return
                    }
                    onSelect(pendingExternalSearchItemID)
                    self.pendingExternalSearchItemID = nil
                }
            } message: {
                Text(GoodsGoogleLensSearchDisclosure.message)
            }
        }
    }

    private var isShowingExternalSearchDisclosure: Binding<Bool> {
        Binding {
            pendingExternalSearchItemID != nil
        } set: { isPresented in
            if !isPresented {
                pendingExternalSearchItemID = nil
            }
        }
    }

    @ViewBuilder
    private func preview(for item: GoodsGoogleLensSearchItem) -> some View {
        if let data = item.source.previewData {
            GoodsCreatePhotoPreview(data: data)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        } else {
            ListingGoodsImage(url: item.source.previewURL, title: item.title, cornerRadius: 12)
        }
    }
}
