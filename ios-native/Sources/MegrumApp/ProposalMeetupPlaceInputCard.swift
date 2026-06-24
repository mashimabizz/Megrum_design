import Foundation
import MegrumDesign
import SwiftUI

struct ProposalMeetupPlaceInputCard: View {
    @Binding var placeName: String
    @FocusState.Binding var isPlaceFocused: Bool
    var searchResults: [ProposalMeetupPlaceSearchResult]
    var isSearchingPlace: Bool
    var onSearch: () -> Void
    var onSelectSearchResult: (ProposalMeetupPlaceSearchResult) -> Void

    private var trimmedSearchQuery: String {
        placeName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSearch: Bool {
        !trimmedSearchQuery.isEmpty && !isSearchingPlace
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("場所名")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)

            inputRow
            searchResultsSection
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var inputRow: some View {
        HStack(spacing: 8) {
            TextField("交換できる場所", text: $placeName)
                .focused($isPlaceFocused)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
                .proposalPlaceSheetTextInputBehavior()
                .onSubmit(onSearch)

            Button(action: onSearch) {
                if isSearchingPlace {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text("検索")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                }
            }
            .disabled(!canSearch)
            .foregroundStyle(trimmedSearchQuery.isEmpty ? MegrumTheme.muted : MegrumTheme.lavender)
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 52)
        .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(MegrumTheme.lavender.opacity(isPlaceFocused ? 0.36 : 0.14), lineWidth: 1.2)
        }
    }

    @ViewBuilder
    private var searchResultsSection: some View {
        if !searchResults.isEmpty {
            ProposalMeetupPlaceSearchResultsList(
                results: searchResults,
                onSelect: onSelectSearchResult
            )
        }
    }
}
