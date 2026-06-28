import MegrumDesign
import SwiftUI

struct HomeMatchLogicHelpContent: View {
    var exchangeSettings: HomeDefaultExchangeSettings
    var onOpenWish: () -> Void
    var onOpenIndividualListings: () -> Void
    var onOpenExchangeSettings: () -> Void
    var onOpenPaymentSettings: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                intro
                mutualMatchSection
                goodsConditionsSection
                priceConditionsSection
                exchangePaymentSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 28)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("相互マッチは、個別募集同士の噛み合いです。")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)
            Text("あなたと相手の個別募集が、お互いに「譲れるもの」と「欲しいもの」で噛み合うかを見ています。")
                .font(.system(size: 14.5, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
        }
    }

    private var mutualMatchSection: some View {
        HomeMatchLogicHelpSection(
            systemImage: "arrow.left.arrow.right.circle.fill",
            title: "相互にマッチとは",
            rows: [
                HomeMatchLogicHelpRow(mark: "1", title: "個別募集同士で見ています", body: "あなたの個別募集と、相手の個別募集を組み合わせて判定します。"),
                HomeMatchLogicHelpRow(mark: "2", title: "両方向に合う相手だけです", body: "相手が譲るものがあなたの求めるものに合い、あなたが譲るものも相手の求めるものに合う場合に表示します。"),
                HomeMatchLogicHelpRow(mark: "3", title: "交換に出す意思があるものだけです", body: "相手がただ持っているだけのグッズではなく、相手の個別募集の「譲るもの」に入っているグッズを見ています。")
            ],
            actions: [
                HomeMatchLogicHelpAction(title: "個別募集を作る", systemImage: "rectangle.stack.badge.plus", action: onOpenIndividualListings)
            ]
        )
    }

    private var goodsConditionsSection: some View {
        HomeMatchLogicHelpSection(
            systemImage: "shippingbox.fill",
            title: "グッズ条件の見方",
            rows: [
                HomeMatchLogicHelpRow(mark: "大", title: "グループや作品が合う", body: "BTS、TWICE、作品名など、まず大きな推しの分類が合うかを見ます。"),
                HomeMatchLogicHelpRow(mark: "人", title: "メンバー指定があればそこまで見る", body: "サナ、モモなどのメンバー指定がある場合は、同じメンバーのグッズだけを候補にします。"),
                HomeMatchLogicHelpRow(mark: "種", title: "グッズ種別も合わせる", body: "トレカ、缶バッジ、アクスタなど、指定された種別がある場合はそこも一致させます。"),
                HomeMatchLogicHelpRow(mark: "シリーズ", title: "シリーズは落とさず注意表示にします", body: "シリーズが合わない場合も候補には残し、カードに「シリーズ不一致？」と表示します。")
            ],
            actions: [
                HomeMatchLogicHelpAction(title: "Wishも設定", systemImage: "heart.fill", action: onOpenWish)
            ]
        )
    }

    private var priceConditionsSection: some View {
        HomeMatchLogicHelpSection(
            systemImage: "yensign.circle.fill",
            title: "定価・金額条件の見方",
            rows: [
                HomeMatchLogicHelpRow(mark: "定", title: "定価同士は一致", body: "お互いが定価を条件にしている場合は、そのまま合うものとして扱います。"),
                HomeMatchLogicHelpRow(mark: "¥", title: "定価と金額指定は候補に残す", body: "定価と具体的な金額は比べられないため、「金額込み候補」として表示します。"),
                HomeMatchLogicHelpRow(mark: "不足", title: "金額指定同士だけ不足を見ます", body: "相手の提示額が求めている金額より低い場合は「金額不足」と表示します。")
            ],
            actions: [
                HomeMatchLogicHelpAction(title: "個別募集を見直す", systemImage: "square.and.pencil", action: onOpenIndividualListings)
            ]
        )
    }

    private var exchangePaymentSection: some View {
        HomeMatchLogicHelpSection(
            systemImage: "info.circle.fill",
            title: "交換・支払条件の見方",
            rows: [
                HomeMatchLogicHelpRow(mark: "交", title: "交換条件", body: "グッズ条件で相互に合う候補は残し、交換手段、都道府県、日程、送料で決める必要がある点を注意シリーズにします。"),
                HomeMatchLogicHelpRow(mark: "支", title: "支払条件", body: "物々交換だけなら見ません。定価や金額指定を含む候補だけ、共通の支払方法があるかを確認します。")
            ],
            footer: "現在の標準交換条件: \(exchangeSettings.summaryText)",
            actions: [
                HomeMatchLogicHelpAction(title: "交換条件を設定", systemImage: "slider.horizontal.3", action: onOpenExchangeSettings),
                HomeMatchLogicHelpAction(title: "支払条件を設定", systemImage: "yensign.circle", action: onOpenPaymentSettings)
            ]
        )
    }
}

struct HomeMatchLogicHelpRow: Identifiable, Equatable {
    var id: String { "\(mark)-\(title)" }
    var mark: String
    var title: String
    var body: String
}

struct HomeMatchLogicHelpAction: Identifiable {
    var id: String { title }
    var title: String
    var systemImage: String
    var action: () -> Void
}

private struct HomeMatchLogicHelpSection: View {
    var systemImage: String
    var title: String
    var rows: [HomeMatchLogicHelpRow]
    var footer: String?
    var actions: [HomeMatchLogicHelpAction]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(MegrumTheme.ink)

            VStack(spacing: 10) {
                ForEach(rows) { row in
                    HStack(alignment: .top, spacing: 12) {
                        Text(row.mark)
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.lavender)
                            .frame(width: 34, height: 34)
                            .background(MegrumTheme.lavender.opacity(0.12), in: Circle())

                        VStack(alignment: .leading, spacing: 3) {
                            Text(row.title)
                                .font(.system(size: 15.5, weight: .black, design: .rounded))
                                .foregroundStyle(MegrumTheme.ink)
                            Text(row.body)
                                .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                                .foregroundStyle(MegrumTheme.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            if let footer {
                Text(footer)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.lavender)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 8) {
                ForEach(actions) { action in
                    Button(action: action.action) {
                        Label(action.title, systemImage: action.systemImage)
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(MegrumTheme.lavender)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(MegrumTheme.lavender.opacity(0.24), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(.white.opacity(0.74), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(MegrumTheme.ink.opacity(0.08), lineWidth: 1)
        }
    }
}
