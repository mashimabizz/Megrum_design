import MegrumCore
import MegrumDesign
import SwiftUI

struct GoodsCreateOshiPickerRow: View {
    var title: String = "推し"
    var isLoading: Bool
    var selectedGroupName: String?
    var isItemReadOnly: Bool
    var action: () -> Void

    var body: some View {
        GoodsEditorSectionContainer(title: title, systemImage: "person.2", required: true) {
            Button(action: action) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("推し（グループ・作品）")
                            .font(.subheadline.weight(.black))
                            .foregroundStyle(MegrumTheme.ink)
                        if isLoading {
                            Text("読み込み中")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(MegrumTheme.muted)
                        }
                    }
                    Spacer(minLength: 12)
                    Text(selectedGroupName ?? "選択")
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(selectedGroupName == nil ? MegrumTheme.muted : MegrumTheme.lavender)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.black))
                        .foregroundStyle(MegrumTheme.muted)
                }
                .padding(.horizontal, 14)
                .frame(height: 64)
                .background(.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(MegrumTheme.lavender.opacity(0.18), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
            .disabled(isItemReadOnly || isLoading)
        }
    }
}

struct GoodsInventoryCreateMetaStepView: View {
    @Binding var createMetas: [GoodsCreateMetaDraft]

    var createPhotos: [GoodsCreatePhotoDraft]
    var selectedCreateMetaIDs: Set<UUID>
    var oshiCharacters: [OshiCharacter]
    var allowsMemberSelection: Bool
    var createError: String?
    var onToggleSelection: (UUID) -> Void
    var onSelectAll: () -> Void
    var onClearSelection: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GoodsInventoryCreateMetaSelectionHeader(
                selectedCount: selectedCreateMetaIDs.count,
                totalCount: createMetas.count,
                onSelectAll: onSelectAll,
                onClearSelection: onClearSelection
            )

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 10)], spacing: 10) {
                ForEach($createMetas) { $meta in
                    GoodsInventoryCreateMetaTile(
                        meta: $meta,
                        photo: photo(for: meta.photoID),
                        allowsMemberSelection: allowsMemberSelection,
                        memberName: memberName(for: meta.memberID),
                        isSelected: selectedCreateMetaIDs.contains(meta.id),
                        onToggleSelection: {
                            onToggleSelection(meta.id)
                        }
                    )
                }
            }

            if allowsMemberSelection, oshiCharacters.isEmpty {
                GoodsCreateMemberRequestInfo()
            }

            if let createError {
                GoodsCreateErrorNotice(message: createError)
            }
        }
    }

    private func photo(for photoID: UUID?) -> GoodsCreatePhotoDraft? {
        guard let photoID else {
            return nil
        }
        return createPhotos.first { $0.id == photoID }
    }

    private func memberName(for memberID: UUID?) -> String? {
        guard let memberID else {
            return nil
        }
        return oshiCharacters.first { $0.id == memberID }?.name
    }
}

struct GoodsCreateMemberRequestInfo: View {
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(width: 32, height: 32)
                .background(MegrumTheme.lavender.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text("メンバーが見つからない場合")
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(MegrumTheme.ink)
                Text("Swift版では推し設定の追加リクエストから仮登録できます。登録画面では、追加済みメンバーだけを選べます。")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MegrumTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(MegrumTheme.sky.opacity(0.16), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
