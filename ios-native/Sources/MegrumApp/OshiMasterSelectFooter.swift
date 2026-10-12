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
            OshiMasterSearchField(searchText: $searchText)
            OshiMasterPendingSelectionAction(
                allowsMultipleSelection: allowsMultipleSelection,
                pendingSelectionCount: pendingSelectionCount,
                onRegister: onRegister
            )
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
}

private struct OshiMasterSearchField: View {
    @Binding var searchText: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(MegrumTheme.muted)
            TextField("作品名・グループ名で検索", text: $searchText)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 14)
        .frame(height: OshiMasterSelectLayoutMetrics.searchHeight)
        .background(MegrumTheme.ink.opacity(0.04), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 18)
    }
}

private struct OshiMasterPendingSelectionAction: View {
    var allowsMultipleSelection: Bool
    var pendingSelectionCount: Int
    var onRegister: () -> Void

    @ViewBuilder
    var body: some View {
        if allowsMultipleSelection, pendingSelectionCount > 0 {
            Text(OshiSettingsPresentationText.masterSelectionCountTitle(selectionCount: pendingSelectionCount))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(MegrumTheme.lavender)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 18)
                .transition(.opacity)

            Button(action: onRegister) {
                Text(OshiSettingsPresentationText.masterRegisterButtonTitle(selectionCount: pendingSelectionCount))
            }
            .buttonStyle(.megrumPrimary(height: OshiMasterSelectLayoutMetrics.registerButtonHeight))
            .padding(.horizontal, 18)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .accessibilityLabel(OshiSettingsPresentationText.masterRegisterButtonTitle(selectionCount: pendingSelectionCount))
        }
    }
}
