import MegrumCore
import MegrumDesign
import SwiftUI

struct AccountSetupOshiMasterStep: View {
    var groups: [OshiGroup]
    var categoryOptions: [OshiCategoryOption]
    @Binding var selectedGenreID: UUID?
    @Binding var searchText: String
    @Binding var selectedGroups: [OshiGroup]
    var requestedDrafts: [OnboardingOshiDraft]
    var isLoading: Bool
    var errorMessage: String?
    @FocusState.Binding var focusedField: AccountSetupFocusedField?
    var onClearError: () -> Void
    var onRequestOshi: (String) -> Void

    private var selectedGroupIDs: Set<UUID> {
        Set(selectedGroups.map(\.id))
    }

    private var requestCandidateName: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            AccountSetupSearchField(
                placeholder: "作品名・グループ名を検索",
                text: $searchText,
                focusedField: $focusedField,
                focusCase: .groupSearch
            )

            OshiGenreSegmentBar(options: categoryOptions, selection: $selectedGenreID)
                .padding(.horizontal, -18)

            if isLoading {
                HStack(spacing: 10) {
                    ProgressView()
                        .controlSize(.small)
                        .tint(MegrumTheme.lavender)
                    Text("グループ・作品を読み込み中…")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else if groups.isEmpty {
                AccountSetupOshiNoResultsCard(
                    query: requestCandidateName,
                    onRequest: {
                        onRequestOshi(requestCandidateName)
                    }
                )
            } else {
                OshiMasterCandidateGrid(
                    groups: groups,
                    selectedGroupIDs: [],
                    isSelected: { selectedGroupIDs.contains($0.id) },
                    onSelect: toggleGroup
                )
                .padding(.horizontal, -18)
            }

            AccountSetupSelectedGroupSummary(
                selectedGroups: selectedGroups,
                requestedDrafts: requestedDrafts
            )
            AccountSetupErrorText(message: errorMessage)
        }
        .padding(.top, 10)
    }

    private func toggleGroup(_ group: OshiGroup) {
        onClearError()
        if selectedGroups.contains(where: { $0.id == group.id }) {
            selectedGroups.removeAll { $0.id == group.id }
        } else {
            selectedGroups.append(group)
        }
    }
}

private struct AccountSetupOshiNoResultsCard: View {
    var query: String
    var onRequest: () -> Void

    private var canRequest: Bool {
        !query.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("該当するグループ・作品が見つかりません")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)

            if canRequest {
                Button(action: onRequest) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                        Text("「\(query)」を追加リクエスト")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.up.forward")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(MegrumTheme.lavender)
                    .padding(.horizontal, 14)
                    .frame(height: 46)
                    .background(MegrumTheme.lavender.opacity(0.12), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct AccountSetupSelectedGroupSummary: View {
    var selectedGroups: [OshiGroup]
    var requestedDrafts: [OnboardingOshiDraft]

    private var hasSelection: Bool {
        !selectedGroups.isEmpty || !requestedDrafts.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("選択中")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            if !hasSelection {
                Text("まだ選択されていません")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(selectedGroups) { group in
                            AccountSetupSelectedGroupChip(
                                title: group.name,
                                foregroundColor: MegrumTheme.lavender,
                                backgroundColor: MegrumTheme.lavender.opacity(0.14)
                            )
                        }

                        ForEach(requestedDrafts) { draft in
                            AccountSetupSelectedGroupChip(
                                title: draft.displayName,
                                foregroundColor: MegrumTheme.pink,
                                backgroundColor: MegrumTheme.pink.opacity(0.18)
                            )
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
}
