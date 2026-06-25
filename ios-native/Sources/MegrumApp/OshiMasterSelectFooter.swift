import Foundation
import MegrumDesign
import SwiftUI

struct OshiMasterSelectFooter: View {
    var categoryOptions: [OshiCategoryOption]
    @Binding var selectedGenreID: UUID?
    @Binding var searchText: String
    var allowsMultipleSelection: Bool
    var pendingSelectionCount: Int
    var onRegister: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            OshiGenreSegmentBar(options: categoryOptions, selection: $selectedGenreID)
            searchField
            pendingSelectionAction
        }
        .padding(.top, 10)
        .padding(.bottom, 14)
        .background(MegrumTheme.canvas.opacity(0.96))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(.black.opacity(0.08))
                .frame(height: 0.5)
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
            TextField("作品名・グループ名で検索", text: $searchText)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 14)
        .frame(height: OshiMasterSelectLayoutMetrics.searchHeight)
        .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 19, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 19, style: .continuous)
                .strokeBorder(.black.opacity(0.08), lineWidth: 1)
        }
        .padding(.horizontal, 18)
    }

    @ViewBuilder
    private var pendingSelectionAction: some View {
        if allowsMultipleSelection, pendingSelectionCount > 0 {
            Text(OshiSettingsPresentationText.masterSelectionCountTitle(selectionCount: pendingSelectionCount))
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 18)
                .transition(.opacity)

            Button(action: onRegister) {
                Text(OshiSettingsPresentationText.masterRegisterButtonTitle(selectionCount: pendingSelectionCount))
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: OshiMasterSelectLayoutMetrics.registerButtonHeight)
                    .background(MegrumTheme.lavender, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 18)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .accessibilityLabel(OshiSettingsPresentationText.masterRegisterButtonTitle(selectionCount: pendingSelectionCount))
        }
    }
}
