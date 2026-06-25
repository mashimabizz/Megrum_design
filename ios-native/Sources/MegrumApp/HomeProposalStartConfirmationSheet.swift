import MegrumDesign
import SwiftUI

struct HomeProposalStartConfirmationSheet: View {
    var payload: HomeProposalStartConfirmationPayload
    var onConfirm: (HomeDiscoveryProposalSelection) -> Void

    var body: some View {
        HomeSheetScaffold(
            bottomButton: "打診に進む",
            bottomButtonAction: {
                onConfirm(payload.proposalSelection)
            }
        ) {
            VStack(alignment: .leading, spacing: 14) {
                Text("この内容で打診しますか？")
                    .font(.system(size: 21, weight: .black, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)

                ProposalExchangePreviewRow(
                    senderGoods: payload.senderGoodsItems,
                    receiverGoods: payload.receiverGoodsItems,
                    senderCashAmount: payload.senderCashAmount,
                    receiverCashAmount: nil
                )
            }
        }
    }
}
