import MegrumDesign
import SwiftUI

struct ProposalMeetupPlaceActionRow: View {
    var isRequestingLocation: Bool
    var canApplyPreviousDraft: Bool
    var onUseCurrentLocation: () -> Void
    var onApplyPreviousDraft: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            ProposalMeetupPlaceActionButton(
                title: "現在地を中心に",
                systemImage: "location.fill",
                isEnabled: true,
                showsProgress: isRequestingLocation,
                onTap: onUseCurrentLocation
            )

            ProposalMeetupPlaceActionButton(
                title: "前の設定と同じに",
                systemImage: "clock.arrow.circlepath",
                isEnabled: canApplyPreviousDraft,
                onTap: onApplyPreviousDraft
            )
        }
        .font(.system(size: 13, weight: .black, design: .rounded))
    }
}

struct ProposalMeetupPlaceSearchResultsList: View {
    var results: [ProposalMeetupPlaceSearchResult]
    var onSelect: (ProposalMeetupPlaceSearchResult) -> Void

    var body: some View {
        VStack(spacing: 4) {
            ForEach(results) { result in
                ProposalMeetupPlaceSearchResultButton(result: result) {
                    onSelect(result)
                }
            }
        }
        .padding(.top, 2)
    }
}

extension View {
    func proposalPlaceSheetActionStyle(isEnabled: Bool) -> some View {
        self
            .foregroundStyle(isEnabled ? MegrumTheme.ink : MegrumTheme.muted)
            .frame(height: 44)
            .padding(.horizontal, 10)
            .background(.white.opacity(isEnabled ? 0.82 : 0.46), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(MegrumTheme.lavender.opacity(isEnabled ? 0.22 : 0.08), lineWidth: 1)
            }
            .buttonStyle(.plain)
            .opacity(isEnabled ? 1 : 0.58)
    }

    @ViewBuilder
    func proposalPlaceSheetTextInputBehavior() -> some View {
        #if os(iOS)
        self.textInputAutocapitalization(.never)
        #else
        self
        #endif
    }

    func proposalFlowMeetupRow() -> some View {
        self
            .frame(minHeight: 48)
            .padding(.vertical, 6)
    }
}
