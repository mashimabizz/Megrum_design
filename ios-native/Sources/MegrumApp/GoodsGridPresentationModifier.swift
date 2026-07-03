import MegrumCore
import SwiftUI

struct GoodsGridPresentationModifier: ViewModifier {
    @Binding var presentationState: GoodsGridPresentationState
    var context: GoodsGridContext
    var onReportItem: ((GoodsItem, GoodsReportReason, String) -> Void)?

    private var actionMessageBinding: Binding<Bool> {
        Binding(
            get: { presentationState.hasActionMessage },
            set: { if !$0 { presentationState.clearActionMessage() } }
        )
    }

    func body(content: Content) -> some View {
        content
            .sheet(item: $presentationState.detailItem) { item in
                NavigationStack {
                    GoodsDetailSheet(item: item, context: context)
                }
            }
            .sheet(item: $presentationState.reportItem) { item in
                NavigationStack {
                    GoodsReportSheet(item: item) { reason, note in
                        onReportItem?(item, reason, note)
                        presentationState.clearReport()
                    }
                }
            }
            .alert("まだ接続していません", isPresented: actionMessageBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                if let actionMessage = presentationState.actionMessage {
                    Text(actionMessage)
                }
            }
    }
}
