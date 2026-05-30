import MegrumCore
import MegrumDesign
import SwiftUI

struct SearchScreen: View {
    var items: [GoodsItem]

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var filteredItems: [GoodsItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return items
        }
        return items.filter { item in
            item.title.localizedCaseInsensitiveContains(trimmed)
                || item.tags.contains { $0.name.localizedCaseInsensitiveContains(trimmed) }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(MegrumTheme.ink)
                                .frame(width: 54, height: 54)
                                .background(.white.opacity(0.86), in: Circle())
                                .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }

                    Text("検索")
                        .font(.system(size: 58, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)

                    Text("\(filteredItems.count)件")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(MegrumTheme.ink)

                    GoodsGrid(items: filteredItems)
                }
                .padding(.horizontal, 22)
                .padding(.top, 22)
                .padding(.bottom, 132)
            }

            SearchInputBar(query: $query)
                .padding(.horizontal, 22)
                .padding(.bottom, 18)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .megrumHiddenNavigationBar()
    }
}

private struct SearchInputBar: View {
    @Binding var query: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(MegrumTheme.ink)

            TextField("グッズ・推し・タグを検索", text: $query)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .disableAutocorrection(true)
        }
        .padding(.horizontal, 20)
        .frame(height: 62)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.72), lineWidth: 1))
        .shadow(color: .black.opacity(0.12), radius: 18, y: 10)
    }
}
