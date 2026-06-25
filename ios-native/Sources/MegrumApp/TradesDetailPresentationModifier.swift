import MegrumCore
import SwiftUI

struct TradesDetailPresentationModifier: ViewModifier {
    @Binding var detailRoute: TradeDetailRoute?
    @ObservedObject var appState: MegrumAppState
    var proposals: [TradeProposal]

    func body(content: Content) -> some View {
        content.tradeDetailPresentation(item: $detailRoute) { route in
            detailView(for: route)
        }
    }

    @ViewBuilder
    private func detailView(for route: TradeDetailRoute) -> some View {
        NavigationStack {
            if let proposal = proposals.first(where: { $0.id == route.proposalID }) {
                TradeDetailScreen(appState: appState, proposal: proposal)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button {
                                detailRoute = nil
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .heavy))
                            }
                            .accessibilityLabel("やりとり一覧に戻る")
                        }
                    }
            } else {
                TradeDetailUnavailableScreen()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("閉じる") {
                                detailRoute = nil
                            }
                        }
                    }
            }
        }
    }
}

private extension View {
    @ViewBuilder
    func tradeDetailPresentation<Content: View>(
        item: Binding<TradeDetailRoute?>,
        @ViewBuilder content: @escaping (TradeDetailRoute) -> Content
    ) -> some View {
        #if os(iOS)
        fullScreenCover(item: item, content: content)
        #else
        sheet(item: item, content: content)
        #endif
    }
}
